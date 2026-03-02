import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/home_data_model.dart';
import '../models/ongoing_ride_model.dart';
import '../models/ride_module_model.dart';
import 'home_data_source.dart';

/// Production implementation of [HomeDataSource].
///
/// Uses the real IQ Taxi REST API.
class HomeDataSourceImpl implements HomeDataSource {
  final Dio dio;

  HomeDataSourceImpl({required this.dio});

  // ──────────────────────────────────────────
  //  GET USER DETAILS
  //  GET api/v1/user
  // ──────────────────────────────────────────

  @override
  Future<Either<Failure, HomeDataModel>> getUserDetails() async {
    try {
      final response = await dio.get('api/v1/user');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        return Right(HomeDataModel.fromJson(data));
      }

      return Left(
        ServerFailure(
          message:
              body['message']?.toString() ?? 'فشل تحميل بيانات المستخدم',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────
  //  TOGGLE DRIVER STATUS
  //  POST api/v1/driver/online-offline
  // ──────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> toggleDriverStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) async {
    try {
      // The backend toggles status automatically — a simple POST
      // with no body flips active 0↔1. We don't need to send
      // is_active or coordinates; the server handles it.
      final response = await dio.post(
        'api/v1/driver/online-offline',
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        // The server returns the new driver profile in 'data'.
        // Read the 'active' field to know the actual new status.
        final data = body['data'] as Map<String, dynamic>?;
        final isActive = data?['active'] == true ||
            data?['active'] == 1 ||
            data?['active']?.toString() == '1';
        return Right(isActive);
      }

      return Left(
        ServerFailure(
          message: body['message']?.toString() ?? 'فشل تغيير الحالة',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────
  //  GET RIDE MODULES (SERVICE CATEGORIES)
  //  GET api/v1/common/ride_modules
  // ──────────────────────────────────────────

  @override
  Future<Either<Failure, List<RideModuleModel>>> getRideModules() async {
    try {
      final response = await dio.get('api/v1/common/ride_modules');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final rawList = body['data'] as List<dynamic>? ?? [];
        final modules = rawList
            .whereType<Map<String, dynamic>>()
            .map(RideModuleModel.fromJson)
            .where((m) => m.enabled)
            .toList();
        return Right(modules);
      }

      return Left(
        ServerFailure(
          message:
              body['message']?.toString() ?? 'فشل تحميل أنواع الخدمة',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────
  //  GET ONGOING RIDES
  //  GET api/v1/request/history?on_trip=1
  // ──────────────────────────────────────────

  @override
  Future<Either<Failure, List<OngoingRideModel>>> getOngoingRides() async {
    try {
      final response = await dio.get(
        'api/v1/request/history',
        queryParameters: {'on_trip': '1'},
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final rawList = body['data'] as List<dynamic>? ?? [];
        final rides = rawList
            .whereType<Map<String, dynamic>>()
            .map(OngoingRideModel.fromJson)
            .toList();
        return Right(rides);
      }

      return Left(
        ServerFailure(
          message:
              body['message']?.toString() ?? 'فشل تحميل الرحلات النشطة',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ──────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(message: 'انتهت مهلة الاتصال');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'حدث خطأ في الخادم';

    if (data is Map<String, dynamic>) {
      message = data['message']?.toString() ?? message;
    }

    return ServerFailure(message: message, statusCode: statusCode);
  }
}
