import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'iq_text.dart';

/// Location search input matching Figma design
/// With location/search icon and rounded border
class IqLocationInput extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final TextEditingController? controller;
  final bool readOnly;

  const IqLocationInput({
    super.key,
    required this.hintText,
    this.onTap,
    this.leadingIcon,
    this.leadingIconColor,
    this.controller,
    this.readOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.grayBorder),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),
            if (leadingIcon != null)
              Icon(
                leadingIcon,
                color: leadingIconColor ?? AppColors.gray2,
                size: 20.w,
              ),
            SizedBox(width: 8.w),
            Expanded(
              child: readOnly
                  ? IqText(
                      hintText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.grayLight,
                      ),
                    )
                  : TextField(
                      controller: controller,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grayLight,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }
}
