import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iq_core/core/core.dart';

import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/map_performance.dart';
import '../../data/models/parcel_request_model.dart';
import '../bloc/package_delivery_bloc.dart';
import '../bloc/package_delivery_event.dart';
import '../bloc/package_delivery_state.dart';

/// Screen 1 — Parcel landing page.
///
/// Displays a Google Map in the background with a bottom-sheet overlay
/// containing a delivery illustration, title, subtitle, and two
/// side-by-side action buttons: "إرسال طرد" / "استقبال طرد".
///
/// Matches Figma node 7:1472.
class ParcelLandingPage extends StatefulWidget {
  const ParcelLandingPage({
    super.key,
    required this.onSendTapped,
    required this.onReceiveTapped,
    this.initialLat,
    this.initialLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  /// Called after [PackageDeliveryModeSelected] is dispatched for **send**.
  final VoidCallback onSendTapped;

  /// Called after [PackageDeliveryModeSelected] is dispatched for **receive**.
  final VoidCallback onReceiveTapped;

  /// Initial map center / pickup coordinates.
  final double? initialLat;
  final double? initialLng;

  /// Drop-off coordinates — used together with pickup to draw route.
  final double? dropoffLat;
  final double? dropoffLng;

  @override
  State<ParcelLandingPage> createState() => _ParcelLandingPageState();
}

class _ParcelLandingPageState extends State<ParcelLandingPage> {
  final _mapKey = GlobalKey<IqMapViewState>();

  /// Bottom sheet occupies roughly 55 % of the screen.
  static const double _sheetFraction = 0.55;

  /// Route data from Google Directions API.
  DirectionsResult? _directions;

  /// Markers for pickup & drop-off.
  Set<Marker> _markers = {};

  /// Polyline showing the route.
  Set<Polyline> _polylines = {};

  /// Whether both endpoints are available.
  bool get _hasRoute =>
      widget.initialLat != null &&
      widget.initialLng != null &&
      widget.dropoffLat != null &&
      widget.dropoffLng != null &&
      widget.dropoffLat != 0 &&
      widget.dropoffLng != 0;

  @override
  void initState() {
    super.initState();
    if (_hasRoute) {
      _buildMapObjects();
      _fetchDirections();
    }
  }

  /// Build markers & fallback straight-line polyline.
  void _buildMapObjects() {
    final pickup = LatLng(widget.initialLat!, widget.initialLng!);
    final dropoff = LatLng(widget.dropoffLat!, widget.dropoffLng!);

    _markers = {
      Marker(
        markerId: MapMarkerIds.pickup,
        position: pickup,
        icon: MapIcons.numberedSync(1),
      ),
      Marker(
        markerId: MapMarkerIds.dropoff,
        position: dropoff,
        icon: MapIcons.numberedSync(2),
      ),
    };

    // Show fallback straight line until directions load.
    final pts = _directions?.polylinePoints;
    if (pts != null && pts.isNotEmpty) {
      final snapped = RouteHelper.snapToEndpoints(pts, pickup, dropoff);
      _polylines = {MapRouteStyle.route(points: snapped)};
    } else {
      _polylines = {
        MapRouteStyle.fallbackLine(from: pickup, to: dropoff),
      };
    }
  }

  /// Fetch Google Directions for accurate route polyline.
  Future<void> _fetchDirections() async {
    final result = await RouteHelper.fetchRoute(
      service: sl<GoogleMapsService>(),
      originLat: widget.initialLat!,
      originLng: widget.initialLng!,
      destLat: widget.dropoffLat!,
      destLng: widget.dropoffLng!,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _directions = result;
        _buildMapObjects();
      });
      // Fit camera to the actual route bounds.
      final bounds = calculateBounds(result.polylinePoints);
      _mapKey.currentState?.fitBounds(bounds);
    }
  }

  /// Fit the camera to show both pickup and drop-off.
  void _fitRoute() {
    if (!_hasRoute) return;
    final bounds = calculateBounds([
      LatLng(widget.initialLat!, widget.initialLng!),
      LatLng(widget.dropoffLat!, widget.dropoffLng!),
    ]);
    _mapKey.currentState?.fitBounds(bounds);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
      listenWhen: (prev, curr) =>
          curr.status == PackageDeliveryStatus.enteringRecipient,
      listener: (context, state) {
        if (state.parcelRequest.parcelType == ParcelType.send) {
          widget.onSendTapped();
        } else {
          widget.onReceiveTapped();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ── Map background with route ────────────────────
            Positioned.fill(
              child: IqMapView(
                key: _mapKey,
                initialTarget: widget.initialLat != null
                    ? LatLng(widget.initialLat!, widget.initialLng!)
                    : null,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                onMapCreated: (_) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (_hasRoute) {
                      _fitRoute();
                    } else {
                      _mapKey.currentState?.goToMyLocation();
                    }
                  });
                },
                mapPadding: EdgeInsets.only(
                  bottom: screenHeight * _sheetFraction,
                ),
              ),
            ),

            // ── Back button ─────────────────────────────────
            Positioned(
              top: topPadding + 12.h,
              right: 16.w,
              child: _CircleButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // ── My location FAB ─────────────────────────────
            Positioned(
              bottom: screenHeight * _sheetFraction + 16.h,
              left: 16.w,
              child: _CircleButton(
                icon: Icons.my_location,
                iconColor: AppColors.primary,
                onTap: () => _mapKey.currentState?.goToMyLocation(),
              ),
            ),

            // ── Bottom sheet overlay ────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ParcelBottomSheet(
                onSendTapped: () {
                  context.read<PackageDeliveryBloc>().add(
                        const PackageDeliveryModeSelected(ParcelType.send),
                      );
                },
                onReceiveTapped: () {
                  context.read<PackageDeliveryBloc>().add(
                        const PackageDeliveryModeSelected(ParcelType.receive),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bottom sheet content — matches Figma node 7:1472
// ─────────────────────────────────────────────────────────────────

class _ParcelBottomSheet extends StatelessWidget {
  const _ParcelBottomSheet({
    required this.onSendTapped,
    required this.onReceiveTapped,
  });

  final VoidCallback onSendTapped;
  final VoidCallback onReceiveTapped;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: bottomPadding + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.grayInactive,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          SizedBox(height: 16.h),

          // ── Title ──
          IqText(
            AppStrings.sendReceivePackage,
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // ── Subtitle ──
          IqText(
            AppStrings.sendReceiveSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF595959),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),

          SizedBox(height: 16.h),

          // ── Delivery illustration ──
          IqImage(
            AppAssets.sendReceive,
            width: 200.w,
            height: 150.h,
          ),

          SizedBox(height: 24.h),

          // ── Side-by-side buttons ──
          Row(
            children: [
              // Send button (primary / yellow)
              Expanded(
                child: IqPrimaryButton(
                  text: AppStrings.sendParcel,
                  onPressed: onSendTapped,
                ),
              ),
              SizedBox(width: 12.w),
              // Receive button (outlined)
              Expanded(
                child: SizedBox(
                  height: 56.h,
                  child: OutlinedButton(
                    onPressed: onReceiveTapped,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.black,
                      side: BorderSide(color: AppColors.black, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1000.r),
                      ),
                    ),
                    child: IqText(
                      AppStrings.receiveParcel,
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable circle button ─────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final s = 44.w;
    return SizedBox(
      width: s,
      height: s,
      child: Material(
        elevation: 4,
        shadowColor: AppColors.shadow,
        shape: const CircleBorder(),
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            icon,
            size: s * 0.5,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
