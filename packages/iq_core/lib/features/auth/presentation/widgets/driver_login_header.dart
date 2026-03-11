import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';

/// Driver login header — logo + benefits card.
///
/// Matches Figma node 7:5208 (Driver login screen).
class DriverLoginHeader extends StatelessWidget {
  const DriverLoginHeader({super.key});

  static final _benefits = [
    AppStrings.benefit1,
    AppStrings.benefit2,
    AppStrings.benefit3,
    AppStrings.benefit4,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Logo ──
        IqImage(
          AppAssets.iqTaxiLogo,
          width: 100.w,
          height: 115.h,
        ),

        SizedBox(height: 20.h),

        // ── Benefits card ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
          child: Column(
            children: [
              // Title
              IqText(
                AppStrings.joinBenefits,
                style: AppTypography.heading3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),

              // Benefit items
              ...List.generate(_benefits.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index < _benefits.length - 1 ? 8.h : 0),
                  child: Container(
                    width: 312.w,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.inputBorder),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: IqText(
                      _benefits[index],
                      style: AppTypography.bodyLarge.copyWith(height: 1.7),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),

              SizedBox(height: 20.h),

              // Tagline
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: IqText(
                  AppStrings.youAreTheLeader,
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
