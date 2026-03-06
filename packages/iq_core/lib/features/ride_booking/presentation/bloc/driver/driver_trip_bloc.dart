import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  }

  final BookingRepository repository;
  final TripStreamDataSource tripStream;
  StreamSubscription<IncomingRequestModel?>? _incomingSubscription;
  StreamSubscription<ActiveTripModel?>? _tripSubscription;

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
          // metaRequest is null — request may have been cancelled/expired
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
    await repository.respondToRequest(
      requestId: event.requestId,
      isAccept: false,
    );
    emit(state.copyWith(status: DriverTripStatus.idle));
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
      },
    );
  }

  Future<void> _onStartRide(
    DriverTripStartRide event,
    Emitter<DriverTripState> emit,
  ) async {
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
          data: {'trip_start': '1'},
        );
      },
    );
  }

  Future<void> _onEndRide(
    DriverTripEndRide event,
    Emitter<DriverTripState> emit,
  ) async {
    final result = await repository.endRide(
      requestId: event.requestId,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      dropAddress: event.dropAddress,
      distance: event.distance,
      polyLine: event.polyLine,
      beforeTripWaitingTime: event.beforeTripWaitingTime,
      afterTripWaitingTime: event.afterTripWaitingTime,
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
    // Fire-and-forget — don't block UI for location updates
    tripStream.updateDriverLocation(
      requestId: state.requestId!,
      lat: event.lat,
      lng: event.lng,
      bearing: event.bearing,
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
    _tripSubscription?.cancel();
    _tripSubscription = null;
    emit(const DriverTripState());
  }

  @override
  Future<void> close() {
    _incomingSubscription?.cancel();
    _tripSubscription?.cancel();
    return super.close();
  }
}

/// Internal event: Firebase signalled a new request — now fetch full details.
class _FetchPendingRequestDetails extends DriverTripEvent {
  const _FetchPendingRequestDetails({required this.firebaseRequestId});
  final String firebaseRequestId;

  @override
  List<Object?> get props => [firebaseRequestId];
}
