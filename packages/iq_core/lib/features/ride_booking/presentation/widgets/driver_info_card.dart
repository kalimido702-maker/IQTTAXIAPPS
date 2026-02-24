import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';
import 'trip_rating_widget.dart';

/// Displays driver photo, name, rating, and car info.
/// Used across passenger trip screens (driver found, arrived, in progress, invoice, rating).
class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.rating = 0,
    this.carModel,
    this.carColor,
    this.plateNumber,
    this.onCall,
    this.onChat,
    this.showActions = true,
    this.compact = false,
  });

  final String name;
  final String? photoUrl;
  final double rating;
  final String? carModel;
  final String? carColor;
  final String? plateNumber;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final bool showActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 44.w : 56.w;

    return Row(
      children: [
        // Avatar
        ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? IqImage(
                    photoUrl!,
                    fit: BoxFit.cover,
                    width: avatarSize,
                    height: avatarSize,
                  )
                : Container(
                    color: AppColors.grayLightBg,
                    child: Icon(
                      Icons.person,
                      size: avatarSize * 0.6,
                      color: AppColors.grayLight,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12.w),
        // Name + rating + car
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IqText(
                name,
                style: (compact ? AppTypography.labelMedium : AppTypography.labelLarge)
                    .copyWith(color: AppColors.textDark),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  TripRatingStars(rating: rating, size: compact ? 14 : 16),
                  if (carModel != null) ...[
                    SizedBox(width: 8.w),
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: const BoxDecoration(
                        color: AppColors.grayLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: IqText(
                        carModel!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (plateNumber != null && !compact) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.grayLightBg,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: IqText(
                    plateNumber!,
                    style: AppTypography.numberSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    dir: TextDirection.ltr,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Action buttons
        if (showActions) ...[
          if (onChat != null)
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onChat!,
            ),
          if (onCall != null) ...[
            SizedBox(width: 8.w),
            _ActionButton(
              icon: Icons.phone_outlined,
              onTap: onCall!,
              color: AppColors.success,
            ),
          ],
        ],
      ],
    );
  }
}

/// Displays user photo, name, rating (for driver's view of the passenger).
class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.rating = 0,
    this.tripCount,
    this.isNewUser = false,
    this.onCall,
    this.onChat,
    this.showActions = true,
  });

  final String name;
  final String? photoUrl;
  final double rating;
  final int? tripCount;
  final bool isNewUser;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        ClipOval(
          child: SizedBox(
            width: 56.w,
            height: 56.w,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? IqImage(
                    photoUrl!,
                    fit: BoxFit.cover,
                    width: 56.w,
                    height: 56.w,
                  )
                : Container(
                    color: AppColors.grayLightBg,
                    child: Icon(
                      Icons.person,
                      size: 32.w,
                      color: AppColors.grayLight,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12.w),
        // Name + rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: IqText(
                      name,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isNewUser) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: IqText(
                        'مستخدم جديد',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  TripRatingStars(rating: rating),
                  if (tripCount != null) ...[
                    SizedBox(width: 8.w),
                    IqText(
                      '• $tripCount رحلة',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Action buttons
        if (showActions) ...[
          if (onChat != null)
            _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onChat!,
            ),
          if (onCall != null) ...[
            SizedBox(width: 8.w),
            _ActionButton(
              icon: Icons.phone_outlined,
              onTap: onCall!,
              color: AppColors.success,
            ),
          ],
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (color ?? AppColors.primary).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(
            icon,
            size: 22.w,
            color: color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
