import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/geo_utils.dart';
import '../../../data/datasources/trip_stream_data_source.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/incoming_request_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'driver_trip_event.dart';
import 'driver_trip_state.dart';

/// Manages the entire driver trip lifecycle:
/// idle → incoming request → accept → navigate → arrived → in progress → complete → rating.
class DriverTripBloc extends Bloc<DriverTripEvent, DriverTripState> {
  DriverTripBloc({
    required this.repository,
    required this.tripStream,
  }) : super(const DriverTripState()) {
    on<DriverTripListenRequested>(_onListenRequested);
    on<DriverTripIncomingReceived>(_onIncomingReceived);
    on<_FetchPendingRequestDetails>(_onFetchPendingDetails);
    on<DriverTripAccepted>(_onAccepted);
    on<DriverTripRejected>(_onRejected);
    on<DriverTripStreamStarted>(_onStreamStarted);
    on<DriverTripStreamUpdated>(_onStreamUpdated);
    on<DriverTripMarkArrived>(_onMarkArrived);
    on<DriverTripStartRide>(_onStartRide);
    on<DriverTripEndRide>(_onEndRide);
    on<DriverTripPaymentConfirmed>(_onPaymentConfirmed);
    on<DriverTripCancelRequested>(_onCancelRequested);
    on<DriverTripRatingSubmitted>(_onRatingSubmitted);
    on<DriverTripLocationUpdated>(_onLocationUpdated);
    on<DriverTripCheckActiveTrip>(_onCheckActiveTrip);
    on<DriverTripReset>(_onReset);
    on<_WaitingTimeTick>(_onWaitingTimeTick);
    on<DriverTripUploadShipmentProof>(_onUploadShipmentProof);
  }

  final BookingRepository repository;
  final TripStreamDataSource tripStream;
  StreamSubscription<IncomingRequestModel?>? _incomingSubscription;
  StreamSubscription<ActiveTripModel?>? _tripSubscription;

  /// Periodic timer that increments waiting time each second.
  Timer? _waitingTimer;

  /// Minimum distance threshold (in km) to avoid GPS jitter.
  static const double _minDistanceThresholdKm = 0.01; // ~10 metres

  Future<void> _onListenRequested(
    DriverTripListenRequested event,
    Emitter<DriverTripState> emit,
  ) async {
    debugPrint('🚕 DriverTripBloc: _onListenRequested for driverId=${event.driverId}');
    emit(state.copyWith(
      status: DriverTripStatus.idle,
      driverId: event.driverId,
    ));

    await _incomingSubscription?.cancel();
    _incomingSubscription =
        tripStream.watchIncomingRequests(event.driverId).listen(
      (request) {
        debugPrint('🚕 DriverTripBloc: incoming request received: ${request?.requestId ?? "null"}');
        if (!isClosed) {
          add(DriverTripIncomingReceived(request));
        }
      },
      onError: (e) {
        debugPrint('🚕 DriverTripBloc: incoming stream error: $e');
      },
    );
  }

  void _onIncomingReceived(
    DriverTripIncomingReceived event,
    Emitter<DriverTripState> emit,
  ) {
    final request = event.data;
    if (request == null || request is! IncomingRequestModel) {
      // No active incoming request — back to idle
      if (state.status == DriverTripStatus.incomingRequest) {
        emit(state.copyWith(status: DriverTripStatus.idle));
      }
      return;
    }

    // Firebase `request-meta` only carries `driver_id` as a signal.
    // Fetch full ride details from the user API (metaRequest field).
    add(_FetchPendingRequestDetails(firebaseRequestId: request.requestId));
  }

  /// Internal event: fetch rich ride details from the backend API after
  /// Firebase has signalled a new incoming request.
  Future<void> _onFetchPendingDetails(
    _FetchPendingRequestDetails event,
    Emitter<DriverTripState> emit,
  ) async {
    // Avoid refetching if we already have a fully-loaded incoming request
    // being displayed. The user must accept/reject before we fetch another.
    if (state.status == DriverTripStatus.incomingRequest &&
        state.incomingRequest != null &&
        state.incomingRequest!.pickAddress.isNotEmpty) {
      return;
    }

    // If we're already in an active trip (restored via _onCheckActiveTrip),
    // ignore stale incoming-request signals from request-meta.
    const _activeStatuses = {
      DriverTripStatus.loading,
      DriverTripStatus.navigatingToPickup,
      DriverTripStatus.arrivedAtPickup,
      DriverTripStatus.tripInProgress,
      DriverTripStatus.tripCompleted,
    };
    if (_activeStatuses.contains(state.status)) {
      debugPrint('🚕 _onFetchPendingDetails: skipping — already in active trip (${state.status})');
      return;
    }

    // Don't show loading overlay — stay idle until API returns real data.
    debugPrint('🚕 _onFetchPendingDetails: calling API for request ${event.firebaseRequestId}');
    final result = await repository.fetchPendingRequest();

    // Re-check after await — status may have changed while awaiting API.
    if (_activeStatuses.contains(state.status)) {
      debugPrint('🚕 _onFetchPendingDetails: skipping emit — status changed to ${state.status} during API call');
      return;
    }

    result.fold(
      (failure) {
        debugPrint('🚕 _onFetchPendingDetails: API failed — ${failure.message}');
        // API call failed — fall back to idle rather than showing empty data
        emit(state.copyWith(status: DriverTripStatus.idle));
      },
      (fullRequest) {
        debugPrint('🚕 _onFetchPendingDetails: API returned ${fullRequest == null ? "null" : "request id=${fullRequest.requestId}, pickAddr=${fullRequest.pickAddress}"}');
        if (fullRequest != null) {
          emit(state.copyWith(
            status: DriverTripStatus.incomingRequest,
            incomingRequest: fullRequest,
            requestId: fullRequest.requestId,
          ));
        } else {
          // metaRequest is null — request may have been cancelled/expired.
          // Clean up the stale request-meta entry so it doesn't
          // trigger a wasted API call on every app open.
          tripStream.deleteRequestMeta(event.firebaseRequestId);
          emit(state.copyWith(status: DriverTripStatus.idle));
        }
      },
    );
  }

  Future<void> _onAccepted(
    DriverTripAccepted event,
    Emitter<DriverTripState> emit,
  ) async {
    emit(state.copyWith(status: DriverTripStatus.loading));

    final result = await repository.respondToRequest(
      requestId: event.requestId,
      isAccept: true,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverTripStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: DriverTripStatus.navigatingToPickup,
          requestId: event.requestId,
        ));
        // Start listening to trip updates
        add(DriverTripStreamStarted(event.requestId));
      },
    );
  }

  Future<void> _onRejected(
    DriverTripRejected event,
    Emitter<DriverTripState> emit,
  ) async {
    debugPrint('🚕 _onRejected: rejecting request ${event.requestId}');

    // Immediately go idle so the UI dismisses the overlay.
    emit(state.copyWith(status: DriverTripStatus.idle));

    // Notify the backend so it can re-dispatch to the next driver.
    // Retry up to 3 times if the network call fails — if the backend
    // never receives the rejection, no other driver will get the request.
    bool sent = false;
    for (int attempt = 1; attempt <= 3 && !sent; attempt++) {
      final result = await repository.respondToRequest(
        requestId: event.requestId,
        isAccept: false,
      );
      result.fold(
        (failure) {
          debugPrint(
            '⚠️ _onRejected: API attempt $attempt failed — ${failure.message}',
          );
        },
        (_) {
          sent = true;
          debugPrint('🚕 _onRejected: API reject sent successfully');
        },
      );
      if (!sent && attempt < 3) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }

    if (!sent) {
      debugPrint('❌ _onRejected: reject API failed after 3 attempts — '
          'backend may not re-dispatch to another driver');
    }
  }

  Future<void> _onStreamStarted(
    DriverTripStreamStarted event,
    Emitter<DriverTripState> emit,
  ) async {
    await _tripSubscription?.cancel();
    _tripSubscription = tripStream.watchTrip(event.requestId).listen(
      (tripData) {
        if (!isClosed) {
          add(DriverTripStreamUpdated(tripData));
        }
      },
    );
  }

  void _onStreamUpdated(
    DriverTripStreamUpdated event,
    Emitter<DriverTripState> emit,
  ) {
    final tripData = event.tripData;
    if (tripData == null || tripData is! ActiveTripModel) return;

    final phase = tripData.phase;
    debugPrint('🚕 DriverTripBloc._onStreamUpdated: phase=$phase, '
        'current status=${state.status}');

    switch (phase) {
      case TripPhase.cancelled:
        emit(state.copyWith(
          status: DriverTripStatus.cancelled,
          activeTripData: tripData,
        ));

      case TripPhase.completed:
        emit(state.copyWith(
          status: DriverTripStatus.tripCompleted,
          activeTripData: tripData,
        ));

      case TripPhase.driverArrived:
        emit(state.copyWith(
          status: DriverTripStatus.arrivedAtPickup,
          activeTripData: tripData,
        ));

      case TripPhase.inProgress:
        emit(state.copyWith(
          status: DriverTripStatus.tripInProgress,
          activeTripData: tripData,
        ));

      case TripPhase.driverOnWay:
        emit(state.copyWith(
          status: DriverTripStatus.navigatingToPickup,
          activeTripData: tripData,
        ));

      case TripPhase.searching:
        // Still waiting for acceptance to propagate
        break;
    }
  }

  Future<void> _onMarkArrived(
    DriverTripMarkArrived event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.markArrived(requestId: event.requestId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // Update Firebase so both driver & passenger apps see the change.
        tripStream.updateTripNode(
          requestId: event.requestId,
          data: {'trip_arrived': '1'},
        );
        // Start the "before trip" waiting timer.
        _startWaitingTimer(isBeforeTrip: true);
      },
    );
  }

  Future<void> _onStartRide(
    DriverTripStartRide event,
    Emitter<DriverTripState> emit,
  ) async {
    // Stop the "before trip" waiting timer.
    _waitingTimer?.cancel();
    _waitingTimer = null;

    final result = await repository.startRide(
      requestId: event.requestId,
      pickLat: event.pickLat,
      pickLng: event.pickLng,
      otp: event.otp,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // Update Firebase so both driver & passenger apps see the change.
        tripStream.updateTripNode(
          requestId: event.requestId,
          data: {
            'trip_start': '1',
            'waiting_time_before_start': state.waitingTimeBeforeStart,
          },
        );
      },
    );
  }

  Future<void> _onEndRide(
    DriverTripEndRide event,
    Emitter<DriverTripState> emit,
  ) async {
    // Stop any running waiting timer.
    _waitingTimer?.cancel();
    _waitingTimer = null;

    // Use the BLoC's accumulated trip distance if the event distance is 0.
    final distance = event.distance > 0
        ? event.distance
        : double.parse(state.tripDistance.toStringAsFixed(2));

    final beforeWait = event.beforeTripWaitingTime > 0
        ? event.beforeTripWaitingTime
        : state.waitingTimeBeforeStart;

    final afterWait = event.afterTripWaitingTime > 0
        ? event.afterTripWaitingTime
        : state.waitingTimeAfterStart;

    debugPrint('🚕 EndRide: distance=${distance}km, '
        'beforeWait=${beforeWait}s, afterWait=${afterWait}s');

    final result = await repository.endRide(
      requestId: event.requestId,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      dropAddress: event.dropAddress,
      distance: distance,
      polyLine: event.polyLine,
      beforeTripWaitingTime: beforeWait,
      afterTripWaitingTime: afterWait,
    );
    final failure = result.fold((l) => l, (_) => null);
    if (failure != null) {
      // Keep tripInProgress so the user can retry.
      emit(state.copyWith(errorMessage: failure.message));
      return;
    }

    // API succeeded — notify passenger via Firebase.
    try {
      await tripStream.updateTripNode(
        requestId: event.requestId,
        data: {
          'is_completed': true,
          'trip_distance': distance,
          'waiting_time_before_start': beforeWait,
          'waiting_time_after_start': afterWait,
          if (state.latLngArray.isNotEmpty) 'lat_lng_array': state.latLngArray,
          if (event.polyLine.isNotEmpty) 'polyline': event.polyLine,
        },
      );
    } catch (e) {
      debugPrint('🚕 DriverTripBloc: Firebase update failed: $e');
    }
    // Transition to completed — navigates driver to invoice screen.
    emit(state.copyWith(status: DriverTripStatus.tripCompleted));
  }

  Future<void> _onPaymentConfirmed(
    DriverTripPaymentConfirmed event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.confirmPayment(
      requestId: event.requestId,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        // Notify passenger app that payment has been received.
        tripStream.updateTripNode(
          requestId: event.requestId,
          data: {'is_payment_received': true},
        );
      },
    );
  }

  Future<void> _onCancelRequested(
    DriverTripCancelRequested event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.cancelByDriver(
      requestId: event.requestId,
      reason: event.reason,
      customReason: event.customReason,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: DriverTripStatus.cancelled)),
    );
  }

  Future<void> _onRatingSubmitted(
    DriverTripRatingSubmitted event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.submitRating(
      requestId: event.requestId,
      rating: event.rating,
      comment: event.comment,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: DriverTripStatus.rated)),
    );
  }

  Future<void> _onLocationUpdated(
    DriverTripLocationUpdated event,
    Emitter<DriverTripState> emit,
  ) async {
    if (state.requestId == null) return;

    // Always push live location to Firebase.
    tripStream.updateDriverLocation(
      requestId: state.requestId!,
      lat: event.lat,
      lng: event.lng,
      bearing: event.bearing,
    );

    // ── Trip distance accumulation (only while trip is in progress) ──
    if (state.status == DriverTripStatus.tripInProgress) {
      final lastLat = state.lastLat;
      final lastLng = state.lastLng;

      if (lastLat != null && lastLng != null) {
        final segmentKm = GeoUtils.haversineDistance(
          lastLat,
          lastLng,
          event.lat,
          event.lng,
        );

        // Filter out GPS jitter — only add meaningful movement.
        if (segmentKm >= _minDistanceThresholdKm) {
          final newDistance = state.tripDistance + segmentKm;
          final newArray = [
            ...state.latLngArray,
            '${event.lat},${event.lng}',
          ];

          emit(state.copyWith(
            tripDistance: newDistance,
            lastLat: event.lat,
            lastLng: event.lng,
            latLngArray: newArray,
          ));

          // Sync trip distance + trail to Firebase periodically.
          _syncTripTrackingToFirebase(newDistance, newArray);
        }
      } else {
        // First location update during trip — just record the start point.
        emit(state.copyWith(
          lastLat: event.lat,
          lastLng: event.lng,
          latLngArray: ['${event.lat},${event.lng}'],
        ));
      }
    }
  }

  /// Write trip tracking data to Firebase so the passenger app can see
  /// real-time distance and the backend has the GPS trail.
  void _syncTripTrackingToFirebase(
    double distanceKm,
    List<String> latLngArray,
  ) {
    if (state.requestId == null) return;
    tripStream.updateTripNode(
      requestId: state.requestId!,
      data: {
        'trip_distance': double.parse(distanceKm.toStringAsFixed(2)),
        'lat_lng_array': latLngArray,
      },
    );
  }

  /// Called on startup to check if the driver has an ongoing trip.
  /// If yes, restore state with loading, fetch data, then let Firebase
  /// stream determine the correct trip phase.
  Future<void> _onCheckActiveTrip(
    DriverTripCheckActiveTrip event,
    Emitter<DriverTripState> emit,
  ) async {
    // Don't check if we're already in an active trip state.
    if (state.status != DriverTripStatus.idle) return;

    debugPrint('🚕 DriverTripBloc: checking for active trip on startup...');

    final result = await repository.fetchOnTripRequest();
    result.fold(
      (failure) {
        debugPrint('🚕 DriverTripBloc: fetchOnTripRequest failed: ${failure.message}');
      },
      (onTripRequest) {
        if (onTripRequest != null && onTripRequest.requestId.isNotEmpty) {
          debugPrint('🚕 DriverTripBloc: found active trip ${onTripRequest.requestId}, restoring...');
          // Use loading status temporarily — the Firebase stream will
          // immediately fire with the correct phase and update the status.
          emit(state.copyWith(
            status: DriverTripStatus.loading,
            incomingRequest: onTripRequest,
            requestId: onTripRequest.requestId,
          ));
          // Start listening to Firebase for live trip updates.
          // The stream emits the current value first, which will set
          // the correct status (navigatingToPickup / arrivedAtPickup /
          // tripInProgress) via _onStreamUpdated.
          add(DriverTripStreamStarted(onTripRequest.requestId));
        } else {
          debugPrint('🚕 DriverTripBloc: no active trip found.');
        }
      },
    );
  }

  void _onReset(
    DriverTripReset event,
    Emitter<DriverTripState> emit,
  ) {
    final driverId = state.driverId;
    _tripSubscription?.cancel();
    _tripSubscription = null;
    _waitingTimer?.cancel();
    _waitingTimer = null;
    emit(const DriverTripState());

    // Re-subscribe to incoming requests so that any request that arrived
    // while the driver was in tripCompleted/rated state gets picked up.
    // The .onValue stream fires the current value on first listen.
    if (driverId != null) {
      add(DriverTripListenRequested(driverId));
    }
  }

  /// Upload a shipment proof image (fire-and-forget — errors logged).
  Future<void> _onUploadShipmentProof(
    DriverTripUploadShipmentProof event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.uploadShipmentProof(
      requestId: event.requestId,
      imagePath: event.imagePath,
      isBefore: event.isBefore,
    );
    result.fold(
      (failure) => debugPrint(
          '⚠️ [DriverTrip] Shipment proof upload failed: ${failure.message}'),
      (_) => debugPrint('✅ [DriverTrip] Shipment proof uploaded'),
    );
  }

  @override
  Future<void> close() {
    _incomingSubscription?.cancel();
    _tripSubscription?.cancel();
    _waitingTimer?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Waiting-time helpers
  // ---------------------------------------------------------------------------

  /// Whether the current waiting timer is for "before trip" or "after trip".
  bool _waitingIsBeforeTrip = true;

  /// Start a periodic timer that dispatches a tick event every second.
  ///
  /// [isBeforeTrip] = true  → increments `waitingTimeBeforeStart`
  /// [isBeforeTrip] = false → increments `waitingTimeAfterStart`
  void _startWaitingTimer({required bool isBeforeTrip}) {
    _waitingTimer?.cancel();
    _waitingIsBeforeTrip = isBeforeTrip;
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        add(_WaitingTimeTick(isBeforeTrip: _waitingIsBeforeTrip));
      }
    });
  }

  /// Handler for the waiting-time tick event.
  void _onWaitingTimeTick(
    _WaitingTimeTick event,
    Emitter<DriverTripState> emit,
  ) {
    if (event.isBeforeTrip) {
      emit(state.copyWith(
        waitingTimeBeforeStart: state.waitingTimeBeforeStart + 1,
      ));
    } else {
      emit(state.copyWith(
        waitingTimeAfterStart: state.waitingTimeAfterStart + 1,
      ));
    }

    // Sync waiting time to Firebase every 60 seconds.
    final totalWait =
        state.waitingTimeBeforeStart + state.waitingTimeAfterStart;
    if (totalWait > 0 && totalWait % 60 == 0) {
      _syncWaitingTimeToFirebase();
    }
  }

  /// Write current waiting times to Firebase.
  void _syncWaitingTimeToFirebase() {
    if (state.requestId == null) return;
    tripStream.updateTripNode(
      requestId: state.requestId!,
      data: {
        'waiting_time_before_start': state.waitingTimeBeforeStart,
        'waiting_time_after_start': state.waitingTimeAfterStart,
      },
    );
  }
}

/// Internal event: Firebase signalled a new request — now fetch full details.
class _FetchPendingRequestDetails extends DriverTripEvent {
  const _FetchPendingRequestDetails({required this.firebaseRequestId});
  final String firebaseRequestId;

  @override
  List<Object?> get props => [firebaseRequestId];
}

/// Internal event: Waiting timer tick.
class _WaitingTimeTick extends DriverTripEvent {
  const _WaitingTimeTick({required this.isBeforeTrip});
  final bool isBeforeTrip;

  @override
  List<Object?> get props => [isBeforeTrip];
}
