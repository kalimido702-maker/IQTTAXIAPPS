import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';

/// Card for selecting a vehicle type in the ride selection page.
class VehicleTypeCard extends StatelessWidget {
  const VehicleTypeCard({
    super.key,
    required this.name,
    required this.icon,
    required this.price,
    required this.capacity,
    required this.isSelected,
    required this.onTap,
    this.currency = 'د.ع',
    this.description,
  });

  final String name;
  final String icon;
  final String price;
  final int capacity;
  final bool isSelected;
  final VoidCallback onTap;
  final String currency;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary50 : AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grayBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Vehicle icon
            SizedBox(
              width: 60.w,
              height: 40.h,
              child: IqImage(icon, fit: BoxFit.contain),
            ),
            SizedBox(width: 12.w),
            // Name + capacity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IqText(
                    name,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14.w,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 2.w),
                      IqText(
                        '$capacity',
                        style: AppTypography.caption,
                        dir: TextDirection.ltr,
                      ),
                      if (description != null) ...[
                        SizedBox(width: 8.w),
                        Expanded(
                          child: IqText(
                            description!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IqText(
                  price,
                  style: AppTypography.numberLarge.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                  dir: TextDirection.ltr,
                ),
                IqText(
                  currency,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
