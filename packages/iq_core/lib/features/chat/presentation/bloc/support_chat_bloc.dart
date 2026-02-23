import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/support_message_entity.dart';
import '../../domain/repositories/support_chat_repository.dart';

part 'support_chat_event.dart';
part 'support_chat_state.dart';

/// BLoC managing admin support chat state.
class SupportChatBloc extends Bloc<SupportChatEvent, SupportChatState> {
  final SupportChatRepository repository;
  final String currentUserId;
  final String? initialConversationId;

  SupportChatBloc({
    required this.repository,
    required this.currentUserId,
    this.initialConversationId,
  }) : super(SupportChatState(conversationId: initialConversationId)) {
    on<SupportChatLoadRequested>(_onLoadRequested);
    on<SupportChatSendMessage>(_onSendMessage);
    on<SupportChatMarkSeen>(_onMarkSeen);
    on<SupportChatRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(
    SupportChatLoadRequested event,
    Emitter<SupportChatState> emit,
  ) async {
    emit(state.copyWith(status: SupportChatStatus.loading));

    // Backend's admin-chat-history uses auth token — no chat_id needed.
    // It returns new_chat=1 (empty) or new_chat=0 with messages+chat_id.
    final result = await repository.getChatHistory(
      conversationId: state.conversationId ?? '',
      currentUserId: currentUserId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: SupportChatStatus.error,
        errorMessage: failure.message,
      )),
      (historyResult) => emit(state.copyWith(
        status: SupportChatStatus.loaded,
        messages: historyResult.messages,
        conversationId: historyResult.chatId ?? state.conversationId,
      )),
    );
  }

  Future<void> _onSendMessage(
    SupportChatSendMessage event,
    Emitter<SupportChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    emit(state.copyWith(sendStatus: SupportChatSendStatus.sending));

    final result = await repository.sendMessage(
      conversationId: state.conversationId,
      message: event.message.trim(),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        sendStatus: SupportChatSendStatus.failed,
        sendErrorMessage: failure.message,
      )),
      (conversationId) {
        // Optimistically add the message to the list
        final newMessage = SupportMessageEntity(
          id: DateTime.now().millisecondsSinceEpoch,
          message: event.message.trim(),
          senderId: currentUserId,
          createdAt: DateTime.now(),
          isMe: true,
        );

        emit(state.copyWith(
          sendStatus: SupportChatSendStatus.sent,
          conversationId: conversationId,
          messages: [...state.messages, newMessage],
        ));

        // Reset send status back to idle
        emit(state.copyWith(sendStatus: SupportChatSendStatus.idle));
      },
    );
  }

  Future<void> _onMarkSeen(
    SupportChatMarkSeen event,
    Emitter<SupportChatState> emit,
  ) async {
    final convId = state.conversationId;
    if (convId == null || convId.isEmpty) return;

    await repository.markMessagesSeen(conversationId: convId);
  }

  Future<void> _onRefreshRequested(
    SupportChatRefreshRequested event,
    Emitter<SupportChatState> emit,
  ) async {
    final result = await repository.getChatHistory(
      conversationId: state.conversationId ?? '',
      currentUserId: currentUserId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (historyResult) => emit(state.copyWith(
        status: SupportChatStatus.loaded,
        messages: historyResult.messages,
        conversationId: historyResult.chatId ?? state.conversationId,
      )),
    );
  }
}
