import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// A single detail row in the report showing label and value.
///
/// When [isTotal] is true, text is bold to indicate the total line.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface)
        : AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IqText(label, style: style),
          IqText(
            value,
            style: style.copyWith(fontFamily: AppTypography.fontFamilyLatin),
            dir: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
