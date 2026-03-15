import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/trip_chat_message_model.dart';
import 'trip_chat_data_source.dart';

/// Production implementation of [TripChatDataSource].
class TripChatDataSourceImpl implements TripChatDataSource {
  final Dio dio;

  TripChatDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, List<TripChatMessageModel>>> getChatHistory({
    required String requestId,
  }) async {
    try {
      final response = await dio.get(
        'api/v1/request/chat-history/$requestId',
      );

      final body = _safeMap(response.data);

      if (body['success'] == true) {
        final rawList = body['data'];
        if (rawList is List) {
          final messages = rawList
              .whereType<Map<String, dynamic>>()
              .map(TripChatMessageModel.fromJson)
              .toList();
          return Right(messages);
        }
        return const Right([]);
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? AppStrings.failedToLoadConversation,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String requestId,
    required String message,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/send',
        data: {
          'request_id': requestId,
          'message': message,
        },
      );

      final body = _safeMap(response.data);

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? AppStrings.failedToSendMessage,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markSeen({
    required String requestId,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/request/seen',
        data: {'request_id': requestId},
      );

      final body = _safeMap(response.data);

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message:
            _extractMessage(body) ?? AppStrings.failedToUpdateReadStatus,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Safely convert [raw] to Map<String, dynamic>.
  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  /// Extract error message from API response.
  String? _extractMessage(Map<String, dynamic> body) {
    final msg = body['message'];
    if (msg == null) return null;
    if (msg is String) return msg;
    if (msg is List) return msg.join(', ');
    return msg.toString();
  }

  ServerFailure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ServerFailure(message: AppStrings.connectionTimeout);
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ServerFailure(
          message: data['message']?.toString() ?? AppStrings.serverError,
          statusCode: e.response!.statusCode,
        );
      }
    }
    return ServerFailure(message: e.message ?? AppStrings.unexpectedError);
  }
}
