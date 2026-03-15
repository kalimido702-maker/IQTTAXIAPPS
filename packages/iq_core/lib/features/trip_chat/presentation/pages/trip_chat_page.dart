import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/trip_chat_bloc.dart';
import '../widgets/trip_chat_message_bubble.dart';

/// Real-time trip chat page between passenger and driver.
///
/// Expects a [TripChatBloc] to be provided via [BlocProvider] above this page.
class TripChatPage extends StatefulWidget {
  const TripChatPage({
    super.key,
    required this.otherPartyName,
    this.otherPartyPhotoUrl,
  });

  final String otherPartyName;
  final String? otherPartyPhotoUrl;

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TripChatBloc>();
    bloc.add(const TripChatLoadRequested());
    bloc.add(const TripChatStartPolling());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _messageController.clear();
    context.read<TripChatBloc>().add(TripChatSendMessage(message: text));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayLightBg,
      appBar: IqAppBar(title: widget.otherPartyName),
      body: BlocConsumer<TripChatBloc, TripChatState>(
        listener: (context, state) {
          if (state.status == TripChatStatus.loaded) {
            _scrollToBottom();
          }
          if (state.sendStatus == TripChatSendStatus.sent) {
            _scrollToBottom();
          }
          if (state.sendStatus == TripChatSendStatus.failed &&
              state.sendErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.sendErrorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // ── Message list ──
              Expanded(
                child: state.status == TripChatStatus.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : state.messages.isEmpty
                        ? Center(
                            child: IqText(
                              AppStrings.noMessagesYet,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (_, index) {
                              final msg = state.messages[index];
                              return TripChatMessageBubble(
                                message: msg,
                                isMe: msg.fromType ==
                                    context
                                        .read<TripChatBloc>()
                                        .myFromType,
                              );
                            },
                          ),
              ),

              // ── Input bar ──
              Container(
                color: isDark ? AppColors.darkCard : AppColors.white,
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: AppTypography.bodyMedium,
                          textDirection: TextDirection.rtl,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: AppStrings.typeMessage,
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grayPlaceholder,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkInputBg
                                : AppColors.grayLightBg,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _onSend(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      state.sendStatus == TripChatSendStatus.sending
                          ? SizedBox(
                              width: 44.w,
                              height: 44.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : InkWell(
                              onTap: _onSend,
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send_rounded,
                                  size: 20.w,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
