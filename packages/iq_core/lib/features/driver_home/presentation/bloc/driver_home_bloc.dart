import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/geo_hasher.dart';
import '../../../home/data/models/home_data_model.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../location/domain/repositories/location_repository.dart';
import 'driver_home_event.dart';
import 'driver_home_state.dart';

/// BLoC that manages DriverHomePage state.
///
/// Fetches driver home data from the API on [DriverHomeLoadRequested],
/// handles online/offline status toggling and sends periodic location
/// updates to **Firebase Realtime Database** while the driver is online
/// so the backend matching algorithm can assign nearby ride requests.
///
/// The backend reads the `drivers/driver_{id}` Firebase node — **not**
/// the HTTP `api/v1/user/update-location` endpoint — when looking for
/// available drivers near a passenger.
class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  final HomeRepository repository;
  final LocationRepository locationRepository;

  /// Periodic timer that pushes the driver's GPS coordinates to Firebase.
  Timer? _locationTimer;

  /// Interval between location updates pushed to Firebase RTDB.
  static const _locationInterval = Duration(seconds: 10);

  /// Lightweight geohash encoder used by the Firebase location node.
  final _geoHasher = GeoHasher();

  DriverHomeBloc({
    required this.repository,
    required this.locationRepository,
    bool initialOnline = false,
  }) : super(DriverHomeState(isOnline: initialOnline)) {
    on<DriverHomeLoadRequested>(_onLoadRequested);
    on<DriverHomeStatusToggled>(_onStatusToggled);
  }

  // ─── Location helpers ───────────────────────────────────────────────

  /// Start pushing the driver's location to Firebase every
  /// [_locationInterval] seconds.  Also sends one update immediately
  /// so the backend knows where the driver is right away.
  void _startLocationUpdates() {
    _stopLocationUpdates();
    // Send immediately, then periodically.
    _sendLocationNow();
    _locationTimer = Timer.periodic(_locationInterval, (_) {
      _sendLocationNow();
    });
  }

  /// Stop the periodic location updates (driver went offline or bloc closed).
  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Get the current GPS position and write the driver node to
  /// Firebase RTDB at `drivers/driver_{id}`.
  ///
  /// This mirrors the old app's `updateFirebaseData()` exactly so the
  /// backend's matching algorithm can discover this driver.
  Future<void> _sendLocationNow() async {
    try {
      final homeData = state.homeData;
      if (homeData == null) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final geoHash = _geoHasher.encode(
        position.longitude,
        position.latitude,
      );

      final driverRef = FirebaseDatabase.instance
          .ref()
          .child('drivers/driver_${homeData.id}');

      await driverRef.update({
        'bearing': 0,
        'date': DateTime.now().toString(),
        'id': homeData.id,
        'g': geoHash,
        'is_active': state.isOnline ? 1 : 0,
        'is_available': state.isOnline,
        'l': {
          '0': position.latitude,
          '1': position.longitude,
        },
        'mobile': homeData.phone,
        'name': homeData.name,
        'profile_picture': homeData.avatarUrl ?? '',
        'rating': homeData.rating ?? 0,
        'vehicle_type_icon': homeData.vehicleTypeIcon ?? '',
        'updated_at': ServerValue.timestamp,
        'vehicle_number': homeData.carNumber ?? '',
        'vehicle_type_name': homeData.carMake ?? '',
        'vehicle_types': homeData.vehicleTypes,
        'ownerid': homeData.ownerId ?? '',
        'service_location_id': homeData.serviceLocationId ?? '',
        'transport_type': homeData.transportType,
      });

      dev.log(
        '📍 Firebase location updated: '
        'lat=${position.latitude}, lng=${position.longitude}, '
        'g=$geoHash, driver=${homeData.id}',
      );

      // Also send the HTTP update once (best-effort) so the backend
      // has the coordinates in both places.
      await locationRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      dev.log('⚠️ _sendLocationNow error: $e');
    }
  }

  /// Mark the driver as offline / unavailable in Firebase RTDB.
  Future<void> _clearFirebaseAvailability() async {
    try {
      final homeData = state.homeData;
      if (homeData == null) return;

      final driverRef = FirebaseDatabase.instance
          .ref()
          .child('drivers/driver_${homeData.id}');

      await driverRef.update({
        'is_active': 0,
        'is_available': false,
        'updated_at': ServerValue.timestamp,
      });

      dev.log('🔴 Firebase driver ${homeData.id} marked offline');
    } catch (e) {
      dev.log('⚠️ _clearFirebaseAvailability error: $e');
    }
  }

  // ─── Event handlers ─────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    DriverHomeLoadRequested event,
    Emitter<DriverHomeState> emit,
  ) async {
    emit(state.copyWith(status: DriverHomeStatus.loading));

    final result = await repository.getUserDetails();

    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverHomeStatus.error,
        errorMessage: failure.message,
      )),
      (HomeDataModel data) {
        final online = data.isAvailable ?? false;
        emit(state.copyWith(
          status: DriverHomeStatus.loaded,
          homeData: data,
          isOnline: online,
        ));
        // If the driver was already online (e.g. app restart),
        // start pushing location right away.
        if (online) _startLocationUpdates();
      },
    );
  }

  Future<void> _onStatusToggled(
    DriverHomeStatusToggled event,
    Emitter<DriverHomeState> emit,
  ) async {
    // Mark as toggling so UI can show loading indicator
    emit(state.copyWith(isToggling: true));

    final result = await repository.toggleDriverStatus(
      isOnline: !state.isOnline,
      lat: 0,
      lng: 0,
    );

    result.fold(
      (failure) {
        // Revert on failure — keep current state, clear loading
        emit(state.copyWith(isToggling: false));
      },
      (isActive) {
        emit(state.copyWith(
          isOnline: isActive,
          isToggling: false,
        ));
        // Start or stop location updates based on new status.
        if (isActive) {
          _startLocationUpdates();
        } else {
          _stopLocationUpdates();
          _clearFirebaseAvailability();
        }
      },
    );
  }

  @override
  Future<void> close() {
    _stopLocationUpdates();
    _clearFirebaseAvailability();
    return super.close();
  }
}
