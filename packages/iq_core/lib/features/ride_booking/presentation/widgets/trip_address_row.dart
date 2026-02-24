import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Displays pickup and dropoff addresses with colored dots and a connecting line.
class TripAddressRow extends StatelessWidget {
  const TripAddressRow({
    super.key,
    required this.pickAddress,
    required this.dropAddress,
    this.compact = false,
  });

  final String pickAddress;
  final String dropAddress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dotSize = compact ? 10.w : 12.w;
    final lineHeight = compact ? 20.h : 28.h;
    final fontSize = compact ? AppTypography.bodySmall : AppTypography.bodyMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dots + line
        Column(
          children: [
            SizedBox(height: 4.h),
            _Dot(color: AppColors.markerGreen, size: dotSize),
            _DottedLine(height: lineHeight),
            _Dot(color: AppColors.markerRed, size: dotSize),
          ],
        ),
        SizedBox(width: 12.w),
        // Addresses
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IqText(
                pickAddress,
                style: fontSize.copyWith(color: AppColors.textDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: lineHeight - 6.h),
              IqText(
                dropAddress,
                style: fontSize.copyWith(color: AppColors.textDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small colored circle marker.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Vertical dotted line connecting the two dots.
class _DottedLine extends StatelessWidget {
  const _DottedLine({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxHeight / 5).floor();
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              dashCount,
              (_) => Container(
                width: 2.w,
                height: 2.h,
                color: AppColors.grayLight,
              ),
            ),
          );
        },
      ),
    );
  }
}
