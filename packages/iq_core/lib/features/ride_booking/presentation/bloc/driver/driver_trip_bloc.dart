import 'dart:async';

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
    emit(state.copyWith(
      status: DriverTripStatus.idle,
      driverId: event.driverId,
    ));

    await _incomingSubscription?.cancel();
    _incomingSubscription =
        tripStream.watchIncomingRequests(event.driverId).listen(
      (request) {
        if (!isClosed) {
          add(DriverTripIncomingReceived(request));
        }
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

    emit(state.copyWith(
      status: DriverTripStatus.incomingRequest,
      incomingRequest: request,
      requestId: request.requestId,
    ));
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
      (_) {}, // Firebase stream will update the state
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
      (_) {}, // Firebase stream will update the state
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
      distance: event.distance,
      beforeTripWaitingTime: event.beforeTripWaitingTime,
      afterTripWaitingTime: event.afterTripWaitingTime,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {}, // Firebase stream will update the state
    );
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
      (_) {}, // Firebase stream will update the state
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
