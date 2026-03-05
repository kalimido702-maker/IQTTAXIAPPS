import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/goods_type_model.dart';
import '../models/parcel_request_model.dart';
import '../../../ride_booking/data/models/ride_request_response_model.dart';
import '../../../ride_booking/data/models/vehicle_type_model.dart';

/// Remote data source for package delivery API calls.
abstract class PackageDeliveryDataSource {
  /// `GET api/v1/common/goods-types`
  Future<Either<Failure, List<GoodsTypeModel>>> getGoodsTypes();

  /// `POST api/v1/request/eta` with `transport_type: 'delivery'`
  Future<Either<Failure, List<VehicleTypeModel>>> getDeliveryEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    String? promoCode,
  });

  /// `POST api/v1/request/delivery/create`
  Future<Either<Failure, RideRequestResponseModel>> createDeliveryRequest({
    required ParcelRequestModel request,
  });
}

class PackageDeliveryDataSourceImpl implements PackageDeliveryDataSource {
  PackageDeliveryDataSourceImpl({required this.dio});

  final Dio dio;

  @override
  Future<Either<Failure, List<GoodsTypeModel>>> getGoodsTypes() async {
    try {
      final response = await dio.get('api/v1/common/goods-types');
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(GoodsTypeModel.fromJson)
            .where((g) => g.active)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل في جلب أنواع البضائع',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getDeliveryEta({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
    String? promoCode,
  }) async {
    try {
      final requestData = {
          'pick_lat': pickLat,
          'pick_lng': pickLng,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'ride_type': 1,
          'transport_type': 'delivery',
          if (promoCode != null) 'promo_code': promoCode,
      };
      debugPrint('📦 [DeliveryETA] REQUEST: $requestData');
      final response = await dio.post(
        'api/v1/request/eta',
        data: FormData.fromMap(requestData),
      );
      final body = response.data as Map<String, dynamic>;
      debugPrint('📦 [DeliveryETA] RESPONSE: $body');
      if (response.statusCode == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(VehicleTypeModel.fromJson)
            .toList();
        return Right(list);
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToGetPrices,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideRequestResponseModel>> createDeliveryRequest({
    required ParcelRequestModel request,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/delivery/create',
        data: FormData.fromMap(request.toApiBody()),
      );
      final body = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return Right(RideRequestResponseModel.fromJson(body));
      }
      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToCreateRequest,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Error handler ──

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(message: AppStrings.connectionTimeout);
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure(message: AppStrings.noInternetConnection);
    }
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final message = body is Map ? body['message']?.toString() : null;
    if (statusCode == 401) {
      return AuthFailure(message: message ?? AppStrings.unauthorized);
    }
    if (statusCode == 422) {
      return ValidationFailure(message: message ?? AppStrings.invalidData);
    }
    return ServerFailure(message: message ?? AppStrings.serverError);
  }
}
