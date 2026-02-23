import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/weekly_earnings_model.dart';

/// Simple vertical bar chart showing daily earnings.
///
/// The selected day's bar is yellow, others are gray.
/// Bar heights are proportional to the maximum earning of the week.
class EarningsBarChart extends StatelessWidget {
  const EarningsBarChart({
    super.key,
    required this.earnings,
    required this.selectedDayIndex,
    this.onBarTap,
  });

  final WeeklyEarningsModel earnings;
  final int selectedDayIndex;
  final ValueChanged<int>? onBarTap;

  static const double _maxBarHeight = 120;

  @override
  Widget build(BuildContext context) {
    final maxVal = earnings.maxDailyEarning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final dayEarning = earnings.earningsForDay(i);
        final isSelected = i == selectedDayIndex;
        final barHeight = maxVal > 0
            ? (dayEarning / maxVal * _maxBarHeight).clamp(8.0, _maxBarHeight)
            : 8.0;

        return GestureDetector(
          onTap: () => onBarTap?.call(i),
          child: SizedBox(
            width: 31.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 19.w,
                  height: barHeight.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.buttonYellow
                        : const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                IqText(
                  WeeklyEarningsModel.dayLabels[i],
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: AppTypography.fontFamilyLatin,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
