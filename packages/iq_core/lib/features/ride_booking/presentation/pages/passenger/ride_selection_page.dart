import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iq_core/core/constants/app_strings.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/google_maps_service.dart';
import '../../../../../core/utils/geo_utils.dart';
import '../../../../../core/services/map_performance.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import '../../bloc/passenger/passenger_trip_event.dart';
import '../../bloc/passenger/passenger_trip_state.dart';
import '../../widgets/ride_bottom_sheets.dart';
import '../../widgets/vehicle_type_card.dart';
import 'passenger_active_trip_page.dart';

/// Ride selection page — vehicle type, promo, payment, confirm booking.
/// Figma 7:2781.
class RideSelectionPage extends StatelessWidget {
  const RideSelectionPage({
    super.key,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.stops = const [],
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  /// Intermediate stops (max 2). Each: {order, lat, lng, address}.
  final List<Map<String, dynamic>> stops;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<PassengerTripBloc>(),
      child: _Body(
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffAddress: dropoffAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        stops: stops,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    this.stops = const [],
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final List<Map<String, dynamic>> stops;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _mapKey = GlobalKey<IqMapViewState>();

  /// Route data from Google Directions API.
  DirectionsResult? _directions;
  bool _isLoadingRoute = false;

  /// Cached markers — rebuilt only when directions change.
  late Set<Marker> _markers;

  /// Cached polylines — rebuilt only when directions change.
  late Set<Polyline> _polylines;

  void _rebuildMapObjects() {
    // Marker numbering: 1=pickup, 2..N=stops, N+1=dropoff.
    final totalPoints = 2 + widget.stops.length;
    _markers = {
      Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: MapIcons.numberedSync(1),
      ),
      for (var i = 0; i < widget.stops.length; i++)
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(
            (widget.stops[i]['lat'] as num).toDouble(),
            (widget.stops[i]['lng'] as num).toDouble(),
          ),
          icon: MapIcons.numberedSync(i + 2),
        ),
      Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: MapIcons.numberedSync(totalPoints),
      ),
    };

    final pts = _directions?.polylinePoints;
    if (pts != null && pts.isNotEmpty) {
      final pickup = LatLng(widget.pickupLat, widget.pickupLng);
      final dropoff = LatLng(widget.dropoffLat, widget.dropoffLng);
      final snapped = RouteHelper.snapToEndpoints(pts, pickup, dropoff);
      _polylines = { MapRouteStyle.route(points: snapped) };
    } else {
      _polylines = {
        MapRouteStyle.fallbackLine(
          from: LatLng(widget.pickupLat, widget.pickupLng),
          to: LatLng(widget.dropoffLat, widget.dropoffLng),
        ),
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _rebuildMapObjects();
    _fetchDirections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRoute();
    });
  }

  /// Fetch Google Directions for accurate route, distance & duration.
  /// Fires the ETA API call once we have the route data so the server
  /// receives distance + duration + polyline and returns the correct fare.
  Future<void> _fetchDirections() async {
    setState(() => _isLoadingRoute = true);

    // Build waypoints from intermediate stops.
    final waypoints = widget.stops
        .map((s) => LatLng(
              (s['lat'] as num).toDouble(),
              (s['lng'] as num).toDouble(),
            ))
        .toList();

    final result = await RouteHelper.fetchRoute(
      service: sl<GoogleMapsService>(),
      originLat: widget.pickupLat,
      originLng: widget.pickupLng,
      destLat: widget.dropoffLat,
      destLng: widget.dropoffLng,
      waypoints: waypoints.isNotEmpty ? waypoints : null,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _directions = result;
        _isLoadingRoute = false;
        _rebuildMapObjects();
      });
      // Re-fit camera to actual route bounds.
      final bounds = calculateBounds(result.polylinePoints);
      _mapKey.currentState?.fitBounds(bounds);

      // Fire ETA with route data.
      // Distance for PRICING → straight-line (Haversine) so fares are lower.
      // Duration → real Google duration so ETA stays accurate.
      final straightLineKm = GeoUtils.haversineDistance(
        widget.pickupLat,
        widget.pickupLng,
        widget.dropoffLat,
        widget.dropoffLng,
      );
      final straightLineMeters = straightLineKm * 1000;

      if (!mounted) return;
      context.read<PassengerTripBloc>().add(PassengerTripEtaRequested(
            pickLat: widget.pickupLat,
            pickLng: widget.pickupLng,
            dropLat: widget.dropoffLat,
            dropLng: widget.dropoffLng,
            pickAddress: widget.pickupAddress,
            dropAddress: widget.dropoffAddress,
            distance: straightLineMeters,
            duration: result.durationSeconds / 60.0,
            polyline: result.encodedPolyline,
            stops: widget.stops.isNotEmpty ? widget.stops : null,
          ));
    } else {
      setState(() => _isLoadingRoute = false);
      // Fallback: request ETA without route data (minimum fare).
      if (!mounted) return;
      context.read<PassengerTripBloc>().add(PassengerTripEtaRequested(
            pickLat: widget.pickupLat,
            pickLng: widget.pickupLng,
            dropLat: widget.dropoffLat,
            dropLng: widget.dropoffLng,
            pickAddress: widget.pickupAddress,
            dropAddress: widget.dropoffAddress,
            stops: widget.stops.isNotEmpty ? widget.stops : null,
          ));
    }
  }

  void _fitRoute() {
    final points = [
      LatLng(widget.pickupLat, widget.pickupLng),
      for (final s in widget.stops)
        LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
      LatLng(widget.dropoffLat, widget.dropoffLng),
    ];
    final bounds = calculateBounds(points);
    _mapKey.currentState?.fitBounds(bounds);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PassengerTripBloc, PassengerTripState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PassengerTripStatus.searchingDriver ||
            state.status == PassengerTripStatus.activeTrip) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PassengerActiveTripPage(),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Map
            Positioned.fill(
              child: IqMapView(
                key: _mapKey,
                initialTarget: LatLng(widget.pickupLat, widget.pickupLng),
                markers: _markers,
                polylines: _polylines,
                mapPadding: EdgeInsets.only(bottom: 380.h),
              ),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              right: 16.w,
              child: _CircleIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            // Bottom sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                pickupAddress: widget.pickupAddress,
                dropoffAddress: widget.dropoffAddress,
                directions: _directions,
                isLoadingRoute: _isLoadingRoute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.pickupAddress,
    required this.dropoffAddress,
    this.directions,
    this.isLoadingRoute = false,
  });

  final String pickupAddress;
  final String dropoffAddress;
  final DirectionsResult? directions;
  final bool isLoadingRoute;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.chatShadow,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BlocBuilder<PassengerTripBloc, PassengerTripState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.vehicleTypes != curr.vehicleTypes ||
            prev.selectedVehicle != curr.selectedVehicle ||
            prev.paymentOpt != curr.paymentOpt ||
            prev.promoCode != curr.promoCode ||
            prev.scheduledTime != curr.scheduledTime ||
            prev.selectedPreferences != curr.selectedPreferences ||
            prev.instructions != curr.instructions,
        builder: (context, state) {
          if (state.status == PassengerTripStatus.loadingEta) {
            return Padding(
              padding: EdgeInsets.all(40.w),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (state.status == PassengerTripStatus.error) {
            return Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 40.w),
                  SizedBox(height: 8.h),
                  IqText(
                    state.errorMessage ?? AppStrings.errorOccurred,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final vehicles = state.vehicleTypes;
          final selected = state.selectedVehicle;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.h),

                // ─── Title ───
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: IqText(
                      AppStrings.enjoyYourTrip,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.black,
                        fontWeight: FontWeight.w700,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // ─── Section header — "أنواع الرحلات" ───
                SizedBox(
                  width: double.infinity,
                  child: IqText(
                    AppStrings.tripTypes,
                    style: AppTypography.heading3.copyWith(
                      color: isDark ? AppColors.white : AppColors.black,
                      fontWeight: FontWeight.w700,
                      height: 1.33,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                SizedBox(height: 16.h),

                // ─── Vehicle type cards ───
                if (vehicles.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: IqText(
                        AppStrings.noDataToDisplay,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.chipText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...vehicles.map((v) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: VehicleTypeCard(
                      name: v.name,
                      icon: v.icon,
                      price: v.total.toStringAsFixed(2),
                      capacity: v.capacity,
                      isSelected: selected?.zoneTypeId == v.zoneTypeId,
                      currency: v.currencySymbol,
                      description: v.shortDescription,
                      onTap: () {
                        context
                            .read<PassengerTripBloc>()
                            .add(PassengerTripVehicleSelected(v));
                      },
                    ),
                  );
                }),

                SizedBox(height: 20.h),

                // ─── Promo code row ───
                _PromoCodeRow(
                  appliedCode: state.promoCode,
                  onTap: () async {
                    final code = await showPromoCodeSheet(
                      context,
                      currentCode: state.promoCode,
                    );
                    if (code != null && context.mounted) {
                      context.read<PassengerTripBloc>().add(
                            PassengerTripPromoApplied(
                              code.isEmpty ? null : code,
                            ),
                          );
                    }
                  },
                ),

                SizedBox(height: 15.h),

                // ─── Payment row ───
                _PaymentRow(
                  currentPayment: state.paymentOpt,
                  onChanged: (opt) async {
                    final result = await showPaymentMethodSheet(
                      context,
                      currentPayment: state.paymentOpt,
                      allowedMethods:
                          selected?.paymentTypes ?? const {},
                    );
                    if (result != null && context.mounted) {
                      context
                          .read<PassengerTripBloc>()
                          .add(PassengerTripPaymentChanged(result));
                    }
                  },
                ),

                SizedBox(height: 30.h),

                // ─── Schedule + Preferences buttons ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _PillButton(
                        text: state.scheduledTime != null
                            ? '${AppStrings.rideLater} ✓'
                            : AppStrings.scheduleRide,
                        backgroundColor: state.scheduledTime != null
                            ? AppColors.primary
                            : AppColors.black,
                        textColor: state.scheduledTime != null
                            ? AppColors.black
                            : AppColors.white,
                        onTap: () async {
                          final result = await showScheduleRideSheet(
                            context,
                            currentSchedule: state.scheduledTime,
                          );
                          if (result != null && context.mounted) {
                            final bloc = context.read<PassengerTripBloc>();
                            if (result is DateTime) {
                              bloc.add(PassengerTripScheduleChanged(result));
                            } else {
                              // empty string = remove schedule
                              bloc.add(
                                  const PassengerTripScheduleChanged(null));
                            }
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 30.w),
                    Expanded(
                      child: _PillButton(
                        text: state.selectedPreferences.isNotEmpty
                            ? '${AppStrings.ridePreferences} (${state.selectedPreferences.length})'
                            : AppStrings.ridePreferences,
                        backgroundColor: AppColors.buttonYellow,
                        textColor: AppColors.black,
                        onTap: () async {
                          final prefs = selected?.preferences ?? [];
                          final currentIds = state.selectedPreferences
                              .map((m) => m['id'] as int)
                              .toList();
                          final result = await showRidePreferencesSheet(
                            context,
                            availablePreferences: prefs,
                            selectedIds: currentIds,
                            currentInstructions: state.instructions,
                          );
                          if (result != null && context.mounted) {
                            final bloc = context.read<PassengerTripBloc>();
                            bloc.add(PassengerTripPreferencesChanged(
                              (result['preferences'] as List<Map<String, dynamic>>?) ?? [],
                            ));
                            final instr = result['instructions'] as String?;
                            bloc.add(PassengerTripInstructionsChanged(
                              (instr != null && instr.isNotEmpty) ? instr : null,
                            ));
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30.h),

                // ─── Ride now button ───
                _RideNowButton(
                  isLoading: state.status ==
                      PassengerTripStatus.creatingRequest,
                  isScheduled: state.scheduledTime != null,
                  onPressed: selected != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          context
                              .read<PassengerTripBloc>()
                              .add(PassengerTripCreateRequested(
                                polyline: directions?.encodedPolyline,
                              ));
                        }
                      : null,
                ),

                SizedBox(height: 34.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets — pixel-matched to Figma export
// ─────────────────────────────────────────────────────────────────────────────

/// Promo code row — white bg, shadow, radius 16, height 54.
class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow({required this.onTap, this.appliedCode});

  final VoidCallback onTap;
  final String? appliedCode;

  @override
  Widget build(BuildContext context) {
    final hasCode = appliedCode != null && appliedCode!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: hasCode
              ? AppColors.buttonYellow.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.chatShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 16.w,
              color: isDark ? AppColors.white : AppColors.black,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasCode) ...[
                  Icon(Icons.check_circle,
                      size: 18.w, color: AppColors.buttonYellow),
                  SizedBox(width: 8.w),
                ],
                IqText(
                  hasCode ? '${AppStrings.promoCode}: $appliedCode' : AppStrings.promoCode,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment row — white bg, shadow, radius 16, height 70.
/// Shows payment icon + name (18sp bold) + subtitle "تغيير طريقة الدفع" (14sp).
class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.currentPayment,
    required this.onChanged,
  });

  final int currentPayment;
  final ValueChanged<int> onChanged;

  String get _paymentName {
    switch (currentPayment) {
      case 0:
        return AppStrings.onlinePayment;
      case 1:
        return AppStrings.cash;
      case 2:
        return AppStrings.walletPayment;
      default:
        return AppStrings.cash;
    }
  }

  IconData get _paymentIcon {
    switch (currentPayment) {
      case 0:
        return Icons.credit_card;
      case 1:
        return Icons.payments_outlined;
      case 2:
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(currentPayment);
      },
      child: Container(
        width: double.infinity,
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.chatShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Arrow (leading in LTR = left side. In RTL this becomes right.)
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 16.w,
              color: AppColors.grayDate,
            ),
            const Spacer(),
            // Name + subtitle
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IqText(
                  _paymentName,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
                IqText(
                  AppStrings.changePaymentMethod,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grayDate,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            SizedBox(width: 15.w),
            // Payment icon
            Icon(_paymentIcon, size: 24.w, color: isDark ? AppColors.white : AppColors.black),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped button — used for "جدولة الرحلة" (black) and "تفضيلات الرحلة" (yellow).
/// Figma: height 60, borderRadius 1000, padding h:40 v:18, fontSize 18, w700.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        alignment: Alignment.center,
        child: IqText(
          text,
          style: AppTypography.heading3.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// "ركوب الآن" yellow pill button.
/// Figma: width ~189, borderRadius 75, yellow bg, black text 18sp bold.
class _RideNowButton extends StatelessWidget {
  const _RideNowButton({
    required this.isLoading,
    required this.onPressed,
    this.isScheduled = false,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isScheduled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onPressed!();
            },
      child: Container(
        width: 189.w,
        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.5.h),
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.buttonYellow
              : AppColors.buttonYellow.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(75.r),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.black,
                ),
              )
            : IqText(
                isScheduled ? AppStrings.rideLater : AppStrings.rideNow,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}

/// Back button — white circle with optional outer glow. Used on map overlay.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 35.w,
        height: 35.w,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCard : AppColors.white).withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(icon, size: 20.w, color: isDark ? AppColors.white : AppColors.black),
          ),
        ),
      ),
    );
  }
}


