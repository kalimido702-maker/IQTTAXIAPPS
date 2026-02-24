import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Horizontal row showing trip metrics: duration, distance, ride type.
class TripInfoRow extends StatelessWidget {
  const TripInfoRow({
    super.key,
    this.duration,
    this.distance,
    this.rideType,
  });

  final String? duration;
  final String? distance;
  final String? rideType;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[];
    if (duration != null) {
      items.add(_InfoItem(icon: Icons.access_time_rounded, value: duration!));
    }
    if (distance != null) {
      items.add(_InfoItem(icon: Icons.straighten_rounded, value: distance!));
    }
    if (rideType != null) {
      items.add(_InfoItem(icon: Icons.local_taxi_rounded, value: rideType!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.grayLightBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .expand((item) => [
                  Expanded(child: item),
                  if (item != items.last)
                    Container(
                      width: 1,
                      height: 30.h,
                      color: AppColors.grayBorder,
                    ),
                ])
            .toList(),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20.w, color: AppColors.textMuted),
        SizedBox(height: 4.h),
        IqText(
          value,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
