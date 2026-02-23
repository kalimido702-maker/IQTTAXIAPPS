part of 'support_chat_bloc.dart';

enum SupportChatStatus { initial, loading, loaded, error }

enum SupportChatSendStatus { idle, sending, sent, failed }

/// Immutable state for the support chat screen.
class SupportChatState {
  final SupportChatStatus status;
  final List<SupportMessageEntity> messages;
  final String? conversationId;
  final String? errorMessage;
  final SupportChatSendStatus sendStatus;
  final String? sendErrorMessage;

  const SupportChatState({
    this.status = SupportChatStatus.initial,
    this.messages = const [],
    this.conversationId,
    this.errorMessage,
    this.sendStatus = SupportChatSendStatus.idle,
    this.sendErrorMessage,
  });

  SupportChatState copyWith({
    SupportChatStatus? status,
    List<SupportMessageEntity>? messages,
    String? conversationId,
    String? errorMessage,
    SupportChatSendStatus? sendStatus,
    String? sendErrorMessage,
  }) {
    return SupportChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: errorMessage ?? this.errorMessage,
      sendStatus: sendStatus ?? this.sendStatus,
      sendErrorMessage: sendErrorMessage ?? this.sendErrorMessage,
    );
  }
}
