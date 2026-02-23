import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/constants/app_strings.dart';

/// Online / Offline toggle badge for the driver home page.
///
/// Design: pill-shaped switch.
/// ✅ Online  → green bg, white circle on the RIGHT, "متصل ✓" text on the LEFT.
/// ❌ Offline → red bg,   white circle on the LEFT,  "غير متصل ✕" text on the RIGHT.
class DriverStatusBadge extends StatelessWidget {
  const DriverStatusBadge({
    super.key,
    required this.isOnline,
    required this.onToggle,
    this.isLoading = false,
  });

  final bool isOnline;
  final VoidCallback onToggle;
  final bool isLoading;

  static const _onlineColor = AppColors.driverOnline;
  static const _offlineColor = AppColors.driverOffline;
  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final bgColor = isOnline ? _onlineColor : _offlineColor;
    final circleSize = 34.w;
    final badgeHeight = 44.h;
    final badgeWidth = 145.w;

    return GestureDetector(
      onTap: isLoading ? null : onToggle,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeInOut,
        height: badgeHeight,
        width: badgeWidth,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(badgeHeight / 2),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Sliding white circle ──
            AnimatedPositionedDirectional(
              duration: _duration,
              curve: Curves.easeInOut,
              top: (badgeHeight - circleSize) / 2,
              // Online → end side (right in RTL), Offline → start side (left in RTL)
              start: isOnline ? badgeWidth - circleSize - 5.w : 5.w,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(8.w),
                        child: CircularProgressIndicator(
                          color: bgColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : null,
              ),
            ),

            // ── Text + icon ──
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: _duration,
                child: isOnline
                    ? _OnlineLabel(key: const ValueKey('online'))
                    : _OfflineLabel(key: const ValueKey('offline')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label shown when online: "✓ متصل" aligned to the start (left in RTL).
class _OnlineLabel extends StatelessWidget {
  const _OnlineLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 12.w, end: 42.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: AppColors.white, size: 18.w),
          SizedBox(width: 4.w),
          IqText(
            AppStrings.connected,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label shown when offline: "✕ غير متصل" aligned to the end (right in RTL).
class _OfflineLabel extends StatelessWidget {
  const _OfflineLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 42.w, end: 12.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.close, color: AppColors.white, size: 18.w),
          SizedBox(width: 4.w),
          Flexible(
            child: IqText(
              AppStrings.disconnected,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
