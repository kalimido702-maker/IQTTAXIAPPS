import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/google_maps_service.dart';
import '../../../../../core/services/map_performance.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import '../../bloc/passenger/passenger_trip_event.dart';
import '../../bloc/passenger/passenger_trip_state.dart';
import '../../widgets/trip_address_row.dart';
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
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<PassengerTripBloc>()
        ..add(PassengerTripEtaRequested(
          pickLat: pickupLat,
          pickLng: pickupLng,
          dropLat: dropoffLat,
          dropLng: dropoffLng,
          pickAddress: pickupAddress,
          dropAddress: dropoffAddress,
        )),
      child: _Body(
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffAddress: dropoffAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
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
  });

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _mapKey = GlobalKey<IqMapViewState>();

  /// Route data from Google Directions API.
  DirectionsResult? _directions;
  bool _isLoadingRoute = false;

  /// Cached marker / polyline sets — computed once and only rebuilt when
  /// the underlying data changes. Avoids re-allocating objects per frame.
  late final Set<Marker> _markers = _buildMarkers();
  Set<Polyline> _routePolylines = const {};

  /// Cached hue icons — avoid repeated SDK look-ups every build.
  static final _pickupIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  static final _dropoffIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  Set<Marker> _buildMarkers() => {
        Marker(
          markerId: MapMarkerIds.pickup,
          position: LatLng(widget.pickupLat, widget.pickupLng),
          icon: _pickupIcon,
        ),
        Marker(
          markerId: MapMarkerIds.dropoff,
          position: LatLng(widget.dropoffLat, widget.dropoffLng),
          icon: _dropoffIcon,
        ),
      };

  /// Build polylines once from current _directions. Called only when
  /// _directions actually changes (inside _fetchDirections setState).
  Set<Polyline> _buildRoutePolylines() {
    final pts = _directions?.polylinePoints;
    if (pts == null || pts.isEmpty) {
      return {
        Polyline(
          polylineId: MapPolylineIds.route,
          color: AppColors.routeLine,
          width: 5,
          points: [
            LatLng(widget.pickupLat, widget.pickupLng),
            LatLng(widget.dropoffLat, widget.dropoffLng),
          ],
        ),
      };
    }
    final simplified = simplifyPolyline(pts);
    return {
      Polyline(
        polylineId: MapPolylineIds.route,
        color: AppColors.routeLine,
        width: 5,
        geodesic: true,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        points: simplified,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    // Build initial fallback polyline (straight line).
    _routePolylines = _buildRoutePolylines();
    _fetchDirections();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRoute();
    });
  }

  /// Fetch Google Directions for accurate route, distance & duration.
  Future<void> _fetchDirections() async {
    setState(() => _isLoadingRoute = true);
    try {
      final service = sl<GoogleMapsService>();
      final result = await service.getDirections(
        originLat: widget.pickupLat,
        originLng: widget.pickupLng,
        destLat: widget.dropoffLat,
        destLng: widget.dropoffLng,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _directions = result;
          _isLoadingRoute = false;
          // Rebuild cached polylines with the real directions data.
          _routePolylines = _buildRoutePolylines();
        });
        // Re-fit camera to actual route bounds.
        final bounds = calculateBounds(result.polylinePoints);
        _mapKey.currentState?.fitBounds(bounds);
      } else {
        setState(() => _isLoadingRoute = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _fitRoute() {
    final bounds = calculateBounds([
      LatLng(widget.pickupLat, widget.pickupLng),
      LatLng(widget.dropoffLat, widget.dropoffLng),
    ]);
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
                polylines: _routePolylines,
                mapPadding: EdgeInsets.only(bottom: 380.h),
              ),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              right: 16.w,
              child: _CircleButton(
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BlocBuilder<PassengerTripBloc, PassengerTripState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.vehicleTypes != curr.vehicleTypes ||
            prev.selectedVehicle != curr.selectedVehicle ||
            prev.paymentOpt != curr.paymentOpt,
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
                    state.errorMessage ?? 'حدث خطأ',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final vehicles = state.vehicleTypes;
          final selected = state.selectedVehicle;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                SizedBox(height: 16.h),

                // Addresses
                TripAddressRow(
                  pickAddress: pickupAddress,
                  dropAddress: dropoffAddress,
                  compact: true,
                ),
                SizedBox(height: 12.h),

                // Distance & Time from Google Directions
                if (directions != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _InfoChip(
                          icon: Icons.route_rounded,
                          label: directions!.distanceText,
                        ),
                        Container(
                          width: 1,
                          height: 24.h,
                          color: AppColors.primary200,
                        ),
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: directions!.durationText,
                        ),
                      ],
                    ),
                  )
                else if (isLoadingRoute)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 12.h),
                Divider(color: AppColors.grayBorder, height: 1),
                SizedBox(height: 16.h),

                // Vehicle type list
                IqText(
                  'اختر نوع الرحلة',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 12.h),
                ...vehicles.map((v) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: VehicleTypeCard(
                      name: v.name,
                      icon: v.icon,
                      price: v.total.toStringAsFixed(0),
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

                SizedBox(height: 12.h),

                // Payment row
                _PaymentRow(
                  currentPayment: state.paymentOpt,
                  onChanged: (opt) {
                    context
                        .read<PassengerTripBloc>()
                        .add(PassengerTripPaymentChanged(opt));
                  },
                ),

                SizedBox(height: 16.h),

                // Confirm button
                IqPrimaryButton(
                  text: 'ركوب الآن',
                  isLoading: state.status == PassengerTripStatus.creatingRequest,
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
              ],
            ),
          );
        },
      ),
    );
  }
}

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
        return 'نقدي';
      case 1:
        return 'محفظة';
      case 2:
        return 'بطاقة';
      default:
        return 'نقدي';
    }
  }

  IconData get _paymentIcon {
    switch (currentPayment) {
      case 0:
        return Icons.payments_outlined;
      case 1:
        return Icons.account_balance_wallet_outlined;
      case 2:
        return Icons.credit_card;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cycle through payment options
        onChanged((currentPayment + 1) % 3);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.grayLightBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(_paymentIcon, size: 22.w, color: AppColors.textDark),
            SizedBox(width: 10.w),
            IqText(
              _paymentName,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22.w,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Icon(icon, size: 20.w, color: AppColors.textDark),
        ),
      ),
    );
  }
}

/// Small icon + text chip for showing distance/time.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.w, color: AppColors.primary700),
        SizedBox(width: 6.w),
        IqText(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
