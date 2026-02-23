import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/support_message_model.dart';

/// Contract for admin support chat API calls.
abstract class SupportChatDataSource {
  /// Fetch the chat history for the given conversation.
  Future<Either<Failure, SupportChatHistoryResponse>> getChatHistory({
    required String conversationId,
    required String currentUserId,
  });

  /// Send a message to admin support.
  ///
  /// If [conversationId] is `null`, sends `new_conversation: 1`
  /// to create a new conversation. Returns the conversation ID.
  Future<Either<Failure, String>> sendMessage({
    String? conversationId,
    required String message,
  });

  /// Mark all support messages as seen / read.
  Future<Either<Failure, void>> markMessagesSeen({
    required String conversationId,
  });

  /// Get the locally cached conversation ID (from SharedPreferences).
  String? getSavedConversationId();
}
