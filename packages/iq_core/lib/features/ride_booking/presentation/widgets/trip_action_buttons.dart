import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Bottom action bar with locate, share, and SOS buttons.
/// Used in the active trip in-progress screen.
class TripActionButtons extends StatelessWidget {
  const TripActionButtons({
    super.key,
    this.onLocate,
    this.onShareTrip,
    this.onSos,
  });

  final VoidCallback? onLocate;
  final VoidCallback? onShareTrip;
  final VoidCallback? onSos;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionItem(
          icon: Icons.my_location_rounded,
          label: AppStrings.locatePosition,
          onTap: onLocate,
        ),
        _ActionItem(
          icon: Icons.share_rounded,
          label: AppStrings.shareTrip,
          onTap: onShareTrip,
        ),
        _ActionItem(
          icon: Icons.sos_rounded,
          label: 'SOS',
          onTap: onSos,
          isEmergency: true,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isEmergency ? AppColors.error.withValues(alpha: 0.1) : AppColors.grayLightBg;
    final iconColor = isEmergency ? AppColors.error : AppColors.textDark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.w),
          ),
          SizedBox(height: 4.h),
          IqText(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
