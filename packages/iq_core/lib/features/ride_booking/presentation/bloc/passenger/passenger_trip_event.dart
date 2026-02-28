import 'package:equatable/equatable.dart';

import '../../../data/models/vehicle_type_model.dart';

/// Events for the passenger trip flow.
abstract class PassengerTripEvent extends Equatable {
  const PassengerTripEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch vehicle types and pricing from ETA API.
class PassengerTripEtaRequested extends PassengerTripEvent {
  const PassengerTripEtaRequested({
    required this.pickLat,
    required this.pickLng,
    required this.dropLat,
    required this.dropLng,
    required this.pickAddress,
    required this.dropAddress,
    this.promoCode,
  });

  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;
  final String pickAddress;
  final String dropAddress;
  final String? promoCode;

  @override
  List<Object?> get props => [pickLat, pickLng, dropLat, dropLng, promoCode];
}

/// User selects a vehicle type.
class PassengerTripVehicleSelected extends PassengerTripEvent {
  const PassengerTripVehicleSelected(this.vehicleType);
  final VehicleTypeModel vehicleType;

  @override
  List<Object?> get props => [vehicleType];
}

/// User changes payment method.
class PassengerTripPaymentChanged extends PassengerTripEvent {
  const PassengerTripPaymentChanged(this.paymentOpt);

  /// 1=cash, 2=wallet, 0=card, 3=online
  final int paymentOpt;

  @override
  List<Object?> get props => [paymentOpt];
}

/// User confirms and creates the ride request.
class PassengerTripCreateRequested extends PassengerTripEvent {
  const PassengerTripCreateRequested({
    this.polyline,
    this.instructions,
  });

  final String? polyline;
  final String? instructions;

  @override
  List<Object?> get props => [polyline];
}

/// Start listening to Firebase for trip updates.
class PassengerTripStreamStarted extends PassengerTripEvent {
  const PassengerTripStreamStarted(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Firebase emitted a new trip state.
class PassengerTripStreamUpdated extends PassengerTripEvent {
  const PassengerTripStreamUpdated(this.tripData);
  final dynamic tripData;

  @override
  List<Object?> get props => [tripData];
}

/// User cancels the trip.
class PassengerTripCancelRequested extends PassengerTripEvent {
  const PassengerTripCancelRequested({
    required this.reason,
    this.customReason,
  });

  final String reason;
  final String? customReason;

  @override
  List<Object?> get props => [reason];
}

/// User submits a rating.
class PassengerTripRatingSubmitted extends PassengerTripEvent {
  const PassengerTripRatingSubmitted({
    required this.rating,
    this.comment,
  });

  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [rating, comment];
}

/// Reset the trip flow to initial state.
class PassengerTripReset extends PassengerTripEvent {
  const PassengerTripReset();
}

/// User applied or removed a promo code.
class PassengerTripPromoApplied extends PassengerTripEvent {
  const PassengerTripPromoApplied(this.promoCode);
  final String? promoCode;

  @override
  List<Object?> get props => [promoCode];
}

/// User scheduled a ride for later.
class PassengerTripScheduleChanged extends PassengerTripEvent {
  const PassengerTripScheduleChanged(this.scheduledTime);

  /// null = ride now (not scheduled).
  final DateTime? scheduledTime;

  @override
  List<Object?> get props => [scheduledTime];
}

/// User changed ride preferences (e.g. pet-friendly).
class PassengerTripPreferencesChanged extends PassengerTripEvent {
  const PassengerTripPreferencesChanged(this.preferences);

  /// List of preference IDs: [{"id": 1}, {"id": 2}]
  final List<Map<String, dynamic>> preferences;

  @override
  List<Object?> get props => [preferences];
}

/// User changed instructions for the driver.
class PassengerTripInstructionsChanged extends PassengerTripEvent {
  const PassengerTripInstructionsChanged(this.instructions);
  final String? instructions;

  @override
  List<Object?> get props => [instructions];
}
