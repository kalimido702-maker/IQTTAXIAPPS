import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/services/map_performance.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/incoming_request_model.dart';
import '../../bloc/driver/driver_trip_bloc.dart';
import '../../bloc/driver/driver_trip_event.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/swipe_to_accept_button.dart';
import '../../widgets/trip_address_row.dart';

/// Full-screen overlay shown when a new ride request comes in.
/// Figma 7:6066.
class IncomingRequestOverlay extends StatefulWidget {
  const IncomingRequestOverlay({super.key, required this.request});

  final IncomingRequestModel request;

  @override
  State<IncomingRequestOverlay> createState() => _IncomingRequestOverlayState();
}

class _IncomingRequestOverlayState extends State<IncomingRequestOverlay> {
  Timer? _countdownTimer;
  int _secondsLeft = 0;

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
    _calculateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          // Auto-reject on timeout
          _countdownTimer?.cancel();
          context.read<DriverTripBloc>().add(
            DriverTripRejected(widget.request.requestId),
          );
        }
      });
    });
  }

  void _calculateTimeLeft() {
    if (widget.request.expiresAt != null) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _secondsLeft = (widget.request.expiresAt! - nowSec).clamp(0, 120);
    } else {
      _secondsLeft = 60;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Map preview (top half)
            Expanded(
              flex: 4,
              child: ClipRRect(
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
            ),

            // Request details (bottom half)
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IqText(
                          'تفاصيل الرحلة',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        // Timer badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: _secondsLeft <= 10
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.primary50,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: IqText(
                            '$_secondsLeft ثانية',
                            style: AppTypography.labelMedium.copyWith(
                              color: _secondsLeft <= 10
                                  ? AppColors.error
                                  : AppColors.primary700,
                            ),
                            dir: TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Vehicle type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.taxiBadge.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: IqText(
                        req.vehicleTypeName,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.taxiBadge,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // User info
                    UserInfoCard(
                      name: req.userName ?? '',
                      photoUrl: req.userImage,
                      rating: double.tryParse(req.userRating ?? '') ?? 0.0,
                      showActions: false,
                    ),
                    SizedBox(height: 16.h),

                    // Price + distance row
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          value: '${req.totalAmount.toStringAsFixed(0)} IQD',
                        ),
                        SizedBox(width: 12.w),
                        _InfoChip(
                          icon: Icons.straighten_rounded,
                          value: '${req.distance.toStringAsFixed(1)} كم',
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Addresses
                    TripAddressRow(
                      pickAddress: req.pickAddress,
                      dropAddress: req.dropAddress,
                    ),
                    SizedBox(height: 24.h),

                    // Reject + Swipe to accept
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
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: IqText(
                                    'رفض',
                                    style: AppTypography.labelMedium.copyWith(
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
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.grayLightBg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.w, color: AppColors.textMuted),
            SizedBox(width: 6.w),
            IqText(
              value,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
