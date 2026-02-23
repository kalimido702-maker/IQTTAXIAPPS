import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/weekly_earnings_model.dart';
import 'earnings_data_source.dart';

/// Production implementation of [EarningsDataSource].
class EarningsDataSourceImpl implements EarningsDataSource {
  final Dio dio;

  EarningsDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, WeeklyEarningsModel>> getWeeklyEarnings({
    int? weekNumber,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (weekNumber != null) {
        queryParams['week_number'] = weekNumber;
      }

      final response = await dio.get(
        'api/v1/driver/weekly-earnings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(WeeklyEarningsModel.fromJson(body));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل تحميل الأرباح',
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
