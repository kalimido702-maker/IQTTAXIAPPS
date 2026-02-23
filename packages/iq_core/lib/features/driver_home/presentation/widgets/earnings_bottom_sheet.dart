import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Today's earnings data.
class TodayEarnings {
  const TodayEarnings({
    this.tripsCount = 0,
    this.distanceKm = 0,
    this.activeHours = 0,
    this.activeMinutes = 0,
    this.totalEarningsIQD = 0,
  });

  final int tripsCount;
  final int distanceKm;
  final int activeHours;
  final int activeMinutes;
  final int totalEarningsIQD;
}

/// Driver home bottom sheet showing today's earnings.
///
/// Figma layout:
///   1. Drag handle
///   2. Title: "أرباح اليوم"
///   3. Stats row: trips | distance | active time (separated by vertical lines)
///   4. Divider
///   5. Total earnings: "IQD 21,730"
class EarningsBottomSheet extends StatelessWidget {
  const EarningsBottomSheet({
    super.key,
    required this.earnings,
  });

  final TodayEarnings earnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Drag handle ───
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.gray1,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // ─── Title ───
          IqText(
            AppStrings.todayEarnings,
            style: AppTypography.heading2,
          ),
          SizedBox(height: 16.h),

          // ─── Divider ───
          Divider(height: 1, color: AppColors.grayDivider, indent: 24.w, endIndent: 24.w),
          SizedBox(height: 16.h),

          // ─── Stats row ───
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Trips
                  Expanded(
                    child: _StatColumn(
                      value: '${earnings.tripsCount}',
                      label: AppStrings.completedTrips,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.grayDivider,
                  ),
                  // Distance
                  Expanded(
                    child: _StatColumn(
                      value: '${earnings.distanceKm} km',
                      label: AppStrings.totalDistance,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.grayDivider,
                  ),
                  // Active time
                  Expanded(
                    child: _StatColumn(
                      value:
                          '${earnings.activeHours} hr : ${earnings.activeMinutes} min',
                      label: AppStrings.activityTime,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // ─── Divider ───
          Divider(height: 1, color: AppColors.grayDivider, indent: 24.w, endIndent: 24.w),
          SizedBox(height: 16.h),

          // ─── Total earnings ───
          IqText(
            'IQD ${_formatNumber(earnings.totalEarningsIQD)}',
            style: AppTypography.heading1.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
            dir: TextDirection.ltr,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    final str = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IqText(
          value,
          style: AppTypography.numberMedium.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          dir: TextDirection.ltr,
        ),
        SizedBox(height: 4.h),
        IqText(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray3,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
