import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/support_message_entity.dart';
import '../bloc/support_chat_bloc.dart';

/// Admin support chat page — matches Figma node 7:1660.
///
/// Layout:
/// - AppBar with admin avatar, "دردشة المسؤول", "Active now"
/// - Message list (admin = black bubble left, user = white bubble right)
/// - Bottom input bar with text field, mic icon, yellow send button
class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

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

    context
        .read<SupportChatBloc>()
        .add(SupportChatSendMessage(message: text));
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocConsumer<SupportChatBloc, SupportChatState>(
                listener: (context, state) {
                  if (state.sendStatus == SupportChatSendStatus.sent) {
                    _scrollToBottom();
                  }
                  if (state.sendStatus == SupportChatSendStatus.failed &&
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
                      Expanded(child: _buildMessageList(state)),
                      _buildInputBar(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom header matching Figma: avatar+title on RIGHT, back arrow on LEFT.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.chatShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // In RTL: children[0] → RIGHT side
          // Admin avatar (46px)
          Container(
            width: 46.w,
            height: 46.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grayLightBg,
            ),
            child: ClipOval(
              child: Icon(
                Icons.person,
                color: AppColors.grayLight,
                size: 30.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.adminChat,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Almarai',
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                AppStrings.activeNow,
                style: TextStyle(
                  color: AppColors.chatSubtitle,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const Spacer(),
          // Back arrow — in RTL last child → LEFT side
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.black,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(SupportChatState state) {
    if (state.status == SupportChatStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == SupportChatStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 12.h),
            Text(
              state.errorMessage ?? AppStrings.somethingWrong,
              style: TextStyle(
                color: AppColors.textSubtitle,
                fontSize: 14.sp,
                fontFamily: 'Almarai',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => context
                  .read<SupportChatBloc>()
                  .add(const SupportChatLoadRequested()),
              child: Text(
                AppStrings.retry,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Almarai',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56.sp,
              color: AppColors.grayLight,
            ),
            SizedBox(height: 12.h),
            Text(
              AppStrings.noMessagesYet,
              style: TextStyle(
                color: AppColors.textSubtitle,
                fontSize: 14.sp,
                fontFamily: 'Almarai',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              AppStrings.startConversation,
              style: TextStyle(
                color: AppColors.grayLight,
                fontSize: 12.sp,
                fontFamily: 'Almarai',
              ),
            ),
          ],
        ),
      );
    }

    // LTR wrapper so admin bubbles align LEFT, user bubbles align RIGHT
    // (universal chat convention regardless of app text direction).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final msg = state.messages[index];
          final showDateHeader =
              _shouldShowDateHeader(state.messages, index);
          final isFollowUp = !showDateHeader &&
              index > 0 &&
              state.messages[index - 1].isMe == msg.isMe;

          return Column(
            children: [
              if (showDateHeader) _buildDateHeader(msg.createdAt),
              _MessageBubble(message: msg, isFollowUp: isFollowUp),
            ],
          );
        },
      ),
    );
  }

  /// Show date header when the date changes between messages.
  bool _shouldShowDateHeader(
      List<SupportMessageEntity> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final label = isToday
        ? AppStrings.today
        : DateFormat('dd/MM/yyyy').format(date);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20.sp,
            fontFamily: 'Almarai',
            fontWeight: FontWeight.w400,
            height: 1.30,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      child: Container(
        height: 55.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.chatShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text field (start in RTL = right side)
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: 'Almarai',
                  color: AppColors.black,
                ),
                decoration: InputDecoration(
                  fillColor: AppColors.transparent,
                  hintText: AppStrings.sendYourMessage,
                  hintStyle: TextStyle(
                    color: AppColors.chatInputHint,
                    fontSize: 16.sp,
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Icon(
                      Icons.mic_none_rounded,
                      color: AppColors.chatInputHint,
                      size: 24.sp,
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 24.w,
                    minHeight: 24.w,
                  ),
                ),
                onSubmitted: (_) => _onSend(),
              ),
            ),
            // Send button (end in RTL = left side)
            Padding(
              padding: EdgeInsets.all(6.w),
              child: GestureDetector(
                onTap: _onSend,
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.buttonYellow,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Icon(
                    Icons.send,
                    color: AppColors.black,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble Widget ──────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final SupportMessageEntity message;
  final bool isFollowUp;

  const _MessageBubble({
    required this.message,
    this.isFollowUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 12px between same-sender messages, 30px between different senders.
      padding: EdgeInsets.only(top: isFollowUp ? 12.h : 30.h),
      child: message.isMe ? _buildUserBubble() : _buildAdminBubble(),
    );
  }

  /// Admin message: black bubble, LEFT-aligned (LTR context).
  /// Sharp bottom-left corner (tail pointing left toward sender).
  Widget _buildAdminBubble() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 250.w),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                      bottomRight: Radius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15.sp,
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: AppColors.chatTimestamp,
                  fontSize: 10.sp,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// User message: white bubble, RIGHT-aligned (LTR context) with avatar.
  /// Sharp bottom-right corner (tail pointing right toward avatar).
  Widget _buildUserBubble() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bubble content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 250.w),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                      bottomLeft: Radius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    message.message,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15.sp,
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: AppColors.chatTimestamp,
                  fontSize: 10.sp,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.40,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // User avatar (44px)
        Container(
          width: 44.w,
          height: 44.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grayLightBg,
          ),
          child: ClipOval(
            child: Icon(
              Icons.person,
              color: AppColors.grayLight,
              size: 24.sp,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}
