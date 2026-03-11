import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/notification_model.dart';
import 'notification_data_source.dart';

/// Production implementation of [NotificationDataSource].
class NotificationDataSourceImpl implements NotificationDataSource {
  final Dio dio;

  NotificationDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, (List<NotificationModel>, NotificationPagination)>>
      getNotifications({int page = 1}) async {
    try {
      final response = await dio.get(
        'api/v1/notifications/get-notification',
        queryParameters: {'page': page},
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final rawData = body['data'] as List<dynamic>? ?? [];
        final notifications = rawData
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();

        final meta = body['meta'] as Map<String, dynamic>? ?? {};
        final pagination = NotificationPagination.fromJson(meta);

        return Right((notifications, pagination));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToLoadNotifications,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      final response =
          await dio.get('api/v1/notifications/delete-notification/$id');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToDeleteNotification,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllNotifications() async {
    try {
      final response =
          await dio.get('api/v1/notifications/delete-all-notification');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToClearNotifications,
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
      return NetworkFailure(message: AppStrings.connectionTimeout);
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure();
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ServerFailure(
        message: data['message']?.toString() ?? AppStrings.serverError,
        statusCode: e.response?.statusCode,
      );
    }
    return ServerFailure(
      message: e.message ?? AppStrings.serverError,
      statusCode: e.response?.statusCode,
    );
  }
}
