import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/weekly_earnings_model.dart';

/// Horizontal day-of-week selector with left/right navigation arrows.
///
/// The selected day is highlighted with a yellow circle.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedIndex,
    required this.onDaySelected,
    required this.onPrevious,
    required this.onNext,
    this.disablePrevious = false,
    this.disableNext = false,
  });

  /// Currently selected day (0 = Mon, 6 = Sun). -1 = none.
  final int selectedIndex;

  final ValueChanged<int> onDaySelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool disablePrevious;
  final bool disableNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Left arrow (previous week) ──
        GestureDetector(
          onTap: disablePrevious ? null : onPrevious,
          child: Icon(
            Icons.chevron_left,
            size: 24.w,
            color: disablePrevious
                ? AppColors.gray1
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),

        // ── Day labels ──
        ...List.generate(7, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onDaySelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46.w,
              height: 46.w,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.buttonYellow,
                      borderRadius: BorderRadius.circular(23.r),
                    )
                  : null,
              alignment: Alignment.center,
              child: IqText(
                WeeklyEarningsModel.dayLabels[i],
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: AppTypography.fontFamilyLatin,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }),

        // ── Right arrow (next week) ──
        GestureDetector(
          onTap: disableNext ? null : onNext,
          child: Icon(
            Icons.chevron_right,
            size: 24.w,
            color: disableNext
                ? AppColors.gray1
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
