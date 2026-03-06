import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/cancel_reason_model.dart';
import '../../data/models/incoming_request_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/ride_request_response_model.dart';
import '../../data/models/vehicle_type_model.dart';
import '../../domain/repositories/booking_repository.dart';

/// Thin delegate that forwards all calls to [BookingRemoteDataSource].
class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl({required this.dataSource});

  final BookingRemoteDataSource dataSource;

  @override
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
  }) =>
      dataSource.getEta(
        pickLat: pickLat,
        pickLng: pickLng,
        dropLat: dropLat,
        dropLng: dropLng,
        rideType: rideType,
        transportType: transportType,
        promoCode: promoCode,
        distance: distance,
        duration: duration,
        polyline: polyline,
        pickAddress: pickAddress,
        dropAddress: dropAddress,
      );

  @override
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
  }) =>
      dataSource.createRideRequest(
        pickLat: pickLat,
        pickLng: pickLng,
        dropLat: dropLat,
        dropLng: dropLng,
        pickAddress: pickAddress,
        dropAddress: dropAddress,
        vehicleType: vehicleType,
        paymentOpt: paymentOpt,
        rideType: rideType,
        transportType: transportType,
        promoCode: promoCode,
        polyline: polyline,
        requestEtaAmount: requestEtaAmount,
        instructions: instructions,
        isBidRide: isBidRide,
        offerAmount: offerAmount,
        isLater: isLater,
        tripStartTime: tripStartTime,
        selectedPreferences: selectedPreferences,
        distance: distance,
        duration: duration,
        promocodeId: promocodeId,
        discountedTotal: discountedTotal,
      );

  @override
  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
    int? cancelMethod,
  }) =>
      dataSource.cancelRequest(
        requestId: requestId,
        reason: reason,
        customReason: customReason,
        cancelMethod: cancelMethod,
      );

  @override
  Future<Either<Failure, List<CancelReasonModel>>> getCancelReasons() =>
      dataSource.getCancelReasons();

    @override
    Future<Either<Failure, List<Map<String, dynamic>>>> getRecentSearches() =>
      dataSource.getRecentSearches();

  @override
  Future<Either<Failure, bool>> submitRating({
    required String requestId,
    required int rating,
    String? comment,
  }) =>
      dataSource.submitRating(
        requestId: requestId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<Either<Failure, bool>> changeDropLocation({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String? polyline,
  }) =>
      dataSource.changeDropLocation(
        requestId: requestId,
        dropLat: dropLat,
        dropLng: dropLng,
        dropAddress: dropAddress,
        polyline: polyline,
      );

  @override
  Future<Either<Failure, bool>> changePaymentMethod({
    required String requestId,
    required int paymentOpt,
  }) =>
      dataSource.changePaymentMethod(
        requestId: requestId,
        paymentOpt: paymentOpt,
      );

  @override
  Future<Either<Failure, InvoiceModel>> getTripInvoice({
    required String requestId,
  }) =>
      dataSource.getTripInvoice(requestId: requestId);

  @override
  Future<Either<Failure, bool>> respondToRequest({
    required String requestId,
    required bool isAccept,
  }) =>
      dataSource.respondToRequest(
        requestId: requestId,
        isAccept: isAccept,
      );

  @override
  Future<Either<Failure, bool>> markArrived({
    required String requestId,
  }) =>
      dataSource.markArrived(requestId: requestId);

  @override
  Future<Either<Failure, bool>> startRide({
    required String requestId,
    required double pickLat,
    required double pickLng,
    String? otp,
  }) =>
      dataSource.startRide(
        requestId: requestId,
        pickLat: pickLat,
        pickLng: pickLng,
        otp: otp,
      );

  @override
  Future<Either<Failure, bool>> endRide({
    required String requestId,
    required double dropLat,
    required double dropLng,
    String dropAddress = '',
    String polyLine = '',
    required double distance,
    int beforeTripWaitingTime = 0,
    int afterTripWaitingTime = 0,
  }) =>
      dataSource.endRide(
        requestId: requestId,
        dropLat: dropLat,
        dropLng: dropLng,
        dropAddress: dropAddress,
        polyLine: polyLine,
        distance: distance,
        beforeTripWaitingTime: beforeTripWaitingTime,
        afterTripWaitingTime: afterTripWaitingTime,
      );

  @override
  Future<Either<Failure, String>> createRidePayment({
    required String requestId,
    required double amount,
  }) =>
      dataSource.createRidePayment(requestId: requestId, amount: amount);

  @override
  Future<Either<Failure, bool>> confirmPayment({
    required String requestId,
  }) =>
      dataSource.confirmPayment(requestId: requestId);

  @override
  Future<Either<Failure, bool>> cancelByDriver({
    required String requestId,
    required String reason,
    String? customReason,
  }) =>
      dataSource.cancelByDriver(
        requestId: requestId,
        reason: reason,
        customReason: customReason,
      );

  @override
  Future<Either<Failure, IncomingRequestModel?>> fetchPendingRequest() =>
      dataSource.fetchPendingRequest();

  @override
  Future<Either<Failure, IncomingRequestModel?>> fetchOnTripRequest() =>
      dataSource.fetchOnTripRequest();

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      fetchPassengerActiveTripDetails({required String requestId}) =>
          dataSource.fetchPassengerActiveTripDetails(requestId: requestId);
}
