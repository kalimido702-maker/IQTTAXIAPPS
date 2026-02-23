import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Black card displaying total earnings amount.
///
/// Matches the Figma design: black rounded card with white text,
/// title on top and large amount below.
class TotalEarningsCard extends StatelessWidget {
  const TotalEarningsCard({
    super.key,
    required this.totalEarnings,
    required this.currencySymbol,
    required this.title,
  });

  final double totalEarnings;
  final String currencySymbol;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          IqText(
            title,
            style: AppTypography.heading3.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15.h),
          IqText(
            '$currencySymbol ${NumberFormat('#,###').format(totalEarnings.toInt())}',
            style: AppTypography.heading1.copyWith(
              fontSize: 35.sp,
              color: Colors.white,
              fontFamily: AppTypography.fontFamilyLatin,
            ),
            dir: TextDirection.ltr,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
