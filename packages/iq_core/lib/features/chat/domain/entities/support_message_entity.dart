import 'package:equatable/equatable.dart';

/// A single message in the admin support chat.
class SupportMessageEntity extends Equatable {
  final int id;
  final String message;
  final String senderId;
  final DateTime createdAt;

  /// `true` when this message was sent by the current user (not admin).
  final bool isMe;

  const SupportMessageEntity({
    required this.id,
    required this.message,
    required this.senderId,
    required this.createdAt,
    required this.isMe,
  });

  @override
  List<Object?> get props => [id, message, senderId, createdAt, isMe];
}
