part of 'trip_chat_bloc.dart';

enum TripChatStatus { initial, loading, loaded, error }

enum TripChatSendStatus { idle, sending, sent, failed }

/// Immutable state for the trip chat screen.
class TripChatState {
  final TripChatStatus status;
  final List<TripChatMessageEntity> messages;
  final String? errorMessage;
  final TripChatSendStatus sendStatus;
  final String? sendErrorMessage;

  const TripChatState({
    this.status = TripChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.sendStatus = TripChatSendStatus.idle,
    this.sendErrorMessage,
  });

  TripChatState copyWith({
    TripChatStatus? status,
    List<TripChatMessageEntity>? messages,
    String? errorMessage,
    TripChatSendStatus? sendStatus,
    String? sendErrorMessage,
  }) {
    return TripChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      sendStatus: sendStatus ?? this.sendStatus,
      sendErrorMessage: sendErrorMessage ?? this.sendErrorMessage,
    );
  }
}
