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
    on<DriverHomeResumed>(_onResumed);
  }

  // ─── Location helpers ───────────────────────────────────────────────

  /// Start pushing the driver's location to Firebase every
  /// [_locationInterval] seconds.  Also sends one update immediately
  /// so the backend knows where the driver is right away.
  void _startLocationUpdates() {
    _stopLocationUpdates();

    // ── CRITICAL: mark active IMMEDIATELY (no GPS wait) ──
    // `_sendLocationNow()` needs to fetch a GPS position first which can
    // take 5+ seconds. If a passenger requests a ride in that window the
    // backend still sees `is_active: 0` and skips this driver.
    // Writing `is_active: 1, is_available: true` + all metadata right
    // away ensures the backend discovers the driver INSTANTLY. The stale
    // `g` and `l` from the previous session is good enough for proximity
    // matching until the first GPS update lands.
    _writeAvailabilityNow();

    // Then start periodic full updates (includes fresh GPS).
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

  /// Immediately write `is_active=1, is_available=true` and every non-GPS
  /// field to Firebase so the backend matching algorithm can discover this
  /// driver without waiting for `Geolocator.getCurrentPosition()`.
  Future<void> _writeAvailabilityNow() async {
    try {
      final homeData = state.homeData;
      if (homeData == null) return;

      final numericId = int.tryParse(homeData.id) ?? homeData.id;

      final driverRef = FirebaseDatabase.instance
          .ref()
          .child('drivers/driver_${homeData.id}');

      await driverRef.update({
        'id': numericId,
        'is_active': 1,
        'is_available': true,
        'bearing': 0,
        'date': DateTime.now().toString(),
        'mobile': homeData.phone,
        'name': homeData.name,
        'profile_picture': homeData.avatarUrl ?? '',
        'rating': homeData.rating?.toString() ?? '0',
        'vehicle_type_icon': homeData.vehicleTypeIcon ?? '',
        'vehicle_number': homeData.carNumber ?? '',
        'vehicle_type_name': homeData.carMake ?? '',
        'vehicle_types': homeData.vehicleTypes,
        'ownerid': homeData.ownerId ?? '',
        'service_location_id': homeData.serviceLocationId ?? '',
        'transport_type': homeData.transportType,
        'preferences': <int>[],
        'updated_at': ServerValue.timestamp,
      });

      dev.log(
        '✅ Firebase: driver $numericId marked ACTIVE immediately '
        '(svc_loc=${homeData.serviceLocationId})',
      );
    } catch (e) {
      dev.log('⚠️ _writeAvailabilityNow error: $e');
    }
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

      // Write `id` as int to match the old app — the backend reads this
      // value and copies it into `request-meta.driver_id`, so the type
      // MUST stay int for our `.equalTo(int)` Firebase query to match.
      final numericId = int.tryParse(homeData.id) ?? homeData.id;

      // ── CRITICAL: Match old app's Firebase node EXACTLY ──
      //
      // 1. NEVER pass null — Firebase `.update({key: null})` DELETES the
      //    key from the node. The old app's model defaults every field to
      //    '' / 0 / false, so keys are ALWAYS present. Use `?? ''`.
      //
      // 2. `rating` must be String — old app writes `userData.rating`
      //    which is forced `.toString()` in its model.
      //
      // 3. `preferences` must be present — even as [].
      final updatePayload = <String, dynamic>{
        'bearing': 0,
        'date': DateTime.now().toString(),
        'id': numericId,
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
        'rating': homeData.rating?.toString() ?? '0',
        'vehicle_type_icon': homeData.vehicleTypeIcon ?? '',
        'updated_at': ServerValue.timestamp,
        'vehicle_number': homeData.carNumber ?? '',
        'vehicle_type_name': homeData.carMake ?? '',
        'vehicle_types': homeData.vehicleTypes,
        'ownerid': homeData.ownerId ?? '',
        'service_location_id': homeData.serviceLocationId ?? '',
        'transport_type': homeData.transportType,
        'preferences': <int>[],
      };

      await driverRef.update(updatePayload);

      dev.log(
        '📍 Firebase updated: '
        'id=$numericId (${numericId.runtimeType}), '
        'lat=${position.latitude}, lng=${position.longitude}, '
        'is_active=${state.isOnline ? 1 : 0}, '
        'svc_loc=${homeData.serviceLocationId}, '
        'vehicle_types=${homeData.vehicleTypes}, '
        'transport=${homeData.transportType}',
      );

      // Also send the HTTP update once (best-effort) so the backend
      // has the coordinates in both places.
      await locationRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      dev.log('⚠️ _sendLocationNow GPS error: $e — writing heartbeat anyway');
      // ── HEARTBEAT: even if GPS fails, keep updated_at fresh ──
      // The backend checks `updated_at` to decide if a driver is
      // "truly online". Without this, a stationary driver whose GPS
      // times out would go stale and stop receiving trips.
      try {
        final homeData = state.homeData;
        if (homeData != null) {
          final driverRef = FirebaseDatabase.instance
              .ref()
              .child('drivers/driver_${homeData.id}');
          await driverRef.update({
            'updated_at': ServerValue.timestamp,
            'is_active': state.isOnline ? 1 : 0,
            'is_available': state.isOnline,
          });
          dev.log('💓 Heartbeat: updated_at refreshed (no GPS)');
        }
      } catch (e2) {
        dev.log('⚠️ Heartbeat write also failed: $e2');
      }
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

    bool wentOnline = false;

    result.fold(
      (failure) {
        // Revert on failure — keep current state, clear loading
        emit(state.copyWith(isToggling: false));
      },
      (isActive) {
        wentOnline = isActive;
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

    // ── MATCH OLD APP: re-fetch user details after going online ──
    // The old app calls `add(GetUserDetailsEvent())` after toggle, which
    // refreshes user data from the API and re-writes Firebase with the
    // FRESH data. This ensures the backend has the latest state.
    if (wentOnline) {
      final freshResult = await repository.getUserDetails();
      freshResult.fold(
        (f) => dev.log('⚠️ Post-toggle getUserDetails failed: ${f.message}'),
        (freshData) {
          dev.log(
            '🔄 Post-toggle refresh: '
            'svc_loc=${freshData.serviceLocationId}, '
            'vTypes=${freshData.vehicleTypes}, '
            'transport=${freshData.transportType}, '
            'approved=${freshData.isApproved}',
          );
          emit(state.copyWith(homeData: freshData));
          // Re-write Firebase with the FRESH data immediately.
          _sendLocationNow();
        },
      );
    }
  }

  /// Called when the app resumes from background. Re-establish
  /// Firebase location updates so the driver stays discoverable.
  Future<void> _onResumed(
    DriverHomeResumed event,
    Emitter<DriverHomeState> emit,
  ) async {
    if (state.isOnline) {
      dev.log('📱 App resumed — driver is online, restarting location updates');
      _startLocationUpdates();
    }
  }

  @override
  Future<void> close() {
    _stopLocationUpdates();
    _clearFirebaseAvailability();
    return super.close();
  }
}
