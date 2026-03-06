import 'package:equatable/equatable.dart';

import '../../../data/models/active_trip_model.dart';
import '../../../data/models/incoming_request_model.dart';

/// Overall status of the driver trip flow.
enum DriverTripStatus {
  /// Idle — online, waiting for requests.
  idle,

  /// An incoming ride request appeared.
  incomingRequest,

  /// Driver accepted, navigating to pickup.
  navigatingToPickup,

  /// Driver arrived at pickup location.
  arrivedAtPickup,

  /// Trip in progress.
  tripInProgress,

  /// Trip completed — invoice shown.
  tripCompleted,

  /// Driver submitted rating — flow done.
  rated,

  /// Trip was cancelled.
  cancelled,

  /// Loading / processing action.
  loading,

  /// Error occurred.
  error,
}

/// State for the driver trip BLoC.
class DriverTripState extends Equatable {
  const DriverTripState({
    this.status = DriverTripStatus.idle,
    this.incomingRequest,
    this.requestId,
    this.activeTripData,
    this.errorMessage,
    this.driverId,
    this.tripDistance = 0.0,
    this.lastLat,
    this.lastLng,
    this.latLngArray = const [],
    this.waitingTimeBeforeStart = 0,
    this.waitingTimeAfterStart = 0,
  });

  final DriverTripStatus status;

  /// The incoming ride request details.
  final IncomingRequestModel? incomingRequest;

  /// Active trip request ID.
  final String? requestId;

  /// Real-time trip data from Firebase.
  final ActiveTripModel? activeTripData;

  /// Error message, if any.
  final String? errorMessage;

  /// The driver's own ID.
  final String? driverId;

  /// GPS-accumulated trip distance in kilometres.
  final double tripDistance;

  /// Last known latitude (for distance accumulation).
  final double? lastLat;

  /// Last known longitude (for distance accumulation).
  final double? lastLng;

  /// Trail of lat/lng pairs recorded during the trip.
  final List<String> latLngArray;

  /// Waiting time (in seconds) before the trip started (driver arrived → trip start).
  final int waitingTimeBeforeStart;

  /// Waiting time (in seconds) after the trip started (if the driver pauses / idles).
  final int waitingTimeAfterStart;

  DriverTripState copyWith({
    DriverTripStatus? status,
    IncomingRequestModel? incomingRequest,
    String? requestId,
    ActiveTripModel? activeTripData,
    String? errorMessage,
    String? driverId,
    double? tripDistance,
    double? lastLat,
    double? lastLng,
    List<String>? latLngArray,
    int? waitingTimeBeforeStart,
    int? waitingTimeAfterStart,
  }) {
    return DriverTripState(
      status: status ?? this.status,
      incomingRequest: incomingRequest ?? this.incomingRequest,
      requestId: requestId ?? this.requestId,
      activeTripData: activeTripData ?? this.activeTripData,
      errorMessage: errorMessage,
      driverId: driverId ?? this.driverId,
      tripDistance: tripDistance ?? this.tripDistance,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      latLngArray: latLngArray ?? this.latLngArray,
      waitingTimeBeforeStart:
          waitingTimeBeforeStart ?? this.waitingTimeBeforeStart,
      waitingTimeAfterStart:
          waitingTimeAfterStart ?? this.waitingTimeAfterStart,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incomingRequest,
        requestId,
        activeTripData,
        errorMessage,
        tripDistance,
        lastLat,
        lastLng,
        latLngArray,
        waitingTimeBeforeStart,
        waitingTimeAfterStart,
      ];
}
