import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/support_message_entity.dart';

/// Result of loading chat history — includes messages + chat_id.
class ChatHistoryResult {
  final List<SupportMessageEntity> messages;
  final String? chatId;

  const ChatHistoryResult({required this.messages, this.chatId});
}

/// Contract for admin support chat repository.
abstract class SupportChatRepository {
  /// Load conversation history.
  Future<Either<Failure, ChatHistoryResult>> getChatHistory({
    required String conversationId,
    required String currentUserId,
  });

  /// Send a message. Returns the conversation ID
  /// (important for new conversations).
  Future<Either<Failure, String>> sendMessage({
    String? conversationId,
    required String message,
  });

  /// Mark messages as read.
  Future<Either<Failure, void>> markMessagesSeen({
    required String conversationId,
  });
}
