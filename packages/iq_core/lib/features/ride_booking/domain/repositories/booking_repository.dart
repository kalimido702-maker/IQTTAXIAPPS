import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/cancel_reason_model.dart';
import '../../data/models/incoming_request_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/ride_request_response_model.dart';
import '../../data/models/vehicle_type_model.dart';

/// Repository contract for ride booking operations.
abstract class BookingRepository {
  // ─── Passenger ───
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
  });

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
  });

  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
    int? cancelMethod,
  });

  Future<Either<Failure, List<CancelReasonModel>>> getCancelReasons();

  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentSearches();

  Future<Either<Failure, bool>> submitRating({
    required String requestId,
    required int rating,
    String? comment,
  });

  Future<Either<Failure, bool>> changeDropLocation({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String? polyline,
  });

  Future<Either<Failure, bool>> changePaymentMethod({
    required String requestId,
    required int paymentOpt,
  });

  Future<Either<Failure, InvoiceModel>> getTripInvoice({
    required String requestId,
  });

  // ─── Driver ───
  Future<Either<Failure, bool>> respondToRequest({
    required String requestId,
    required bool isAccept,
  });

  Future<Either<Failure, bool>> markArrived({
    required String requestId,
  });

  Future<Either<Failure, bool>> startRide({
    required String requestId,
    required double pickLat,
    required double pickLng,
    String? otp,
  });

  Future<Either<Failure, bool>> endRide({
    required String requestId,
    required double dropLat,
    required double dropLng,
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

  Future<Either<Failure, bool>> confirmPayment({
    required String requestId,
  });

  Future<Either<Failure, bool>> cancelByDriver({
    required String requestId,
    required String reason,
    String? customReason,
  });

  /// Fetch pending incoming request details from the user API.
  Future<Either<Failure, IncomingRequestModel?>> fetchPendingRequest();

  /// Fetch an already-accepted ongoing trip from the user API.
  Future<Either<Failure, IncomingRequestModel?>> fetchOnTripRequest();

  /// (Passenger) Fetch active trip details with driver info and fare.
  Future<Either<Failure, Map<String, dynamic>>>
      fetchPassengerActiveTripDetails({required String requestId});
}
