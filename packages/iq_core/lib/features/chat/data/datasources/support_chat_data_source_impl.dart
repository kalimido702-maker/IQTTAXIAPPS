import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../models/support_message_model.dart';
import 'support_chat_data_source.dart';

const _kConversationIdKey = 'support_chat_conversation_id';

/// Production implementation of [SupportChatDataSource].
class SupportChatDataSourceImpl implements SupportChatDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  SupportChatDataSourceImpl({required this.dio, required this.prefs});

  @override
  Future<Either<Failure, SupportChatHistoryResponse>> getChatHistory({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      // Backend: GET api/v1/request/user-chat-history
      // Query param: conversation_id
      final response = await dio.get(
        'api/v1/request/user-chat-history',
        queryParameters: conversationId.isNotEmpty
            ? {'conversation_id': conversationId}
            : null,
      );

      final body = _safeMap(response.data);

      if (response.statusCode == 200 && body['success'] == true) {
        final parsed = SupportChatHistoryResponse.fromJson(
          body,
          currentUserId: currentUserId,
        );

        // Cache the chat_id so it persists across navigation
        if (parsed.conversationId != null &&
            parsed.conversationId!.isNotEmpty) {
          prefs.setString(_kConversationIdKey, parsed.conversationId!);
        }

        return Right(parsed);
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? 'فشل تحميل المحادثة',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> sendMessage({
    String? conversationId,
    required String message,
  }) async {
    try {
      // Backend: POST api/v1/request/user-send-message
      // Required: new_conversation (1 or 0), content
      // When existing chat: also send conversation_id
      final Map<String, dynamic> data = {'content': message};

      if (conversationId != null && conversationId.isNotEmpty) {
        data['conversation_id'] = conversationId;
        data['new_conversation'] = 0;
      } else {
        data['new_conversation'] = 1;
      }

      final response = await dio.post(
        'api/v1/request/user-send-message',
        data: data,
      );

      final body = _safeMap(response.data);

      if (response.statusCode == 200 && body['success'] == true) {
        // Backend may return conversation_id in various places
        final respData = _safeMap(body['data']);
        final chatData = _safeMap(respData['chat_data']);
        final newChatId =
            (respData['conversation_id'] ?? chatData['id'] ?? respData['chat_id'] ?? conversationId ?? '')
                .toString();

        // Cache locally so it persists across navigation
        if (newChatId.isNotEmpty) {
          prefs.setString(_kConversationIdKey, newChatId);
        }

        return Right(newChatId);
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? 'فشل إرسال الرسالة',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesSeen({
    required String conversationId,
  }) async {
    try {
      final response = await dio.get(
        'api/v1/request/update-notification-count',
        queryParameters: {'conversation_id': conversationId},
      );

      final body = _safeMap(response.data);

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: _extractMessage(body) ?? 'فشل تحديث حالة القراءة',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  String? getSavedConversationId() {
    return prefs.getString(_kConversationIdKey);
  }

  /// Safely convert [raw] to Map<String, dynamic>.
  /// Handles: Map, String (JSON), or anything else → empty map.
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
  /// Backend may return `message` as a String or List<String>.
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
      return const ServerFailure(message: 'انتهت مهلة الاتصال');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ServerFailure(
          message: data['message']?.toString() ?? 'حدث خطأ في الخادم',
          statusCode: e.response!.statusCode,
        );
      }
    }
    return ServerFailure(message: e.message ?? 'حدث خطأ غير متوقع');
  }
}
