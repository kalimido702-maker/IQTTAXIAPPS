import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../domain/entities/trip_entity.dart';

/// A card representing a single trip in the history list.
///
/// Matches the Figma design: status badge, vehicle type, addresses,
/// divider, date + total row.
class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({
    super.key,
    required this.trip,
    this.onTap,
  });

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  final TripEntity trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.07),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Vehicle type + Status badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _VehicleTypeLabel(trip: trip),
                _StatusBadge(status: trip.status),
              ],
            ),
            SizedBox(height: 12.h),

            // ── Pickup address pill ──
            _AddressPill(
              address: trip.pickupAddress,
              markerColor: AppColors.markerRed,
            ),
            SizedBox(height: 8.h),

            // ── Dropoff address pill ──
            _AddressPill(
              address: trip.dropoffAddress,
              markerColor: AppColors.markerGreen,
            ),
            SizedBox(height: 12.h),

            // ── Divider ──
            Divider(
              height: 1,
              color: isDark ? AppColors.white.withValues(alpha: 0.12) : AppColors.grayBorder,
            ),
            SizedBox(height: 12.h),

            // ── Date + Total ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IqText(
                  trip.formattedTotal,
                  style: AppTypography.heading1.copyWith(
                    fontFamily: AppTypography.fontFamilyArabic,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IqText(
                  _dateFormat.format(trip.createdAt),
                  style: AppTypography.numberMedium.copyWith(
                    fontFamily: AppTypography.fontFamilyLatin,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grayDate,
                  ),
                  dir: ui.TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: IqText(
        config.label,
        style: AppTypography.labelSmall.copyWith(
          color: config.textColor,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  static _BadgeConfig _getConfig(TripStatus status) {
    switch (status) {
      case TripStatus.completed:
        return const _BadgeConfig(
          label: 'مكتمل',
          backgroundColor: AppColors.statusCompletedBg,
          textColor: AppColors.statusCompletedText,
          borderColor: AppColors.statusCompletedBorder,
        );
      case TripStatus.cancelled:
        return const _BadgeConfig(
          label: 'تم الإلغاء',
          backgroundColor: AppColors.statusCancelledBg,
          textColor: AppColors.statusCancelledText,
          borderColor: AppColors.statusCancelledBorder,
        );
      case TripStatus.upcoming:
        return const _BadgeConfig(
          label: 'قادم',
          backgroundColor: AppColors.statusOngoingBg,
          textColor: AppColors.statusOngoingText,
          borderColor: AppColors.statusOngoingBorder,
        );
      case TripStatus.unknown:
        return const _BadgeConfig(
          label: 'غير معروف',
          backgroundColor: AppColors.grayDivider,
          textColor: AppColors.grayDate,
          borderColor: AppColors.grayBorder,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _BadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

// ── Vehicle Type Label ────────────────────────────────────────

class _VehicleTypeLabel extends StatelessWidget {
  const _VehicleTypeLabel({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    final isTaxi = trip.isTaxi;
    final color = isTaxi ? AppColors.taxiBadge : AppColors.deliveryBadge;
    final label =
        isTaxi ? 'تاكسي' : (trip.vehicleTypeName.isNotEmpty ? trip.vehicleTypeName : 'مندوب');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions_car_filled_outlined,
          size: 18.w,
          color: color,
        ),
        SizedBox(width: 4.w),
        IqText(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}

// ── Address Pill ──────────────────────────────────────────────

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.address,
    required this.markerColor,
  });

  final String address;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: isDark ? AppColors.white.withValues(alpha: 0.24) : AppColors.grayBorder,
        ),
      ),
      child: Row(
        children: [
          // Oval marker icon
          Container(
            width: 10.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(5.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: IqText(
              address,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.white.withValues(alpha: 0.70) : AppColors.textAddress,
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
