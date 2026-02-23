import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// BLoC for the Notifications feature.
///
/// Handles loading, pagination, single delete, and clear-all.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoad);
    on<NotificationLoadMoreRequested>(_onLoadMore);
    on<NotificationDeleteRequested>(_onDelete);
    on<NotificationClearAllRequested>(_onClearAll);
  }

  Future<void> _onLoad(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());

    final result = await _repository.getNotifications(page: 1);

    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (data) => emit(NotificationLoaded(
        notifications: data.$1,
        pagination: data.$2,
      )),
    );
  }

  Future<void> _onLoadMore(
    NotificationLoadMoreRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    if (!currentState.pagination.hasMorePages) return;
    if (currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.pagination.currentPage + 1;
    final result = await _repository.getNotifications(page: nextPage);

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (data) => emit(NotificationLoaded(
        notifications: [...currentState.notifications, ...data.$1],
        pagination: data.$2,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onDelete(
    NotificationDeleteRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final result = await _repository.deleteNotification(event.id);

    result.fold(
      (_) => null, // Silently fail, keep list unchanged.
      (_) {
        final updated = currentState.notifications
            .where((n) => n.id != event.id)
            .toList();
        emit(currentState.copyWith(notifications: updated));
      },
    );
  }

  Future<void> _onClearAll(
    NotificationClearAllRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final result = await _repository.clearAllNotifications();

    result.fold(
      (_) => null,
      (_) => emit(currentState.copyWith(
        notifications: [],
        pagination: const NotificationPagination(),
      )),
    );
  }
}
