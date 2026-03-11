import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
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
    on<PassengerTripPromoApplied>(_onPromoApplied);
    on<PassengerTripScheduleChanged>(_onScheduleChanged);
    on<PassengerTripPreferencesChanged>(_onPreferencesChanged);
    on<PassengerTripInstructionsChanged>(_onInstructionsChanged);
    on<PassengerTripStopAdded>(_onStopAdded);
    on<PassengerTripStopRemoved>(_onStopRemoved);
    on<PassengerTripRestoreOngoing>(_onRestoreOngoing);
    on<PassengerTripDetailsFetched>(_onDetailsFetched);
    on<PassengerTripChangeDropRequested>(_onChangeDropRequested);
  }

  final BookingRepository repository;
  final TripStreamDataSource tripStream;
  StreamSubscription<ActiveTripModel?>? _tripSubscription;

  /// Cached driver info + fare from `GET api/v1/user` → onTripRequest.
  /// Firebase doesn’t carry these fields; they come from the API only.
  Map<String, dynamic>? _apiEnrichment;

  /// Whether we’re currently fetching trip details from the API.
  bool _isFetchingDetails = false;

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
      stops: event.stops ?? state.stops,
    ));

    final result = await repository.getEta(
      pickLat: event.pickLat,
      pickLng: event.pickLng,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      promoCode: event.promoCode,
      distance: event.distance,
      duration: event.duration,
      polyline: event.polyline,
      pickAddress: event.pickAddress,
      dropAddress: event.dropAddress,
      stops: event.stops,
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
      vehicleType: state.selectedVehicle!.typeId,
      paymentOpt: state.paymentOpt,
      polyline: event.polyline,
      requestEtaAmount: state.selectedVehicle!.total,
      instructions: state.instructions ?? event.instructions,
      isLater: state.scheduledTime != null ? 1 : 0,
      rideType: 1,
      tripStartTime: state.scheduledTime?.toIso8601String(),
      selectedPreferences:
          state.selectedPreferences.isNotEmpty ? state.selectedPreferences : null,
      // Fields from ETA response — mirrors old app behaviour
      distance: state.selectedVehicle!.distanceInMeters,
      duration: state.selectedVehicle!.time.toStringAsFixed(0),
      promocodeId: state.selectedVehicle!.hasDiscount
          ? state.selectedVehicle!.promoId
          : null,
      discountedTotal: state.selectedVehicle!.hasDiscount
          ? state.selectedVehicle!.discountedTotal
          : null,
      stops: state.stops.isNotEmpty ? state.stops : null,
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

      // Enrich with API data if available (driver name, rating, fare, etc.)
      final enriched = _enrichTripData(tripData);

      switch (phase) {
        case TripPhase.cancelled:
          emit(state.copyWith(
            status: PassengerTripStatus.cancelled,
            activeTripData: enriched,
          ));

        case TripPhase.completed:
          emit(state.copyWith(
            status: PassengerTripStatus.tripCompleted,
            activeTripData: enriched,
          ));

        case TripPhase.searching:
          emit(state.copyWith(
            status: PassengerTripStatus.searchingDriver,
            activeTripData: enriched,
          ));

        case TripPhase.driverOnWay:
        case TripPhase.driverArrived:
        case TripPhase.inProgress:
          emit(state.copyWith(
            status: PassengerTripStatus.activeTrip,
            activeTripData: enriched,
          ));

          // Fetch driver details from API once when driver accepts.
          if (_apiEnrichment == null && !_isFetchingDetails) {
            _fetchTripDetailsFromApi();
          }
      }
    }
  }

  /// Returns `null` for null or empty strings.
  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  /// Merge cached API enrichment data into a Firebase-sourced trip model.
  ActiveTripModel _enrichTripData(ActiveTripModel tripData) {
    final e = _apiEnrichment;
    if (e == null) return tripData;

    return tripData.copyWith(
      driverName: _s(tripData.driverName) ?? _s(e['driver_name']),
      driverProfilePicture:
          _s(tripData.driverProfilePicture) ?? _s(e['driver_profile_picture']),
      driverRating:
          _s(tripData.driverRating) ?? _s(e['driver_rating']),
      driverMobile:
          _s(tripData.driverMobile) ?? _s(e['driver_mobile']),
      driverId: tripData.driverId ??
          (e['driver_id'] != null
              ? int.tryParse(e['driver_id'].toString())
              : null),
      vehicleNumber:
          _s(tripData.vehicleNumber) ?? _s(e['vehicle_number']),
      vehicleMake:
          _s(tripData.vehicleMake) ?? _s(e['vehicle_make']),
      vehicleModel:
          _s(tripData.vehicleModel) ?? _s(e['vehicle_model']),
      vehicleColor:
          _s(tripData.vehicleColor) ?? _s(e['vehicle_color']),
      totalAmount: (tripData.totalAmount == 0)
          ? (double.tryParse(e['total_amount']?.toString() ?? '') ?? 0)
          : null,
      paymentMethod:
          _s(tripData.paymentMethod) ?? _s(e['payment_method']),
      currencyCode:
          (tripData.currencyCode == 'IQD' && e['currency_code'] != null)
              ? e['currency_code'].toString()
              : null,
    );
  }

  /// Fire-and-forget API call to get driver info + fare.
  void _fetchTripDetailsFromApi() {
    final requestId = state.requestId;
    if (requestId == null || requestId.isEmpty) {
      debugPrint('⚠️ [PassengerTrip] No requestId — skipping API fetch');
      return;
    }
    _isFetchingDetails = true;
    debugPrint('🔍 [PassengerTrip] Fetching trip details for request $requestId…');
    repository
        .fetchPassengerActiveTripDetails(requestId: requestId)
        .then((result) {
      result.fold(
        (failure) {
          debugPrint(
            '⚠️ [PassengerTrip] Failed to fetch trip details: ${failure.message}',
          );
          _isFetchingDetails = false;
        },
        (enrichment) {
          debugPrint('✅ [PassengerTrip] API enrichment received: $enrichment');
          if (!isClosed && enrichment.isNotEmpty) {
            add(PassengerTripDetailsFetched(enrichment));
          }
          _isFetchingDetails = false;
        },
      );
    });
  }

  void _onDetailsFetched(
    PassengerTripDetailsFetched event,
    Emitter<PassengerTripState> emit,
  ) {
    _apiEnrichment = event.enrichment;

    // Re-enrich and emit the current trip data with newly fetched info.
    final current = state.activeTripData;
    if (current != null) {
      final enriched = _enrichTripData(current);
      debugPrint(
        '🔄 [PassengerTrip] Re-emitting enriched → '
        'name=${enriched.driverName}, '
        'rating=${enriched.driverRating}, '
        'photo=${enriched.driverProfilePicture != null ? "present" : "null"}, '
        'fare=${enriched.totalAmount}',
      );
      emit(state.copyWith(activeTripData: enriched));
    }
  }

  Future<void> _onCancelRequested(
    PassengerTripCancelRequested event,
    Emitter<PassengerTripState> emit,
  ) async {
    final requestId = state.requestId;
    if (requestId == null) return;

    // 1) Show loading immediately
    emit(state.copyWith(status: PassengerTripStatus.cancelling));

    // 2) Stop listening to Firebase so stale events don't interfere
    await _tripSubscription?.cancel();
    _tripSubscription = null;

    // 3) Write cancelled_by_user to Firebase (same as old app)
    try {
      await FirebaseDatabase.instance
          .ref('requests')
          .child(requestId)
          .update({'cancelled_by_user': true});
    } catch (e) {
      debugPrint('⚠️ Failed to write cancelled_by_user to Firebase: $e');
    }

    // 4) Call backend API with timeout
    try {
      final result = await repository
          .cancelRequest(
            requestId: requestId,
            reason: event.reason,
            customReason: event.customReason,
            cancelMethod: event.isTimerCancel ? 0 : null,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => const Right(true), // treat timeout as success
          );

      result.fold(
        (failure) {
          debugPrint('⚠️ Cancel API failed: ${failure.message}');
          // Still treat as cancelled since Firebase was updated
          emit(state.copyWith(status: PassengerTripStatus.cancelled));
        },
        (_) => emit(state.copyWith(status: PassengerTripStatus.cancelled)),
      );
    } catch (_) {
      // Even if everything fails, pop the user out
      emit(state.copyWith(status: PassengerTripStatus.cancelled));
    }
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
    _apiEnrichment = null;
    _isFetchingDetails = false;
    emit(const PassengerTripState());
  }

  void _onPromoApplied(
    PassengerTripPromoApplied event,
    Emitter<PassengerTripState> emit,
  ) {
    emit(state.copyWith(promoCode: event.promoCode));
  }

  void _onScheduleChanged(
    PassengerTripScheduleChanged event,
    Emitter<PassengerTripState> emit,
  ) {
    if (event.scheduledTime == null) {
      emit(state.copyWith(clearSchedule: true));
    } else {
      emit(state.copyWith(scheduledTime: event.scheduledTime));
    }
  }

  void _onPreferencesChanged(
    PassengerTripPreferencesChanged event,
    Emitter<PassengerTripState> emit,
  ) {
    emit(state.copyWith(selectedPreferences: event.preferences));
  }

  void _onInstructionsChanged(
    PassengerTripInstructionsChanged event,
    Emitter<PassengerTripState> emit,
  ) {
    if (event.instructions == null || event.instructions!.isEmpty) {
      emit(state.copyWith(clearInstructions: true));
    } else {
      emit(state.copyWith(instructions: event.instructions));
    }
  }

  void _onStopAdded(
    PassengerTripStopAdded event,
    Emitter<PassengerTripState> emit,
  ) {
    if (state.stops.length >= 2) return; // Max 2 intermediate stops.
    final newStops = [
      ...state.stops,
      {
        'order': state.stops.length + 1,
        'lat': event.lat,
        'lng': event.lng,
        'address': event.address,
      },
    ];
    emit(state.copyWith(stops: newStops));
  }

  void _onStopRemoved(
    PassengerTripStopRemoved event,
    Emitter<PassengerTripState> emit,
  ) {
    if (event.index < 0 || event.index >= state.stops.length) return;
    final newStops = List<Map<String, dynamic>>.from(state.stops)
      ..removeAt(event.index);
    // Re-number remaining stops.
    for (var i = 0; i < newStops.length; i++) {
      newStops[i] = {...newStops[i], 'order': i + 1};
    }
    emit(state.copyWith(stops: newStops));
  }

  // ─── Change Drop Location ───

  Future<void> _onChangeDropRequested(
    PassengerTripChangeDropRequested event,
    Emitter<PassengerTripState> emit,
  ) async {
    final requestId = state.requestId;
    if (requestId == null || requestId.isEmpty) return;

    final result = await repository.changeDropLocation(
      requestId: requestId,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      dropAddress: event.dropAddress,
    );

    result.fold(
      (failure) {
        debugPrint('⚠️ [PassengerTrip] Change drop failed: ${failure.message}');
      },
      (_) {
        // Update Firebase so the driver sees the change in real-time.
        FirebaseDatabase.instance
            .ref('requests')
            .child(requestId)
            .update({
          'drop_lat': event.dropLat,
          'drop_lng': event.dropLng,
          'drop_address': event.dropAddress,
          'destination_change': ServerValue.timestamp,
        });

        // Update local state so the map and UI refresh.
        emit(state.copyWith(
          dropLat: event.dropLat,
          dropLng: event.dropLng,
          dropAddress: event.dropAddress,
        ));
      },
    );
  }

  /// Restore an ongoing trip from the home carousel.
  ///
  /// Sets up state with known coordinates / addresses, puts status
  /// to [PassengerTripStatus.searchingDriver] (Firebase stream will
  /// promote to [PassengerTripStatus.activeTrip] once data arrives),
  /// and kicks off the Firebase stream listener.
  void _onRestoreOngoing(
    PassengerTripRestoreOngoing event,
    Emitter<PassengerTripState> emit,
  ) {
    // Cancel any previous subscription to avoid ghost data.
    _tripSubscription?.cancel();
    _tripSubscription = null;
    _apiEnrichment = null;
    _isFetchingDetails = false;

    // Emit a FRESH state — do NOT use copyWith so stale activeTripData
    // (e.g. driver marker from a previous trip) is discarded.
    emit(PassengerTripState(
      status: PassengerTripStatus.searchingDriver,
      requestId: event.requestId,
      pickLat: event.pickLat,
      pickLng: event.pickLng,
      dropLat: event.dropLat,
      dropLng: event.dropLng,
      pickAddress: event.pickAddress,
      dropAddress: event.dropAddress,
    ));

    // Start listening to Firebase for real-time trip updates
    add(PassengerTripStreamStarted(event.requestId));
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }
}
