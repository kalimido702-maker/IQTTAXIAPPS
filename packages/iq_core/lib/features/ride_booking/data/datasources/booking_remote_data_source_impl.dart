import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/cancel_reason_model.dart';
import '../models/invoice_model.dart';
import '../models/ride_request_response_model.dart';
import '../models/vehicle_type_model.dart';
import 'booking_remote_data_source.dart';

/// Dio implementation of [BookingRemoteDataSource].
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl({required this.dio});

  final Dio dio;

  // ─── Passenger APIs ───

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    int rideType = 1,
    String transportType = 'taxi',
    String? promoCode,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/eta',
        data: FormData.fromMap({
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'ride_type': rideType,
          'transport_type': transportType,
          if (promoCode != null) 'promo_code': promoCode,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeModel.fromJson)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في الحصول على الأسعار',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/create',
        data: FormData.fromMap({
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'pick_address': pickAddress,
          'drop_address': dropAddress,
          'vehicle_type': vehicleType,
          'payment_opt': paymentOpt,
          'ride_type': rideType,
          'transport_type': transportType,
          if (promoCode != null) 'promo_code': promoCode,
          if (polyline != null) 'polyline': polyline,
          if (requestEtaAmount != null) 'request_eta_amount': requestEtaAmount,
          if (instructions != null) 'instructions': instructions,
          'is_bid_ride': isBidRide,
          if (offerAmount != null) 'offer_amount': offerAmount,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Right(RideRequestResponseModel.fromJson(body));
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في إنشاء الطلب',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelRequest({
    required String requestId,
    required String reason,
    String? customReason,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/cancel',
        data: FormData.fromMap({
          'request_id': requestId,
          'reason': reason,
          if (customReason != null) 'custom_reason': customReason,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في إلغاء الطلب',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CancelReasonModel>>> getCancelReasons() async {
    try {
      final response = await dio.get('api/v1/common/cancallation/reasons');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CancelReasonModel.fromJson)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في جلب أسباب الإلغاء',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentSearches() async {
    try {
      final response = await dio.get('api/v1/request/list-recent-searches');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((item) {
          return {
            'pick_address': item['pick_address'],
            'pick_lat': item['pick_lat'],
            'pick_lng': item['pick_lng'],
            'drop_address': item['drop_address'],
            'drop_lat': item['drop_lat'],
            'drop_lng': item['drop_lng'],
          };
        }).toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في تحميل الأماكن الأخيرة',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitRating({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/rating',
        data: FormData.fromMap({
          'request_id': requestId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في إرسال التقييم',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changeDropLocation({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    String? polyline,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/change-drop-location',
        data: FormData.fromMap({
          'request_id': requestId,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'drop_address': dropAddress,
          if (polyline != null) 'polyline': polyline,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? 'فشل في تغيير نقطة الوصول',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changePaymentMethod({
    required String requestId,
    required int paymentOpt,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/user/payment-method',
        data: FormData.fromMap({
          'request_id': requestId,
          'payment_opt': paymentOpt,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? 'فشل في تغيير طريقة الدفع',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvoiceModel>> getTripInvoice({
    required String requestId,
  }) async {
    try {
      final response = await dio.get('api/v1/request/history');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        // Find the specific trip in history
        final list = body['data'] is Map
            ? (body['data']['data'] as List? ?? [])
            : (body['data'] as List? ?? []);

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] ?? item['request_id']).toString();
            if (id == requestId) {
              return Right(InvoiceModel.fromJson(item));
            }
          }
        }
        return Left(
            const ServerFailure(message: 'لم يتم العثور على الفاتورة'));
      }
      return Left(ServerFailure(
        message:
            body['message']?.toString() ?? 'فشل في جلب تفاصيل الرحلة',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─── Driver APIs ───

  @override
  Future<Either<Failure, bool>> respondToRequest({
    required String requestId,
    required bool isAccept,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/respond',
        data: FormData.fromMap({
          'request_id': requestId,
          'is_accept': isAccept ? 1 : 0,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في الاستجابة للطلب',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markArrived({
    required String requestId,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/arrived',
        data: FormData.fromMap({'request_id': requestId}),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في تأكيد الوصول',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> startRide({
    required String requestId,
    required double pickLat,
    required double pickLng,
    String? otp,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/started',
        data: FormData.fromMap({
          'request_id': requestId,
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          if (otp != null) 'otp': otp,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في بدء الرحلة',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> endRide({
    required String requestId,
    required double dropLat,
    required double dropLng,
    required double distance,
    int beforeTripWaitingTime = 0,
    int afterTripWaitingTime = 0,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/end',
        data: FormData.fromMap({
          'request_id': requestId,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'distance': distance,
          'before_trip_start_waiting_time': beforeTripWaitingTime,
          'after_trip_start_waiting_time': afterTripWaitingTime,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في إنهاء الرحلة',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> confirmPayment({
    required String requestId,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/payment-confirm',
        data: FormData.fromMap({'request_id': requestId}),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في تأكيد الدفع',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelByDriver({
    required String requestId,
    required String reason,
    String? customReason,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/cancel/by-driver',
        data: FormData.fromMap({
          'request_id': requestId,
          'reason': reason,
          if (customReason != null) 'custom_reason': customReason,
        }),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(true);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في إلغاء الرحلة',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(message: 'انتهت مهلة الاتصال');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure(message: 'لا يوجد اتصال بالإنترنت');
    }
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final message = body is Map ? body['message']?.toString() : null;

    if (statusCode == 401) {
      return AuthFailure(message: message ?? 'غير مصرح');
    }
    if (statusCode == 422) {
      return ValidationFailure(message: message ?? 'بيانات غير صالحة');
    }
    return ServerFailure(message: message ?? 'حدث خطأ في الخادم');
  }
}
