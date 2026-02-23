import '../../domain/entities/support_message_entity.dart';

/// Model for a single admin support chat message.
class SupportMessageModel extends SupportMessageEntity {
  const SupportMessageModel({
    required super.id,
    required super.message,
    required super.senderId,
    required super.createdAt,
    required super.isMe,
  });

  /// Parse from API response item in `data.conversation[]`.
  ///
  /// Backend fields: id (UUID), content, sender_id, sender_type, created_at.
  factory SupportMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    // Backend uses `sender_id` for sender identification
    final senderId = (json['sender_id'] ?? json['from_id'] ?? '').toString();

    return SupportMessageModel(
      id: (json['id'] ?? '').toString().hashCode,
      message: (json['content'] ?? json['message'] ?? '').toString(),
      senderId: senderId,
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      isMe: senderId == currentUserId,
    );
  }
}

/// Parsed response from `GET api/v1/request/user-chat-history`.
///
/// Backend response structure:
/// ```json
/// {
///   "success": true,
///   "data": {
///     "conversation": [
///       {
///         "id": "uuid",
///         "conversation_id": "uuid",
///         "sender_id": "218",
///         "sender_type": "user",
///         "content": "مرحبا",
///         "created_at": "2026-02-22T23:00:27.000000Z"
///       }
///     ],
///     "new_chat": 0,
///     "conversation_id": "uuid",
///     "count": 0
///   }
/// }
/// ```
class SupportChatHistoryResponse {
  final List<SupportMessageModel> messages;
  final String? conversationId;
  final bool isNewChat;

  const SupportChatHistoryResponse({
    required this.messages,
    this.conversationId,
    this.isNewChat = false,
  });

  factory SupportChatHistoryResponse.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    // Safely extract data — might be Map, String, or null
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    // Backend: data.conversation (array of messages)
    final rawList = data['conversation'] ?? data['conversations'];
    final chatsList = rawList is List ? rawList : <dynamic>[];

    // Backend: data.conversation_id (chat identifier)
    final chatId =
        (data['conversation_id'] ?? data['chat_id'])?.toString();

    // Backend: data.new_chat (1 = new, 0 = existing)
    final newChatFlag = data['new_chat'];
    final isNew = newChatFlag == 1 ||
        newChatFlag == true ||
        chatsList.isEmpty;

    final messages = chatsList
        .whereType<Map<String, dynamic>>()
        .map((e) => SupportMessageModel.fromJson(
              e,
              currentUserId: currentUserId,
            ))
        .toList();

    // Sort oldest → newest for chat display
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return SupportChatHistoryResponse(
      messages: messages,
      conversationId: chatId,
      isNewChat: isNew,
    );
  }
}
