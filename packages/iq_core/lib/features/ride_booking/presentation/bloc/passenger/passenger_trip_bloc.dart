import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/trip_stream_data_source.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'passenger_trip_event.dart';
import 'passenger_trip_state.dart';

/// Manages the entire passenger trip lifecycle:
/// search → select ride → create request → search driver → active trip → invoice → rating.
///
/// Performance: uses a single Firebase stream subscription and emits
/// state changes via `copyWith` to minimize unnecessary rebuilds.
class PassengerTripBloc extends Bloc<PassengerTripEvent, PassengerTripState> {
  PassengerTripBloc({
    required this.repository,
    required this.tripStream,
  }) : super(const PassengerTripState()) {
    on<PassengerTripEtaRequested>(_onEtaRequested);
    on<PassengerTripVehicleSelected>(_onVehicleSelected);
    on<PassengerTripPaymentChanged>(_onPaymentChanged);
    on<PassengerTripCreateRequested>(_onCreateRequested);
    on<PassengerTripStreamStarted>(_onStreamStarted);
    on<PassengerTripStreamUpdated>(_onStreamUpdated);
    on<PassengerTripCancelRequested>(_onCancelRequested);
    on<PassengerTripRatingSubmitted>(_onRatingSubmitted);
    on<PassengerTripReset>(_onReset);
  }

  final BookingRepository repository;
  final TripStreamDataSource tripStream;
  StreamSubscription<ActiveTripModel?>? _tripSubscription;

  // ─── Event Handlers ───

  Future<void> _onEtaRequested(
    PassengerTripEtaRequested event,
    Emitter<PassengerTripState> emit,
  ) async {
    emit(state.copyWith(
      status: PassengerTripStatus.loadingEta,
      pickLat: event.pickLat,
      pickLng: event.pickLng,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      pickAddress: event.pickAddress,
      dropAddress: event.dropAddress,
      promoCode: event.promoCode,
    ));

    final result = await repository.getEta(
      pickLat: event.pickLat,
      pickLng: event.pickLng,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      promoCode: event.promoCode,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: PassengerTripStatus.error,
        errorMessage: failure.message,
      )),
      (vehicleTypes) {
        // Auto-select the default or first vehicle type
        final defaultVehicle = vehicleTypes.firstWhere(
          (v) => v.isDefault,
          orElse: () => vehicleTypes.first,
        );

        emit(state.copyWith(
          status: PassengerTripStatus.selectingRide,
          vehicleTypes: vehicleTypes,
          selectedVehicle: defaultVehicle,
        ));
      },
    );
  }

  void _onVehicleSelected(
    PassengerTripVehicleSelected event,
    Emitter<PassengerTripState> emit,
  ) {
    emit(state.copyWith(selectedVehicle: event.vehicleType));
  }

  void _onPaymentChanged(
    PassengerTripPaymentChanged event,
    Emitter<PassengerTripState> emit,
  ) {
    emit(state.copyWith(paymentOpt: event.paymentOpt));
  }

  Future<void> _onCreateRequested(
    PassengerTripCreateRequested event,
    Emitter<PassengerTripState> emit,
  ) async {
    if (state.selectedVehicle == null) return;

    emit(state.copyWith(status: PassengerTripStatus.creatingRequest));

    final result = await repository.createRideRequest(
      pickLat: state.pickLat,
      pickLng: state.pickLng,
      dropLat: state.dropLat,
      dropLng: state.dropLng,
      pickAddress: state.pickAddress,
      dropAddress: state.dropAddress,
      vehicleType: state.selectedVehicle!.zoneTypeId,
      paymentOpt: state.paymentOpt,
      promoCode: state.promoCode,
      polyline: event.polyline,
      requestEtaAmount: state.selectedVehicle!.total,
      instructions: event.instructions,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: PassengerTripStatus.error,
        errorMessage: failure.message,
      )),
      (response) {
        emit(state.copyWith(
          status: PassengerTripStatus.searchingDriver,
          requestId: response.requestId,
        ));
        // Start listening to Firebase for this request
        add(PassengerTripStreamStarted(response.requestId));
      },
    );
  }

  Future<void> _onStreamStarted(
    PassengerTripStreamStarted event,
    Emitter<PassengerTripState> emit,
  ) async {
    // Cancel any existing subscription
    await _tripSubscription?.cancel();

    // Listen to Firebase RTDB for trip updates
    _tripSubscription = tripStream.watchTrip(event.requestId).listen(
      (tripData) {
        if (!isClosed) {
          add(PassengerTripStreamUpdated(tripData));
        }
      },
      onError: (_) {
        // Firebase errors are non-fatal — we keep listening
      },
    );
  }

  void _onStreamUpdated(
    PassengerTripStreamUpdated event,
    Emitter<PassengerTripState> emit,
  ) {
    final tripData = event.tripData;
    if (tripData == null) return;

    if (tripData is ActiveTripModel) {
      final phase = tripData.phase;

      switch (phase) {
        case TripPhase.cancelled:
          emit(state.copyWith(
            status: PassengerTripStatus.cancelled,
            activeTripData: tripData,
          ));

        case TripPhase.completed:
          emit(state.copyWith(
            status: PassengerTripStatus.tripCompleted,
            activeTripData: tripData,
          ));

        case TripPhase.searching:
          emit(state.copyWith(
            status: PassengerTripStatus.searchingDriver,
            activeTripData: tripData,
          ));

        case TripPhase.driverOnWay:
        case TripPhase.driverArrived:
        case TripPhase.inProgress:
          emit(state.copyWith(
            status: PassengerTripStatus.activeTrip,
            activeTripData: tripData,
          ));
      }
    }
  }

  Future<void> _onCancelRequested(
    PassengerTripCancelRequested event,
    Emitter<PassengerTripState> emit,
  ) async {
    if (state.requestId == null) return;

    final result = await repository.cancelRequest(
      requestId: state.requestId!,
      reason: event.reason,
      customReason: event.customReason,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: PassengerTripStatus.cancelled,
      )),
    );
  }

  Future<void> _onRatingSubmitted(
    PassengerTripRatingSubmitted event,
    Emitter<PassengerTripState> emit,
  ) async {
    if (state.requestId == null) return;

    final result = await repository.submitRating(
      requestId: state.requestId!,
      rating: event.rating,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: PassengerTripStatus.rated)),
    );
  }

  void _onReset(
    PassengerTripReset event,
    Emitter<PassengerTripState> emit,
  ) {
    _tripSubscription?.cancel();
    _tripSubscription = null;
    emit(const PassengerTripState());
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }
}
