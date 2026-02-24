import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/cancel_reason_model.dart';
import '../models/invoice_model.dart';
import '../models/ride_request_response_model.dart';
import '../models/vehicle_type_model.dart';

/// Remote data source for booking / trip lifecycle API calls.
abstract class BookingRemoteDataSource {
  // ─── Passenger APIs ───

  /// Get ETA with vehicle types and pricing.
  Future<Either<Failure, List<VehicleTypeModel>>> getEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
  });

  /// Create a ride request.
  Future<Either<Failure, RideRequestResponseModel>> createRideRequest({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    required String pickAddress,
    required String dropAddress,
    required int vehicleType,
    required int paymentOpt,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
    String? polyline,
    double? requestEtaAmount,
    String? instructions,
    int isBidRide = 0,
    double? offerAmount,
  });

  /// Cancel a ride request.
  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
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
    required double distance,
    int beforeTripWaitingTime = 0,
    int afterTripWaitingTime = 0,
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
}
