import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection_container.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/iq_app_bar.dart';
import '../../core/widgets/iq_text.dart';

/// A single chat message from the trip chat API.
class _TripChatMessage {
  final String id;
  final String message;

  /// 1 = passenger sent, 2 = driver sent.
  final int fromType;
  final String convertedCreatedAt;

  const _TripChatMessage({
    required this.id,
    required this.message,
    required this.fromType,
    required this.convertedCreatedAt,
  });

  factory _TripChatMessage.fromJson(Map<String, dynamic> json) {
    return _TripChatMessage(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      fromType: (json['from_type'] as num?)?.toInt() ?? 1,
      convertedCreatedAt: json['converted_created_at']?.toString() ?? '',
    );
  }
}

/// Real-time trip chat page between passenger and driver.
///
/// Uses:
/// - GET  `api/v1/request/chat-history/{requestId}` – load history
/// - POST `api/v1/request/send`  body: {request_id, message}
/// - POST `api/v1/request/seen`  body: {request_id}
///
/// [myFromType]: 1 if the current user is the passenger, 2 if the driver.
class TripChatPage extends StatefulWidget {
  const TripChatPage({
    super.key,
    required this.requestId,
    required this.otherPartyName,
    required this.myFromType,
    this.otherPartyPhotoUrl,
  });

  final String requestId;
  final String otherPartyName;

  /// 1 = passenger is "me", 2 = driver is "me".
  final int myFromType;
  final String? otherPartyPhotoUrl;

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_TripChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Poll every 5 seconds for new messages.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadHistory(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool silent = false}) async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get(
        'api/v1/request/chat-history/${widget.requestId}',
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        final rawList = body['data'];
        if (rawList is List) {
          final parsed = rawList
              .whereType<Map<String, dynamic>>()
              .map(_TripChatMessage.fromJson)
              .toList();
          if (!mounted) return;
          setState(() {
            _messages
              ..clear()
              ..addAll(parsed);
            if (!silent) _isLoading = false;
          });
          _scrollToBottom();
          _markSeen();
        }
      } else {
        if (!silent && mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markSeen() async {
    try {
      final dio = sl<Dio>();
      await dio.post(
        'api/v1/request/seen',
        data: {'request_id': widget.requestId},
      );
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final dio = sl<Dio>();
      await dio.post(
        'api/v1/request/send',
        data: {
          'request_id': widget.requestId,
          'message': text,
        },
      );
      await _loadHistory(silent: true);
    } catch (_) {
      // Restore the text if sending fails.
      if (mounted) _messageController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayLightBg,
      appBar: IqAppBar(title: widget.otherPartyName),
      body: Column(
        children: [
          // ── Message list ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
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
                        itemCount: _messages.length,
                        itemBuilder: (_, index) =>
                            _MessageBubble(
                              message: _messages[index],
                              isMe:
                                  _messages[index].fromType ==
                                  widget.myFromType,
                            ),
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _isSending
                      ? SizedBox(
                          width: 44.w,
                          height: 44.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : InkWell(
                          onTap: _sendMessage,
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
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  final _TripChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.primary
                  : (isDark ? AppColors.darkCard : AppColors.white),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: isMe
                    ? Radius.circular(16.r)
                    : const Radius.circular(0),
                bottomRight: isMe
                    ? const Radius.circular(0)
                    : Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IqText(
              message.message,
              style: AppTypography.bodyMedium.copyWith(
                color: isMe
                    ? AppColors.black
                    : (isDark ? AppColors.white : AppColors.textDark),
              ),
            ),
          ),
          if (message.convertedCreatedAt.isNotEmpty) ...[
            SizedBox(height: 4.h),
            IqText(
              message.convertedCreatedAt,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
