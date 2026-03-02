import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/ongoing_ride_model.dart';

/// Horizontally-scrolling carousel that shows the user's ongoing / active rides.
///
/// Matches the old app's `HomeOnGoingRidesWidget` design:
/// • PageView with `viewportFraction: 0.95` (peek next card).
/// • Each card: top section with pick/drop addresses, bottom section with
///   car number + vehicle type on left, status badge + fare on right.
/// • Dot indicators below.
class OngoingRidesCarousel extends StatefulWidget {
  const OngoingRidesCarousel({
    super.key,
    required this.rides,
    this.onRideTap,
  });

  final List<OngoingRideModel> rides;
  final void Function(OngoingRideModel ride)? onRideTap;

  @override
  State<OngoingRidesCarousel> createState() => _OngoingRidesCarouselState();
}

class _OngoingRidesCarouselState extends State<OngoingRidesCarousel> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.rides.take(3).toList(); // max 3 like old app

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Icon(Icons.bolt, color: AppColors.buttonYellow, size: 20.w),
              SizedBox(width: 6.w),
              IqText(
                'الرحلات النشطة',
                style: AppTypography.heading3.copyWith(fontSize: 16.sp),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // ─── Cards PageView ───
        SizedBox(
          height: MediaQuery.sizeOf(context).width * 0.375,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _OngoingRideCard(
                  ride: items[index],
                  onTap: () => widget.onRideTap?.call(items[index]),
                ),
              );
            },
          ),
        ),

        // ─── Dot indicators ───
        if (items.length > 1) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: isActive ? 20.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.grayLight,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Individual ride card
// ─────────────────────────────────────────────────────────────────

class _OngoingRideCard extends StatelessWidget {
  const _OngoingRideCard({required this.ride, this.onTap});

  final OngoingRideModel ride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grayDivider, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ─── Top: Addresses ───
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pickup row
                    Row(
                      children: [
                        _dot(const Color(0xFF4CAF50)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: IqText(
                            ride.pickAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Drop-off row
                    Row(
                      children: [
                        _dot(const Color(0xFFF44336)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: IqText(
                            ride.dropAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Divider ───
            Divider(height: 1, color: AppColors.grayDivider),

            // ─── Bottom: Car info + Status + Fare ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                children: [
                  // Left: car number + vehicle type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ride.carNumber.isNotEmpty)
                          IqText(
                            ride.carNumber,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                          ),
                        if (ride.vehicleTypeName.isNotEmpty)
                          IqText(
                            ride.vehicleTypeName,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textHint,
                            ),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),

                  // Right: status + fare
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(status: ride.rideStatus),
                      SizedBox(height: 2.h),
                      IqText(
                        '${ride.currencySymbol} ${ride.displayAmount}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Status badge matching old app colors
// ─────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OngoingRideStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OngoingRideStatus.accepted => ('تم القبول', const Color(0xFF2196F3)),
      OngoingRideStatus.arrived => ('السائق وصل', const Color(0xFFFF9800)),
      OngoingRideStatus.tripStarted => ('في الطريق', const Color(0xFF4CAF50)),
      OngoingRideStatus.completed => ('مكتملة', const Color(0xFF9E9E9E)),
      OngoingRideStatus.cancelled => ('ملغية', const Color(0xFFF44336)),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: IqText(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
