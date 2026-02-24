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

  DriverTripState copyWith({
    DriverTripStatus? status,
    IncomingRequestModel? incomingRequest,
    String? requestId,
    ActiveTripModel? activeTripData,
    String? errorMessage,
    String? driverId,
  }) {
    return DriverTripState(
      status: status ?? this.status,
      incomingRequest: incomingRequest ?? this.incomingRequest,
      requestId: requestId ?? this.requestId,
      activeTripData: activeTripData ?? this.activeTripData,
      errorMessage: errorMessage,
      driverId: driverId ?? this.driverId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incomingRequest,
        requestId,
        activeTripData,
        errorMessage,
      ];
}
