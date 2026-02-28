import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';

/// Card for selecting a vehicle type in the ride selection page.
///
/// Figma: 65h, padding h:22 v:11, white bg, border 0xFFF4F5F6, radius 16.
/// Layout (RTL): [Radio 24] — [price+currency] — [name+capacity] — [vehicle 80w]
class VehicleTypeCard extends StatelessWidget {
  const VehicleTypeCard({
    super.key,
    required this.name,
    required this.icon,
    required this.price,
    required this.capacity,
    required this.isSelected,
    required this.onTap,
    this.currency,
    this.description,
  });

  final String name;
  final String icon;
  final String price;
  final int capacity;
  final bool isSelected;
  final VoidCallback onTap;
  final String? currency;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minHeight: 65.h),
        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkDivider : AppColors.inputFill),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Vehicle icon
            SizedBox(
              width: 80.w,
              height: 33.h,
              child: IqImage(icon, fit: BoxFit.contain),
            ),
            SizedBox(width: 14.w),
            // Name + capacity
            SizedBox(
              width: 110.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IqText(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.white : AppColors.black,
                      fontWeight: FontWeight.w700,
                      height: 1.13,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 1.h),
                  IqText(
                    '$capacity ${AppStrings.persons}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grayCapacity,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Price + currency
            IqText(
              '$price ${currency ?? AppStrings.currencyIQD}',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 21.w),
            // Radio indicator
            _RadioDot(selected: isSelected, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.isDark});

  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.white : AppColors.black;

    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor,
                ),
              ),
            )
          : null,
    );
  }
}
