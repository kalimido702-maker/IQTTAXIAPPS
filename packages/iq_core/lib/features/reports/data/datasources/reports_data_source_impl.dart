import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../models/reports_model.dart';
import 'reports_data_source.dart';

/// Production implementation of [ReportsDataSource].
class ReportsDataSourceImpl implements ReportsDataSource {
  final Dio dio;

  ReportsDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, ReportsModel>> getEarningsReport({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final response = await dio.get(
        'api/v1/driver/earnings-report/$fromDate/$toDate',
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(ReportsModel.fromJson(body));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل تحميل التقارير',
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
