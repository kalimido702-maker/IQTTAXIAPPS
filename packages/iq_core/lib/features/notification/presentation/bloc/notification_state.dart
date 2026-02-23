import 'package:equatable/equatable.dart';

import '../../data/models/notification_model.dart';

/// States for [NotificationBloc].
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load.
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading notifications (first page).
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// Notifications loaded successfully.
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;
  final bool isLoadingMore;

  const NotificationLoaded({
    required this.notifications,
    required this.pagination,
    this.isLoadingMore = false,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    NotificationPagination? pagination,
    bool? isLoadingMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      pagination: pagination ?? this.pagination,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notifications, pagination, isLoadingMore];
}

/// Error fetching notifications.
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
