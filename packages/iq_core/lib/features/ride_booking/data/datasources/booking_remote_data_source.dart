import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/cancel_reason_model.dart';
import '../models/incoming_request_model.dart';
import '../models/invoice_model.dart';
import '../models/ride_request_response_model.dart';
import '../models/vehicle_type_model.dart';

/// Remote data source for booking / trip lifecycle API calls.
abstract class BookingRemoteDataSource {
  // ─── Passenger APIs ───

  /// Get ETA with vehicle types and pricing.
  /// Pass [distance] (metres) and [duration] (**minutes**, not seconds)
  /// along with [polyline] from Google Directions so the server can
  /// compute the correct fare.
  Future<Either<Failure, List<VehicleTypeModel>>> getEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
    double? distance,
    double? duration,
    String? polyline,
    String? pickAddress,
    String? dropAddress,
    List<Map<String, dynamic>>? stops,
  });

  /// Create a ride request.
  Future<Either<Failure, RideRequestResponseModel>> createRideRequest({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    required String pickAddress,
    required String dropAddress,
    required String vehicleType,
    required int paymentOpt,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
    String? polyline,
    double? requestEtaAmount,
    String? instructions,
    int isBidRide = 0,
    double? offerAmount,
    int isLater = 0,
    String? tripStartTime,
    List<Map<String, dynamic>>? selectedPreferences,
    String? distance,
    String? duration,
    String? promocodeId,
    double? discountedTotal,
    List<Map<String, dynamic>>? stops,
  });

  /// Cancel a ride request.
  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
    int? cancelMethod,
  });

  /// Get cancel reasons.
  Future<Either<Failure, List<CancelReasonModel>>> getCancelReasons();

  /// Get recent searches / routes (quick places).
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentSearches();

  /// Submit rating.
  Future<Either<Failure, bool>> submitRating({
    required String requestId,
    required int rating,
    String? comment,
  });

  /// Change drop location during active trip.
  Future<Either<Failure, bool>> changeDropLocation({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String? polyline,
  });

  /// Change payment method during trip.
  Future<Either<Failure, bool>> changePaymentMethod({
    required String requestId,
    required int paymentOpt,
  });

  /// Get trip invoice/details after completion.
  Future<Either<Failure, InvoiceModel>> getTripInvoice({
    required String requestId,
  });

  // ─── Driver APIs ───

  /// Accept or reject a ride request.
  Future<Either<Failure, bool>> respondToRequest({
    required String requestId,
    required bool isAccept,
  });

  /// Mark driver as arrived at pickup.
  Future<Either<Failure, bool>> markArrived({
    required String requestId,
  });

  /// Start the ride.
  Future<Either<Failure, bool>> startRide({
    required String requestId,
    required double pickLat,
    required double pickLng,
    String? otp,
  });

  /// End the ride.
  Future<Either<Failure, bool>> endRide({
    required String requestId,
    required double dropLat,
    required double dropLng,
    double pickLat = 0,
    double pickLng = 0,
    String dropAddress = '',
    String polyLine = '',
    required double distance,
    int beforeTripWaitingTime = 0,
    int afterTripWaitingTime = 0,
  });

  /// Create a QiCard payment for a ride. Returns the payment URL.
  Future<Either<Failure, String>> createRidePayment({
    required String requestId,
    required double amount,
  });

  /// Confirm cash payment received.
  Future<Either<Failure, bool>> confirmPayment({
    required String requestId,
  });

  /// Cancel ride by driver.
  Future<Either<Failure, bool>> cancelByDriver({
    required String requestId,
    required String reason,
    String? customReason,
  });

  /// Fetch pending incoming request from the user-details API.
  ///
  /// Calls `GET api/v1/user` and extracts `metaRequest.data` — the
  /// backend embeds the full ride details there when a request is
  /// pending for this driver.
  Future<Either<Failure, IncomingRequestModel?>> fetchPendingRequest();

  /// Fetch an already-accepted active trip from the user-details API.
  ///
  /// Calls `GET api/v1/user` and extracts `onTripRequest.data` — the
  /// backend returns this when the driver has an ongoing trip.
  /// Returns the request model with the trip ID needed to start
  /// the Firebase stream.
  Future<Either<Failure, IncomingRequestModel?>> fetchOnTripRequest();

  /// (Passenger) Fetch active trip details including driver info and fare.
  ///
  /// Calls `GET api/v1/request/history/{requestId}` which returns full
  /// trip details with nested `driverDetail` and `requestBill`.
  /// Returns a map of enrichment fields compatible with
  /// [ActiveTripModel.copyWith].
  Future<Either<Failure, Map<String, dynamic>>>
      fetchPassengerActiveTripDetails({required String requestId});

  // ─── Delivery / Shipment APIs ───

  /// Upload shipment proof image (before/after loading).
  ///
  /// Calls `POST api/v1/request/upload-proof` with the image file
  /// and a flag indicating whether it's before-load or after-load.
  Future<Either<Failure, bool>> uploadShipmentProof({
    required String requestId,
    required String imagePath,
    required bool isBefore,
  });
}
