import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../home/data/models/home_data_model.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../location/domain/repositories/location_repository.dart';
import 'driver_home_event.dart';
import 'driver_home_state.dart';

/// BLoC that manages DriverHomePage state.
///
/// Fetches driver home data from the API on [DriverHomeLoadRequested],
/// handles online/offline status toggling and sends periodic location
/// updates to the backend while the driver is online so the matching
/// algorithm can assign nearby ride requests.
class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  final HomeRepository repository;
  final LocationRepository locationRepository;

  /// Periodic timer that sends the driver's GPS coordinates to the backend.
  Timer? _locationTimer;

  /// Interval between location updates sent to the server.
  static const _locationInterval = Duration(seconds: 10);

  DriverHomeBloc({
    required this.repository,
    required this.locationRepository,
    bool initialOnline = false,
  }) : super(DriverHomeState(isOnline: initialOnline)) {
    on<DriverHomeLoadRequested>(_onLoadRequested);
    on<DriverHomeStatusToggled>(_onStatusToggled);
  }

  // ─── Location helpers ───────────────────────────────────────────────

  /// Start sending the driver's location to the backend every
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

  /// Get the current GPS position and POST it to the backend.
  Future<void> _sendLocationNow() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await locationRepository.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Silently ignore — network or GPS errors are transient.
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
        }
      },
    );
  }

  @override
  Future<void> close() {
    _stopLocationUpdates();
    return super.close();
  }
}
