import 'package:equatable/equatable.dart';

/// Chat message entity
class ChatMessageEntity extends Equatable {
  final String id;
  final String tripId;
  final String senderId;
  final String message;
  final String type; // text, image, location
  final DateTime createdAt;
  final bool isRead;

  const ChatMessageEntity({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.message,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id, tripId];
}
