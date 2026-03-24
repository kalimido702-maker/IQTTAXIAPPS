import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Referral code display card with a copy icon.
///
/// Shows the referral code in a shadowed container.
class ReferralCodeCard extends StatelessWidget {
  const ReferralCodeCard({
    super.key,
    required this.code,
    required this.onCopy,
  });

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onCopy(); },
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.copy_rounded,
              size: 24.w,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 10.w),
            IqText(
              code,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTypography.fontFamilyLatin,
              ),
              dir: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}
