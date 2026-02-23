import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/trip_entity.dart';
import '../models/trip_history_model.dart';
import 'trip_data_source.dart';

/// Production implementation of [TripDataSource].
class TripDataSourceImpl implements TripDataSource {
  final Dio dio;

  TripDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, TripHistoryResponse>> getTripHistory({
    required int page,
    required String type,
  }) async {
    try {
      final response = await dio.get(
        'api/v1/request/history',
        queryParameters: {
          'page': page,
          'type': type,
        },
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(TripHistoryResponse.fromJson(body));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل تحميل سجل الرحلات',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId) async {
    try {
      // The backend doesn't have a dedicated trip detail endpoint,
      // we fetch from history and find by ID. If a dedicated endpoint
      // is added later, replace this implementation.
      final response = await dio.get(
        'api/v1/request/history',
        queryParameters: {
          'page': 1,
          'type': 'is_completed',
        },
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final historyResponse = TripHistoryResponse.fromJson(body);
        final trip = historyResponse.trips.where((t) => t.id == tripId);
        if (trip.isNotEmpty) {
          return Right(trip.first);
        }
        return const Left(
          ServerFailure(message: 'لم يتم العثور على الرحلة'),
        );
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? 'فشل تحميل تفاصيل الرحلة',
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
