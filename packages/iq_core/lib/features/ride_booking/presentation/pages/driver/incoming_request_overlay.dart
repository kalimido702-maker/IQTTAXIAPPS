import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/services/map_performance.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/incoming_request_model.dart';
import '../../bloc/driver/driver_trip_bloc.dart';
import '../../bloc/driver/driver_trip_event.dart';
import '../../widgets/swipe_to_accept_button.dart';

/// Full-screen overlay shown when a new ride request comes in.
///
/// Re-designed to match the old app layout:
/// Map on top → bottom sheet with trip details, user info, fare, distance,
/// addresses, auto-cancel countdown bar, reject + swipe-to-accept.
class IncomingRequestOverlay extends StatefulWidget {
  const IncomingRequestOverlay({
    super.key,
    required this.request,
    this.acceptDuration = 30,
  });

  final IncomingRequestModel request;

  /// Maximum seconds the driver has to accept/reject.
  final int acceptDuration;

  @override
  State<IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends State<IncomingRequestOverlay> {
  Timer? _countdownTimer;
  late int _secondsLeft;

  /// Cached markers — created once, never rebuilt by timer.
  late final Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(widget.request.pickLat, widget.request.pickLng),
        icon: MapIcons.pickup,
      ),
      Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(widget.request.dropLat, widget.request.dropLng),
        icon: MapIcons.dropoff,
      ),
    };
    _secondsLeft = widget.acceptDuration;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _countdownTimer?.cancel();
          context.read<DriverTripBloc>().add(
            DriverTripRejected(widget.request.requestId),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Progress 0..1 for the circular timer indicator.
  double get _timerProgress =>
      widget.acceptDuration > 0
          ? (_secondsLeft / widget.acceptDuration).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkBackground : AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Map preview (top) ─────────────────────────────
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24.r),
                    ),
                    child: IqMapView(
                      initialTarget: LatLng(req.pickLat, req.pickLng),
                      initialZoom: 14,
                      markers: _markers,
                      myLocationEnabled: false,
                      liteModeEnabled: true,
                      keepAlive: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 8.h,
                    left: 12.w,
                    child: _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<DriverTripBloc>().add(
                          DriverTripRejected(req.requestId),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom sheet ──────────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24.r)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 50.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Title
                      Center(
                        child: IqText(
                          AppStrings.tripDetails,
                          style: AppTypography.heading3.copyWith(
                            color:
                                isDark ? AppColors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Vehicle type badge (centered)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_car_filled_rounded,
                              size: 16.w,
                              color: AppColors.primary700,
                            ),
                            SizedBox(width: 4.w),
                            IqText(
                              req.vehicleTypeName,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── User info + fare row ────────────────
                      Row(
                        children: [
                          // Avatar
                          ClipOval(
                            child: Container(
                              width: 50.w,
                              height: 50.w,
                              color: AppColors.grayLightBg,
                              child: req.userImage != null &&
                                      req.userImage!.isNotEmpty
                                  ? Image.network(
                                      req.userImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        size: 30.w,
                                        color: AppColors.grayLight,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 30.w,
                                      color: AppColors.grayLight,
                                    ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // Name + rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IqText(
                                  req.userName ?? AppStrings.newUser,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16.w,
                                      color: AppColors.starFilled,
                                    ),
                                    SizedBox(width: 2.w),
                                    IqText(
                                      double.tryParse(req.userRating ?? '0')
                                              ?.toStringAsFixed(1) ??
                                          '0.0',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (req.totalRides != null) ...[
                                      SizedBox(width: 6.w),
                                      IqText(
                                        '(${req.totalRides} ${AppStrings.totalRidesCount})',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Fare
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IqText(
                                AppStrings.rideFare,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              IqText(
                                'IQD ${req.totalAmount.toStringAsFixed(0)}',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                                dir: TextDirection.ltr,
                              ),
                              SizedBox(height: 2.h),
                              IqText(
                                req.paymentMethod == 1
                                    ? AppStrings.cash
                                    : AppStrings.electronicPayment,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Distance
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 16.w,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 6.w),
                          IqText(
                            '${req.distance.toStringAsFixed(1)} ${AppStrings.km}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // ── "عناوين الرحلة" section ─────────────
                      IqText(
                        AppStrings.tripAddressesLabel,
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.white : AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Pickup address
                      _AddressRow(
                        color: AppColors.markerGreen,
                        address: req.pickAddress,
                      ),
                      SizedBox(height: 8.h),
                      // Drop address
                      _AddressRow(
                        color: AppColors.markerRed,
                        address: req.dropAddress,
                      ),
                      SizedBox(height: 14.h),

                      // ── Auto-cancel countdown bar ───────────
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkInputBg
                              : AppColors.grayLightBg,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: IqText(
                                '${AppStrings.autoCancelWarning} $_secondsLeft ${AppStrings.second}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Circular timer
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: CustomPaint(
                                painter: _CircularTimerPainter(
                                  progress: _timerProgress,
                                  color: _secondsLeft <= 10
                                      ? AppColors.error
                                      : AppColors.primary,
                                  bgColor: AppColors.grayLight
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // ── Reject + Swipe to accept ────────────
                      Row(
                        children: [
                          // Reject button
                          SizedBox(
                            width: 80.w,
                            child: Material(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30.r),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  context.read<DriverTripBloc>().add(
                                    DriverTripRejected(req.requestId),
                                  );
                                },
                                borderRadius: BorderRadius.circular(30.r),
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 16.h),
                                  child: Center(
                                    child: IqText(
                                      AppStrings.reject,
                                      style:
                                          AppTypography.labelMedium.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Swipe to accept
                          Expanded(
                            child: SwipeToAcceptButton(
                              onAccepted: () {
                                context.read<DriverTripBloc>().add(
                                  DriverTripAccepted(req.requestId),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

/// Small circle icon button for the map overlay (back, menu, etc.).
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(icon, size: 22.w, color: AppColors.textDark),
        ),
      ),
    );
  }
}

/// A single address row with a colored dot and text inside a bordered card.
class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.color, required this.address});
  final Color color;
  final String address;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.1)
              : AppColors.grayLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: IqText(
              address,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.white : AppColors.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a circular arc to indicate remaining time.
class _CircularTimerPainter extends CustomPainter {
  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  final double progress; // 0..1
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 3.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    const startAngle = -3.14159265 / 2; // top
    final sweepAngle = 2 * 3.14159265 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
