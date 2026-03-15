import '../../domain/entities/trip_chat_message_entity.dart';

/// Data model for a trip chat message.
///
/// Extends [TripChatMessageEntity] with JSON parsing capabilities.
class TripChatMessageModel extends TripChatMessageEntity {
  const TripChatMessageModel({
    required super.id,
    required super.message,
    required super.fromType,
    required super.convertedCreatedAt,
  });

  /// Parse from API response item in chat history `data[]`.
  factory TripChatMessageModel.fromJson(Map<String, dynamic> json) {
    return TripChatMessageModel(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      fromType: (json['from_type'] as num?)?.toInt() ?? 1,
      convertedCreatedAt: json['converted_created_at']?.toString() ?? '',
    );
  }
}
