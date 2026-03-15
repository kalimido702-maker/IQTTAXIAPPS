part of 'trip_chat_bloc.dart';

/// Base class for trip chat events.
sealed class TripChatEvent {
  const TripChatEvent();
}

/// Load initial chat history.
final class TripChatLoadRequested extends TripChatEvent {
  const TripChatLoadRequested();
}

/// Send a text message.
final class TripChatSendMessage extends TripChatEvent {
  final String message;
  const TripChatSendMessage({required this.message});
}

/// Refresh chat history (poll or pull-to-refresh).
final class TripChatRefreshRequested extends TripChatEvent {
  const TripChatRefreshRequested();
}

/// Mark all messages as seen.
final class TripChatMarkSeen extends TripChatEvent {
  const TripChatMarkSeen();
}

/// Start polling for new messages.
final class TripChatStartPolling extends TripChatEvent {
  const TripChatStartPolling();
}

/// Stop polling for new messages.
final class TripChatStopPolling extends TripChatEvent {
  const TripChatStopPolling();
}
