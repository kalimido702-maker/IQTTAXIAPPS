import 'package:equatable/equatable.dart';

/// Events for the driver trip flow.
abstract class DriverTripEvent extends Equatable {
  const DriverTripEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening for incoming ride requests.
class DriverTripListenRequested extends DriverTripEvent {
  const DriverTripListenRequested(this.driverId);
  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

/// Firebase emitted a new incoming request.
class DriverTripIncomingReceived extends DriverTripEvent {
  const DriverTripIncomingReceived(this.data);
  final dynamic data;

  @override
  List<Object?> get props => [data];
}

/// Driver accepts the incoming request.
class DriverTripAccepted extends DriverTripEvent {
  const DriverTripAccepted(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Driver rejects the incoming request.
class DriverTripRejected extends DriverTripEvent {
  const DriverTripRejected(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Start listening to active trip updates (after accept).
class DriverTripStreamStarted extends DriverTripEvent {
  const DriverTripStreamStarted(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Firebase emitted a trip state update.
class DriverTripStreamUpdated extends DriverTripEvent {
  const DriverTripStreamUpdated(this.tripData);
  final dynamic tripData;

  @override
  List<Object?> get props => [tripData];
}

/// Driver marks as arrived at pickup.
class DriverTripMarkArrived extends DriverTripEvent {
  const DriverTripMarkArrived(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Driver starts the ride.
class DriverTripStartRide extends DriverTripEvent {
  const DriverTripStartRide({
    required this.requestId,
    required this.pickLat,
    required this.pickLng,
    this.otp,
  });

  final String requestId;
  final double pickLat;
  final double pickLng;
  final String? otp;

  @override
  List<Object?> get props => [requestId];
}

/// Driver ends the ride.
class DriverTripEndRide extends DriverTripEvent {
  const DriverTripEndRide({
    required this.requestId,
    required this.dropLat,
    required this.dropLng,
    required this.distance,
    this.dropAddress = '',
    this.polyLine = '',
    this.beforeTripWaitingTime = 0,
    this.afterTripWaitingTime = 0,
  });

  final String requestId;
  final double dropLat;
  final double dropLng;
  final double distance;
  final String dropAddress;
  final String polyLine;
  final int beforeTripWaitingTime;
  final int afterTripWaitingTime;

  @override
  List<Object?> get props => [requestId, distance];
}

/// Driver confirms cash payment received.
class DriverTripPaymentConfirmed extends DriverTripEvent {
  const DriverTripPaymentConfirmed(this.requestId);
  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

/// Driver cancels the trip.
class DriverTripCancelRequested extends DriverTripEvent {
  const DriverTripCancelRequested({
    required this.requestId,
    required this.reason,
    this.customReason,
  });

  final String requestId;
  final String reason;
  final String? customReason;

  @override
  List<Object?> get props => [requestId, reason];
}

/// Driver submits rating for the passenger.
class DriverTripRatingSubmitted extends DriverTripEvent {
  const DriverTripRatingSubmitted({
    required this.requestId,
    required this.rating,
    this.comment,
  });

  final String requestId;
  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [requestId, rating];
}

/// Driver updates location during active trip.
class DriverTripLocationUpdated extends DriverTripEvent {
  const DriverTripLocationUpdated({
    required this.lat,
    required this.lng,
    required this.bearing,
  });

  final double lat;
  final double lng;
  final double bearing;

  @override
  List<Object?> get props => [lat, lng, bearing];
}

/// Check and restore an active trip on app startup.
/// If the driver was in a trip and killed the app, this event
/// restores the trip state by fetching `onTripRequest` from the API.
class DriverTripCheckActiveTrip extends DriverTripEvent {
  const DriverTripCheckActiveTrip();
}

/// Reset the driver trip flow.
class DriverTripReset extends DriverTripEvent {
  const DriverTripReset();
}

/// Upload a shipment proof image (before-load or after-load).
class DriverTripUploadShipmentProof extends DriverTripEvent {
  const DriverTripUploadShipmentProof({
    required this.requestId,
    required this.imagePath,
    required this.isBefore,
  });

  final String requestId;
  final String imagePath;
  final bool isBefore;

  @override
  List<Object?> get props => [requestId, imagePath, isBefore];
}
