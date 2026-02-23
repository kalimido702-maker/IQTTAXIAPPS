import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// A single quick-place row in the home bottom sheet.
///
/// Figma: location pin icon + place name + trailing chevron,
/// separated by thin dividers.
class QuickPlaceTile extends StatelessWidget {
  const QuickPlaceTile({
    super.key,
    required this.name,
    this.onTap,
  });

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            // Star / favorite icon
            Icon(
              Icons.star_border_rounded,
              color: AppColors.gray2,
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            // Place name
            Expanded(
              child: IqText(
                name,
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 17.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Location pin
            Icon(
              Icons.location_on,
              color: AppColors.error,
              size: 22.w,
            ),
          ],
        ),
      ),
    );
  }
}
