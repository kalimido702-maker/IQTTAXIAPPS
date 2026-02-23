import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/support_message_entity.dart';
import '../../domain/repositories/support_chat_repository.dart';
import '../datasources/support_chat_data_source.dart';

/// Production implementation of [SupportChatRepository].
class SupportChatRepositoryImpl implements SupportChatRepository {
  final SupportChatDataSource dataSource;

  SupportChatRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, ChatHistoryResult>> getChatHistory({
    required String conversationId,
    required String currentUserId,
  }) async {
    final result = await dataSource.getChatHistory(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
    return result.map((response) => ChatHistoryResult(
          messages: response.messages.cast<SupportMessageEntity>(),
          chatId: response.conversationId,
        ));
  }

  @override
  Future<Either<Failure, String>> sendMessage({
    String? conversationId,
    required String message,
  }) {
    return dataSource.sendMessage(
      conversationId: conversationId,
      message: message,
    );
  }

  @override
  Future<Either<Failure, void>> markMessagesSeen({
    required String conversationId,
  }) {
    return dataSource.markMessagesSeen(conversationId: conversationId);
  }
}
