import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../domain/entities/trip_chat_message_entity.dart';

/// A single chat message bubble for trip chat.
class TripChatMessageBubble extends StatelessWidget {
  const TripChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  final TripChatMessageEntity message;
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
