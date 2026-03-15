import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_chat_message_entity.dart';
import '../../domain/repositories/trip_chat_repository.dart';

part 'trip_chat_event.dart';
part 'trip_chat_state.dart';

/// BLoC managing trip chat state (passenger ↔ driver messaging).
class TripChatBloc extends Bloc<TripChatEvent, TripChatState> {
  final TripChatRepository repository;
  final String requestId;
  final int myFromType;

  Timer? _pollTimer;

  TripChatBloc({
    required this.repository,
    required this.requestId,
    required this.myFromType,
  }) : super(const TripChatState()) {
    on<TripChatLoadRequested>(_onLoadRequested);
    on<TripChatSendMessage>(_onSendMessage);
    on<TripChatRefreshRequested>(_onRefreshRequested);
    on<TripChatMarkSeen>(_onMarkSeen);
    on<TripChatStartPolling>(_onStartPolling);
    on<TripChatStopPolling>(_onStopPolling);
  }

  Future<void> _onLoadRequested(
    TripChatLoadRequested event,
    Emitter<TripChatState> emit,
  ) async {
    emit(state.copyWith(status: TripChatStatus.loading));

    final result = await repository.getChatHistory(requestId: requestId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TripChatStatus.error,
        errorMessage: failure.message,
      )),
      (messages) {
        emit(state.copyWith(
          status: TripChatStatus.loaded,
          messages: messages,
        ));
        // Mark messages as seen after loading
        add(const TripChatMarkSeen());
      },
    );
  }

  Future<void> _onSendMessage(
    TripChatSendMessage event,
    Emitter<TripChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    emit(state.copyWith(sendStatus: TripChatSendStatus.sending));

    final result = await repository.sendMessage(
      requestId: requestId,
      message: event.message.trim(),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        sendStatus: TripChatSendStatus.failed,
        sendErrorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(sendStatus: TripChatSendStatus.sent));
        // Reset send status back to idle
        emit(state.copyWith(sendStatus: TripChatSendStatus.idle));
        // Refresh messages after sending
        add(const TripChatRefreshRequested());
      },
    );
  }

  Future<void> _onRefreshRequested(
    TripChatRefreshRequested event,
    Emitter<TripChatState> emit,
  ) async {
    final result = await repository.getChatHistory(requestId: requestId);

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (messages) {
        emit(state.copyWith(
          status: TripChatStatus.loaded,
          messages: messages,
        ));
        add(const TripChatMarkSeen());
      },
    );
  }

  Future<void> _onMarkSeen(
    TripChatMarkSeen event,
    Emitter<TripChatState> emit,
  ) async {
    await repository.markSeen(requestId: requestId);
  }

  void _onStartPolling(
    TripChatStartPolling event,
    Emitter<TripChatState> emit,
  ) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(const TripChatRefreshRequested());
    });
  }

  void _onStopPolling(
    TripChatStopPolling event,
    Emitter<TripChatState> emit,
  ) {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
