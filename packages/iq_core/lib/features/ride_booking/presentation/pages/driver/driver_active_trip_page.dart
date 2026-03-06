import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/google_maps_service.dart';
import '../../../../../core/services/map_performance.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_image.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/cancel_reason_model.dart';
import '../../../data/models/incoming_request_model.dart';
import '../../bloc/driver/driver_trip_bloc.dart';
import '../../bloc/driver/driver_trip_event.dart';
import '../../bloc/driver/driver_trip_state.dart';
import '../passenger/trip_invoice_page.dart';
import '../../widgets/cancel_reasons_sheet.dart';
import '../../widgets/waiting_timer_banner.dart';
import 'shipment_proof_page.dart';
import 'customer_signature_page.dart';

/// The main active trip page for drivers.
/// Shows different UI based on trip phase:
/// - Navigating to pickup → user info + addresses + "وصلت الرحلة" button
/// - Arrived at pickup → waiting timer + "إبدأ الرحلة" button
/// - Trip in progress → route + distance/time + "نهاية الرحلة" button
///
/// Figma: 7:5621, 7:5723, 7:5836
class DriverActiveTripPage extends StatelessWidget {
  const DriverActiveTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<DriverTripBloc>(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _mapKey = GlobalKey<IqMapViewState>();
  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    _startLocationStream();

    // If the page opens and the trip is already completed (restored from
    // _onCheckActiveTrip), the BlocConsumer listener won't fire because
    // there's no state *change*. Handle this edge case explicitly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final status = context.read<DriverTripBloc>().state.status;
      if (status == DriverTripStatus.tripCompleted) {
        _navigateToInvoice();
      } else if (status == DriverTripStatus.cancelled) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  /// Continuously stream GPS position to Firebase so the passenger app
  /// can show the driver marker on the map in real-time.
  void _startLocationStream() {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres — avoid spamming Firebase
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        context.read<DriverTripBloc>().add(
              DriverTripLocationUpdated(
                lat: pos.latitude,
                lng: pos.longitude,
                bearing: pos.heading,
              ),
            );
      },
      onError: (e) {
        debugPrint('📍 DriverActiveTripPage: location stream error: $e');
      },
    );
  }

  void _navigateToInvoice() {
    final requestId = context.read<DriverTripBloc>().state.requestId ?? '';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TripInvoicePage(
          requestId: requestId,
          isDriver: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverTripBloc, DriverTripState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.status == DriverTripStatus.tripCompleted) {
          _navigateToInvoice();
        }
        if (state.status == DriverTripStatus.cancelled) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        // Show error feedback via SnackBar
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.activeTripData != curr.activeTripData,
      builder: (context, state) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: Stack(
              children: [
                // Map
                Positioned.fill(
                  child: _DriverTripMap(
                    mapKey: _mapKey,
                    state: state,
                  ),
                ),
                // ── Dark timer overlay on map ──
                if (state.activeTripData?.phase == TripPhase.driverArrived ||
                    state.activeTripData?.phase == TripPhase.inProgress)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12.h,
                    left: 20.w,
                    right: 20.w,
                    child: WaitingTimerBanner(
                      key: ValueKey(state.activeTripData?.phase),
                      message: state.activeTripData?.phase ==
                              TripPhase.driverArrived
                          ? AppStrings.remainingWaitTime
                          : AppStrings.tripElapsedTime,
                      warningMessage:
                          state.activeTripData?.phase ==
                                  TripPhase.driverArrived
                              ? AppStrings.waitingChargeWarning
                              : null,
                      startTime: DateTime.now(),
                    ),
                  ),
                // Bottom sheet
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _DriverTripSheet(
                    state: state,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverTripMap extends StatefulWidget {
  const _DriverTripMap({
    required this.mapKey,
    required this.state,
  });

  final GlobalKey<IqMapViewState> mapKey;
  final DriverTripState state;

  @override
  State<_DriverTripMap> createState() => _DriverTripMapState();
}

class _DriverTripMapState extends State<_DriverTripMap> {
  List<LatLng>? _routePoints;

  /// Track what route we last fetched to avoid re-fetching the same route.
  String _lastRouteKey = '';

  /// Object pools — avoid re-creating Set<Marker>/Set<Polyline> on every frame.
  final MarkerPool _markerPool = MarkerPool();
  final PolylinePool _polylinePool = PolylinePool();

  @override
  void initState() {
    super.initState();
    _fetchRouteForPhase();
  }

  @override
  void didUpdateWidget(_DriverTripMap old) {
    super.didUpdateWidget(old);
    _fetchRouteForPhase();
  }

  /// Resolve which effective trip phase we are in.
  _EffectivePhase get _phase {
    final status = widget.state.status;
    switch (status) {
      case DriverTripStatus.arrivedAtPickup:
        return _EffectivePhase.arrived;
      case DriverTripStatus.tripInProgress:
        return _EffectivePhase.inProgress;
      default:
        // navigatingToPickup, loading, or any other → treat as navigating
        return _EffectivePhase.navigating;
    }
  }

  /// Fetch route depending on trip phase:
  ///  - navigating → driver current location → pickup
  ///  - inProgress → pickup → dropoff
  ///  - arrived   → no route needed
  Future<void> _fetchRouteForPhase() async {
    final req = widget.state.incomingRequest;
    if (req == null) return;

    final phase = _phase;

    if (phase == _EffectivePhase.navigating) {
      // Route: driver → pickup
      final routeKey = 'nav_${req.pickLat}_${req.pickLng}';
      if (_lastRouteKey == routeKey) return;
      _lastRouteKey = routeKey;

      // Get driver's current position
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final result = await RouteHelper.fetchRoute(
          service: sl<GoogleMapsService>(),
          originLat: pos.latitude,
          originLng: pos.longitude,
          destLat: req.pickLat,
          destLng: req.pickLng,
        );
        if (result != null && mounted) {
          setState(() => _routePoints = result.polylinePoints);
          final bounds = calculateBounds(result.polylinePoints);
          widget.mapKey.currentState?.fitBounds(bounds);
        }
      } catch (e) {
        debugPrint('🗺️ DriverTripMap: failed to get driver position: $e');
        // Fallback: just show pickup marker without route.
      }
    } else if (phase == _EffectivePhase.inProgress) {
      // Route: pickup → dropoff
      final routeKey = 'trip_${req.pickLat}_${req.dropLat}';
      if (_lastRouteKey == routeKey) return;
      _lastRouteKey = routeKey;

      if (req.pickLat == 0 || req.dropLat == 0) return;
      final result = await RouteHelper.fetchRoute(
        service: sl<GoogleMapsService>(),
        originLat: req.pickLat,
        originLng: req.pickLng,
        destLat: req.dropLat,
        destLng: req.dropLng,
      );
      if (result != null && mounted) {
        setState(() => _routePoints = result.polylinePoints);
        final bounds = calculateBounds(result.polylinePoints);
        widget.mapKey.currentState?.fitBounds(bounds);

        // Write the encoded polyline to Firebase so the passenger can
        // see the real route in real-time AND it's available at end-ride.
        final encoded = result.encodedPolyline;
        if (encoded.isNotEmpty) {
          final reqId = widget.state.requestId;
          if (reqId != null && reqId.isNotEmpty) {
            try {
              context.read<DriverTripBloc>().tripStream.updateTripNode(
                    requestId: reqId,
                    data: {'polyline': encoded},
                  );
            } catch (_) {}
          }
        }
      }
    } else {
      // arrived — clear route
      if (_routePoints != null) {
        setState(() => _routePoints = null);
        _polylinePool.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.state.incomingRequest;
    final trip = widget.state.activeTripData;
    final phase = _phase;

    if (req != null) {
      // Always show pickup marker
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(req.pickLat, req.pickLng),
        icon: MapIcons.pickup,
      ));

      // Dropoff marker — only relevant during inProgress
      if (phase == _EffectivePhase.inProgress) {
        _markerPool.upsert(Marker(
          markerId: MapMarkerIds.dropoff,
          position: LatLng(req.dropLat, req.dropLng),
          icon: MapIcons.dropoff,
        ));
      } else {
        _markerPool.remove(MapMarkerIds.dropoff.value);
      }

      // Route polyline
      final routePts = _routePoints;
      if (routePts != null && routePts.length >= 2) {
        if (phase == _EffectivePhase.navigating) {
          // Snap end to pickup
          _polylinePool.upsert(MapRouteStyle.route(points: routePts));
        } else if (phase == _EffectivePhase.inProgress) {
          final snapped = RouteHelper.snapToEndpoints(
            routePts,
            LatLng(req.pickLat, req.pickLng),
            LatLng(req.dropLat, req.dropLng),
          );
          _polylinePool.upsert(MapRouteStyle.route(points: snapped));
        }
      } else if (phase == _EffectivePhase.navigating && req.pickLat != 0) {
        // Fallback: no route yet, don't draw a bad line
      } else if (phase == _EffectivePhase.inProgress) {
        _polylinePool.upsert(MapRouteStyle.fallbackLine(
          from: LatLng(req.pickLat, req.pickLng),
          to: LatLng(req.dropLat, req.dropLng),
        ));
      }
    }

    // Driver marker from Firebase (or my-location blue dot already shows)
    if (trip != null && (trip.driverLat ?? 0) != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.driver,
        position: LatLng(trip.driverLat ?? 0.0, trip.driverLng ?? 0.0),
        icon: MapIcons.driver,
        rotation: trip.driverBearing ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    return IqMapView(
      key: widget.mapKey,
      markers: _markerPool.markers,
      polylines: _polylinePool.polylines,
      mapPadding: EdgeInsets.only(bottom: 350.h),
      myLocationEnabled: true,
    );
  }
}

enum _EffectivePhase { navigating, arrived, inProgress }

// ---------------------------------------------------------------------------
// Bottom sheet — matches old app design (on_ride_widget).
// Shows: حالة الرحلة header → coloured status badge → passenger info row
// → bordered address cards → fare + payment → phase action buttons.
// ---------------------------------------------------------------------------

class _DriverTripSheet extends StatelessWidget {
  const _DriverTripSheet({required this.state});
  final DriverTripState state;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTripData;
    final req = state.incomingRequest;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──
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

            // ── "حالة الرحلة" title ──
            Center(
              child: IqText(
                AppStrings.tripStatus,
                style: AppTypography.heading3.copyWith(
                  color: isDark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // ── Full-width coloured status badge ──
            _TripStatusBadge(status: state.status),
            SizedBox(height: 16.h),

            // ── Passenger info row ──
            if (req != null) ...[
              _PassengerInfoRow(
                name: req.userName ?? '',
                photoUrl: req.userImage,
                rating:
                    double.tryParse(req.userRating ?? '') ?? 0.0,
                totalRides: req.totalRides,
                onChat: () {
                  // Open phone dialer for passenger (chat not built yet)
                  _callPhone(context, req.userMobile);
                },
                onCall: () {
                  _callPhone(context, req.userMobile);
                },
              ),
              SizedBox(height: 16.h),

              // ── Pickup address card ──
              _BorderedAddressCard(
                address: req.pickAddress,
                iconColor: AppColors.markerGreen,
              ),
              SizedBox(height: 8.h),

              // ── Drop address card ──
              _BorderedAddressCard(
                address: req.dropAddress,
                iconColor: AppColors.markerRed,
              ),
              SizedBox(height: 16.h),

              // ── Fare + payment method ──
              _FarePaymentRow(
                amount: req.totalAmount,
                currencySymbol: req.currencySymbol,
                paymentMethod: req.paymentMethod,
              ),
              SizedBox(height: 20.h),
            ],

            // ── Phase action buttons ──
            _DriverPhaseButtons(
              status: state.status,
              requestId: state.requestId ?? '',
              trip: trip,
              incomingRequest: req,
              accumulatedDistance: state.tripDistance,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-width coloured status badge (amber / orange / green).
// ---------------------------------------------------------------------------

class _TripStatusBadge extends StatelessWidget {
  const _TripStatusBadge({required this.status});
  final DriverTripStatus status;

  String get _text {
    switch (status) {
      case DriverTripStatus.arrivedAtPickup:
        return AppStrings.driverArrived;
      case DriverTripStatus.tripInProgress:
        return AppStrings.onWayToDropoff;
      default:
        // navigatingToPickup, loading, or any other → "في الطريق"
        return AppStrings.onTheWay;
    }
  }

  Color get _bgColor {
    switch (status) {
      case DriverTripStatus.arrivedAtPickup:
        return AppColors.warning;
      case DriverTripStatus.tripInProgress:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Color get _textColor {
    switch (status) {
      case DriverTripStatus.arrivedAtPickup:
        return AppColors.white;
      case DriverTripStatus.tripInProgress:
        return AppColors.white;
      default:
        return AppColors.textDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: IqText(
        _text,
        style: AppTypography.labelLarge.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Passenger info row: avatar + name + rating + rides | chat + call buttons.
// ---------------------------------------------------------------------------

class _PassengerInfoRow extends StatelessWidget {
  const _PassengerInfoRow({
    required this.name,
    this.photoUrl,
    this.rating = 0,
    this.totalRides,
    this.onChat,
    this.onCall,
  });

  final String name;
  final String? photoUrl;
  final double rating;
  final String? totalRides;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 52.w;

    return Row(
      children: [
        // ── Avatar ──
        ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? IqImage(
                    photoUrl!,
                    fit: BoxFit.cover,
                    width: avatarSize,
                    height: avatarSize,
                  )
                : Container(
                    color: AppColors.grayLightBg,
                    child: Icon(
                      Icons.person,
                      size: avatarSize * 0.6,
                      color: AppColors.grayLight,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12.w),

        // ── Name + rating + rides ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IqText(
                name,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 16.w, color: AppColors.starFilled),
                  SizedBox(width: 2.w),
                  IqText(
                    rating.toStringAsFixed(1),
                    style: AppTypography.numberSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    dir: TextDirection.ltr,
                  ),
                  if (totalRides != null && totalRides!.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    IqText(
                      '($totalRides ${AppStrings.totalRidesCount})',
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

        // ── Chat + Call circle buttons ──
        _CircleActionBtn(
          icon: Icons.chat_bubble_outlined,
          color: AppColors.success,
          onTap: onChat,
        ),
        SizedBox(width: 8.w),
        _CircleActionBtn(
          icon: Icons.phone_outlined,
          color: AppColors.primary,
          onTap: onCall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small circle action button (chat / call).
// ---------------------------------------------------------------------------

class _CircleActionBtn extends StatelessWidget {
  const _CircleActionBtn({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 20.w, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bordered rounded address card with coloured location icon.
// ---------------------------------------------------------------------------

class _BorderedAddressCard extends StatelessWidget {
  const _BorderedAddressCard({
    required this.address,
    required this.iconColor,
  });

  final String address;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.grayBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 20.w, color: iconColor),
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

// ---------------------------------------------------------------------------
// Fare amount + payment method row.
// ---------------------------------------------------------------------------

class _FarePaymentRow extends StatelessWidget {
  const _FarePaymentRow({
    required this.amount,
    required this.currencySymbol,
    required this.paymentMethod,
  });

  final double amount;
  final String currencySymbol;
  final int paymentMethod;

  String get _paymentText {
    switch (paymentMethod) {
      case 0:
        return AppStrings.cardPayment;
      case 2:
        return AppStrings.walletPayment;
      default:
        return AppStrings.cash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fareColor = const Color(0xFF669C1A); // Old app green for fare.

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: fareColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // Label + amount
          IqText(
            '${AppStrings.rideFare} : ',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          IqText(
            '$currencySymbol ${amount.toStringAsFixed(0)}',
            style: AppTypography.numberLarge.copyWith(
              color: fareColor,
              fontWeight: FontWeight.w700,
            ),
            dir: TextDirection.ltr,
          ),
          const Spacer(),
          // Payment method
          IqText(
            _paymentText,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase-specific action buttons (cancel + arrived / start / end).
// ---------------------------------------------------------------------------

class _DriverPhaseButtons extends StatelessWidget {
  const _DriverPhaseButtons({
    required this.status,
    required this.requestId,
    this.trip,
    this.incomingRequest,
    this.accumulatedDistance = 0.0,
  });

  final DriverTripStatus status;
  final String requestId;
  final ActiveTripModel? trip;
  final IncomingRequestModel? incomingRequest;
  final double accumulatedDistance;

  /// Helper to build cancel + primary action row.
  Widget _cancelAndAction(BuildContext context, String actionText, VoidCallback onAction) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          height: 52.h,
          child: OutlinedButton(
            onPressed: () => _showDriverCancelSheet(context, requestId),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.grayBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000.r),
              ),
            ),
            child: IqText(
              AppStrings.cancel,
              style: AppTypography.button.copyWith(color: AppColors.textDark),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SizedBox(
            height: 52.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_double_arrow_right_rounded, size: 22.w),
                  SizedBox(width: 6.w),
                  IqText(actionText, style: AppTypography.button),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DriverTripStatus.arrivedAtPickup:
        // For delivery trips with shipment-load enabled, show proof
        // upload page before starting the ride.
        if (trip?.isDelivery == true && trip?.enableShipmentLoad == true) {
          return _cancelAndAction(
            context,
            AppStrings.pickGoods,
            () => _handleShipmentLoadBeforeStart(context),
          );
        }
        return _cancelAndAction(context, AppStrings.startTrip, () {
          context.read<DriverTripBloc>().add(
            DriverTripStartRide(
              requestId: requestId,
              pickLat: incomingRequest?.pickLat ?? 0,
              pickLng: incomingRequest?.pickLng ?? 0,
            ),
          );
        });

      case DriverTripStatus.tripInProgress:
        // For delivery trips, the end-trip flow may include unload proof
        // and/or customer signature before actually ending the ride.
        final bool isDeliveryTrip = trip?.isDelivery == true;
        final String endLabel = isDeliveryTrip
            ? AppStrings.dispatchGoods
            : AppStrings.endTrip;

        return SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              if (isDeliveryTrip) {
                _handleDeliveryEndFlow(context);
              } else {
                _endRide(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000.r),
              ),
            ),
            child: IqText(
              endLabel,
              style: AppTypography.button.copyWith(color: AppColors.white),
            ),
          ),
        );

      default:
        // Default: show navigatingToPickup buttons (cancel + وصلت الرحلة)
        // This covers loading / any transient status.
        return _cancelAndAction(context, AppStrings.tripArrived, () {
          context.read<DriverTripBloc>().add(
            DriverTripMarkArrived(requestId),
          );
        });
    }
  }

  // ─── Delivery Flow Helpers ───

  void _endRide(BuildContext context) {
    context.read<DriverTripBloc>().add(
          DriverTripEndRide(
            requestId: requestId,
            dropLat: incomingRequest?.dropLat ?? 0,
            dropLng: incomingRequest?.dropLng ?? 0,
            dropAddress: incomingRequest?.dropAddress ?? '',
            distance: accumulatedDistance > 0
                ? accumulatedDistance
                : (trip?.distance ?? 0),
            polyLine: trip?.polyline ?? '',
          ),
        );
  }

  /// Before starting ride: upload shipment load proof → then start ride.
  Future<void> _handleShipmentLoadBeforeStart(BuildContext context) async {
    final proofPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ShipmentProofPage(isBefore: true),
      ),
    );
    if (proofPath == null || !context.mounted) return;

    // Upload the proof image
    final bloc = context.read<DriverTripBloc>();
    bloc.add(DriverTripUploadShipmentProof(
      requestId: requestId,
      imagePath: proofPath,
      isBefore: true,
    ));

    // Start the ride after proof uploaded
    bloc.add(DriverTripStartRide(
      requestId: requestId,
      pickLat: incomingRequest?.pickLat ?? 0,
      pickLng: incomingRequest?.pickLng ?? 0,
    ));
  }

  /// Before ending ride: optionally upload unload proof → optionally
  /// get customer signature → upload both → end ride.
  Future<void> _handleDeliveryEndFlow(BuildContext context) async {
    final bloc = context.read<DriverTripBloc>();

    // Step 1: Shipment unload proof (if feature enabled)
    if (trip?.enableShipmentUnload == true) {
      final proofPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const ShipmentProofPage(isBefore: false),
        ),
      );
      if (proofPath == null || !context.mounted) return;

      bloc.add(DriverTripUploadShipmentProof(
        requestId: requestId,
        imagePath: proofPath,
        isBefore: false,
      ));
    }

    if (!context.mounted) return;

    // Step 2: Customer digital signature (if feature enabled)
    if (trip?.enableDigitalSignature == true) {
      final sigPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const CustomerSignaturePage(),
        ),
      );
      if (sigPath == null || !context.mounted) return;

      // Upload signature as unload proof
      bloc.add(DriverTripUploadShipmentProof(
        requestId: requestId,
        imagePath: sigPath,
        isBefore: false,
      ));
    }

    if (!context.mounted) return;

    // Step 3: End the ride
    _endRide(context);
  }
}

void _showDriverCancelSheet(BuildContext context, String requestId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => CancelReasonsSheet(
      title: AppStrings.cancelReason,
      reasons: [
        CancelReasonModel(
          id: 1,
          reason: AppStrings.vehicleIssueOrEmergency,
          userType: 'driver',
          arrivalStatus: 'before',
        ),
        CancelReasonModel(
          id: 2,
          reason: AppStrings.passengerNotResponding,
          userType: 'driver',
          arrivalStatus: 'before',
        ),
        CancelReasonModel(
          id: 3,
          reason: AppStrings.cancelReasonOther,
          userType: 'driver',
          arrivalStatus: 'before',
        ),
      ],
      onConfirm: (reason, custom) {
        Navigator.pop(context);
        context.read<DriverTripBloc>().add(
              DriverTripCancelRequested(
                requestId: requestId,
                reason: reason,
                customReason: custom,
              ),
            );
      },
    ),
  );
}

/// Opens the phone dialer with the given phone number.
Future<void> _callPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('رقم الهاتف غير متوفر')),
    );
    return;
  }
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
