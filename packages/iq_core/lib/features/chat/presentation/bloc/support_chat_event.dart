part of 'support_chat_bloc.dart';

/// Base class for support chat events.
sealed class SupportChatEvent {
  const SupportChatEvent();
}

/// Load initial chat history.
final class SupportChatLoadRequested extends SupportChatEvent {
  const SupportChatLoadRequested();
}

/// Send a text message.
final class SupportChatSendMessage extends SupportChatEvent {
  final String message;
  const SupportChatSendMessage({required this.message});
}

/// Mark all messages as seen.
final class SupportChatMarkSeen extends SupportChatEvent {
  const SupportChatMarkSeen();
}

/// Refresh chat history (pull-to-refresh).
final class SupportChatRefreshRequested extends SupportChatEvent {
  const SupportChatRefreshRequested();
}
