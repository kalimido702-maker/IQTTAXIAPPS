import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/notification_model.dart';

/// A single notification card matching the Figma design.
///
/// Shows notification icon, title, body, date, and a delete (×) button.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        // ── Content ──
            // ── Notification icon circle ──
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grayLightBg,
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 24.w,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      IqText(
                        notification.title,
                        style: AppTypography.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Spacer(),
                      // Date
                      IqText(
                        notification.createdAt,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grayDate,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  // Body
                  IqText(
                    notification.body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),      

            SizedBox(width: 10.w),
            // ── Delete (×) button ──
            GestureDetector(
              onTap: onDelete == null ? null : () { HapticFeedback.mediumImpact(); onDelete!(); },
              child: Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Icon(
                  Icons.close,
                  size: 30.w,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
