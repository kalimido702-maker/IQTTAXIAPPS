import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/incentive_model.dart';
import 'incentive_data_source.dart';

/// Production implementation of [IncentiveDataSource].
class IncentiveDataSourceImpl implements IncentiveDataSource {
  final Dio dio;

  IncentiveDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, IncentiveResponse>> getIncentives({
    required int type,
  }) async {
    try {
      // type 0 → daily (today), type 1 → weekly
      final endpoint = type == 0
          ? 'api/v1/driver/new-incentives'
          : 'api/v1/driver/week-incentives';

      final response = await dio.get(endpoint);
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(IncentiveResponse.fromJson(body));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل تحميل الحوافز',
        statusCode: response.statusCode,
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
      return const NetworkFailure();
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ServerFailure(
        message: data['message']?.toString() ?? 'خطأ في الخادم',
        statusCode: e.response?.statusCode,
      );
    }
    return ServerFailure(
      message: e.message ?? 'خطأ في الخادم',
      statusCode: e.response?.statusCode,
    );
  }
}
