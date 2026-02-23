import 'package:equatable/equatable.dart';

/// Events for [NotificationBloc].
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) notifications — page 1.
class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

/// Load next page of notifications.
class NotificationLoadMoreRequested extends NotificationEvent {
  const NotificationLoadMoreRequested();
}

/// Delete a single notification.
class NotificationDeleteRequested extends NotificationEvent {
  final String id;

  const NotificationDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Clear all notifications.
class NotificationClearAllRequested extends NotificationEvent {
  const NotificationClearAllRequested();
}
