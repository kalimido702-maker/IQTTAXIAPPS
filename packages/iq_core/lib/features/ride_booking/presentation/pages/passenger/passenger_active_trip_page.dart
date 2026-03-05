import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/google_maps_service.dart';
import '../../../../../core/services/map_performance.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_image.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../home/presentation/bloc/passenger_home_bloc.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/cancel_reason_model.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import '../../bloc/passenger/passenger_trip_event.dart';
import '../../bloc/passenger/passenger_trip_state.dart';
import '../../widgets/cancel_reasons_sheet.dart';
import '../../widgets/fake_car_markers.dart';
import '../../widgets/searching_driver_animation.dart';
import '../../widgets/trip_action_buttons.dart';
import 'trip_invoice_page.dart';

/// The main active trip page for passengers.
/// Displays different content based on trip phase:
/// - Searching for driver (pulse animation)
/// - Driver on way (driver info + ETA)
/// - Driver arrived (driver info + waiting banner)
/// - Trip in progress (route + driver info + action buttons)
///
/// Figma: 7:2182, 7:2370, 7:2488, 7:2624
class PassengerActiveTripPage extends StatelessWidget {
  const PassengerActiveTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<PassengerTripBloc>(),
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PassengerTripBloc, PassengerTripState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        // Navigate to invoice on completion
        if (state.status == PassengerTripStatus.tripCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TripInvoicePage(
                requestId: state.requestId ?? '',
              ),
            ),
          );
        }
        // Pop on cancel
        if (state.status == PassengerTripStatus.cancelled) {
          Navigator.of(context).popUntil((route) => route.isFirst);
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
                  child: _TripMap(
                    mapKey: _mapKey,
                    state: state,
                  ),
                ),

                // Content overlay
                if (state.status == PassengerTripStatus.searchingDriver)
                  _SearchingOverlay(state: state)
                else if (state.status == PassengerTripStatus.cancelling)
                  const _CancellingOverlay()
                else
                  _ActiveTripSheet(
                    state: state,
                    mapKey: _mapKey,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Map widget that updates markers/polylines based on trip state.
/// Decodes Firebase polyline or fetches Google Directions for real routes.
class _TripMap extends StatefulWidget {
  const _TripMap({
    required this.mapKey,
    required this.state,
  });

  final GlobalKey<IqMapViewState> mapKey;
  final PassengerTripState state;

  @override
  State<_TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<_TripMap> {
  List<LatLng>? _routePoints;
  String? _lastPolylineSource; // Track what we last decoded to avoid re-work.

  /// Object pools — avoid re-creating Set<Marker>/Set<Polyline> on every frame.
  final MarkerPool _markerPool = MarkerPool();
  final PolylinePool _polylinePool = PolylinePool();

  /// Ghost car markers shown while searching for a driver.
  FakeCarMarkersController? _fakeCarsController;
  Set<Marker> _fakeCarsMarkers = {};

  @override
  void didUpdateWidget(_TripMap old) {
    super.didUpdateWidget(old);
    _updateRoute();
    _updateFakeCars();
  }

  @override
  void initState() {
    super.initState();
    _updateRoute();
    _updateFakeCars();
  }

  @override
  void dispose() {
    _fakeCarsController?.dispose();
    super.dispose();
  }

  /// Start or stop fake car markers based on trip state.
  void _updateFakeCars() {
    final isSearching =
        widget.state.status == PassengerTripStatus.searchingDriver;

    if (isSearching && _fakeCarsController == null && widget.state.pickLat != 0) {
      _fakeCarsController = FakeCarMarkersController(
        center: LatLng(widget.state.pickLat, widget.state.pickLng),
      );
      _fakeCarsController!.start((markers) {
        if (mounted) {
          setState(() => _fakeCarsMarkers = markers);
        }
      });
    } else if (!isSearching && _fakeCarsController != null) {
      _fakeCarsController!.stop();
      _fakeCarsController!.dispose();
      _fakeCarsController = null;
      _fakeCarsMarkers = {};
    }
  }

  void _updateRoute() {
    final trip = widget.state.activeTripData;

    // 1) If Firebase has an encoded polyline, decode it.
    if (trip?.polyline != null &&
        trip!.polyline!.isNotEmpty &&
        trip.polyline != _lastPolylineSource) {
      _lastPolylineSource = trip.polyline;
      final decoded = RouteHelper.decodeAndSimplify(trip.polyline!);
      if (decoded.isNotEmpty) {
        setState(() => _routePoints = decoded);
        return;
      }
    }

    // 2) If no polyline from Firebase and we have no route yet,
    //    fetch from Google Directions.
    if (_routePoints == null &&
        widget.state.pickLat != 0 &&
        widget.state.dropLat != 0) {
      _fetchDirections();
    }
  }

  Future<void> _fetchDirections() async {
    final result = await RouteHelper.fetchRoute(
      service: sl<GoogleMapsService>(),
      originLat: widget.state.pickLat,
      originLng: widget.state.pickLng,
      destLat: widget.state.dropLat,
      destLng: widget.state.dropLng,
    );
    if (result != null && mounted) {
      setState(() {
        _routePoints = result.polylinePoints;
        _lastPolylineSource = result.encodedPolyline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.state.activeTripData;

    // Pickup marker
    if (widget.state.pickLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(widget.state.pickLat, widget.state.pickLng),
        icon: MapIcons.pickup,
      ));
    }

    // Dropoff marker
    if (widget.state.dropLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(widget.state.dropLat, widget.state.dropLng),
        icon: MapIcons.dropoff,
      ));
    }

    // Driver marker
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

    // Route polyline — use decoded Google route if available.
    final routePts = _routePoints;
    final pickup = LatLng(widget.state.pickLat, widget.state.pickLng);
    final dropoff = LatLng(widget.state.dropLat, widget.state.dropLng);
    if (routePts != null && routePts.length >= 2) {
      final snapped = RouteHelper.snapToEndpoints(routePts, pickup, dropoff);
      _polylinePool.upsert(MapRouteStyle.route(points: snapped));
    } else if (widget.state.pickLat != 0 && widget.state.dropLat != 0) {
      // Fallback straight line
      _polylinePool.upsert(MapRouteStyle.fallbackLine(
        from: LatLng(widget.state.pickLat, widget.state.pickLng),
        to: LatLng(widget.state.dropLat, widget.state.dropLng),
      ));
    }

    return IqMapView(
      key: widget.mapKey,
      initialTarget: widget.state.pickLat != 0
          ? LatLng(widget.state.pickLat, widget.state.pickLng)
          : null,
      markers: {..._markerPool.markers, ..._fakeCarsMarkers},
      polylines: _polylinePool.polylines,
      mapPadding: EdgeInsets.only(bottom: 320.h),
    );
  }
}

/// Searching for driver — bottom sheet over the map (Figma 7:2182).
class _SearchingOverlay extends StatelessWidget {
  const _SearchingOverlay({required this.state});
  final PassengerTripState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SearchingDriverSheet(
        onCancel: () {
          HapticFeedback.mediumImpact();
          _showCancelConfirmation(context, state.requestId ?? '');
        },
        onAutoCancel: () {
          // Auto-cancel timeout: directly cancel trip without showing dialog
          context.read<PassengerTripBloc>().add(
            const PassengerTripCancelRequested(
              reason: 'لم يتم العثور على سائق',
              isTimerCancel: true,
            ),
          );
        },
      ),
    );
  }
}

/// Loading overlay shown while cancel API is in progress.
class _CancellingOverlay extends StatelessWidget {
  const _CancellingOverlay();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                IqText(
                  AppStrings.cancellingTrip,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for active trip phases (driver on way, arrived, in progress).
// Matches the old-app design with حالة الرحلة header, coloured status badge,
// driver info, bordered address cards, fare + payment, and cancel button.
// ---------------------------------------------------------------------------

class _ActiveTripSheet extends StatelessWidget {
  const _ActiveTripSheet({
    required this.state,
    required this.mapKey,
  });

  final PassengerTripState state;
  final GlobalKey<IqMapViewState> mapKey;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTripData;
    if (trip == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
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

              // ── Full-width status badge ──
              _PassengerStatusBadge(phase: trip.phase),
              SizedBox(height: 16.h),

              // ── Waiting charge warning (driver arrived) ──
              if (trip.phase == TripPhase.driverArrived)
                _WaitingBanner(),

              // ── Driver info ──
              _DriverRow(
                name: trip.driverName ?? '',
                photoUrl: trip.driverProfilePic,
                rating: trip.driverRatingValue,
                vehicleInfo: trip.vehicleTypeName,
                plateNumber: trip.vehicleNumber,
                onChat: () {
                  _callPhone(context, trip.driverMobile);
                },
                onCall: () {
                  _callPhone(context, trip.driverMobile);
                },
              ),
              SizedBox(height: 16.h),

              // ── Addresses in bordered cards ──
              _BorderedAddressCard(
                address: state.pickAddress,
                iconColor: AppColors.markerGreen,
              ),
              SizedBox(height: 8.h),
              _BorderedAddressCard(
                address: state.dropAddress,
                iconColor: AppColors.markerRed,
              ),
              SizedBox(height: 16.h),

              // ── Fare + payment ──
              _FarePaymentRow(
                amount: trip.totalAmount,
                currencySymbol: trip.currencySymbol,
                paymentMethod: trip.paymentMethod,
              ),

              // ── Action buttons (in progress) ──
              if (trip.phase == TripPhase.inProgress) ...[
                SizedBox(height: 16.h),
                TripActionButtons(
                  onLocate: () {
                    if ((trip.driverLat ?? 0) != 0) {
                      mapKey.currentState?.animateTo(
                        LatLng(trip.driverLat ?? 0.0, trip.driverLng ?? 0.0),
                      );
                    }
                  },
                  onShareTrip: () {
                    _shareTrip(
                      context,
                      driverName: trip.driverName ?? '',
                      pickAddress: state.pickAddress,
                      dropAddress: state.dropAddress,
                    );
                  },
                  onSos: () {
                    _callSos(context);
                  },
                ),
              ],

              // ── Cancel (before trip starts) ──
              if (trip.phase != TripPhase.inProgress) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: () => _showCancelConfirmation(
                      context,
                      state.requestId ?? '',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1000.r),
                      ),
                    ),
                    child: IqText(
                      AppStrings.cancelTrip,
                      style: AppTypography.button.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-width coloured status badge for passenger trip phases.
// ---------------------------------------------------------------------------

class _PassengerStatusBadge extends StatelessWidget {
  const _PassengerStatusBadge({required this.phase});
  final TripPhase phase;

  String get _text {
    switch (phase) {
      case TripPhase.driverOnWay:
        return AppStrings.driverOnWay;
      case TripPhase.driverArrived:
        return AppStrings.driverArrived;
      case TripPhase.inProgress:
        return AppStrings.arrivingToDestination;
      default:
        return '';
    }
  }

  Color get _bgColor {
    switch (phase) {
      case TripPhase.driverOnWay:
        return AppColors.primary;
      case TripPhase.driverArrived:
        return AppColors.warning;
      case TripPhase.inProgress:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Color get _textColor {
    switch (phase) {
      case TripPhase.driverOnWay:
        return AppColors.textDark;
      case TripPhase.driverArrived:
        return AppColors.white;
      case TripPhase.inProgress:
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
// Driver info row with avatar, name, rating, vehicle, chat/call buttons.
// ---------------------------------------------------------------------------

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.name,
    this.photoUrl,
    this.rating = 0,
    this.vehicleInfo,
    this.plateNumber,
    this.onChat,
    this.onCall,
  });

  final String name;
  final String? photoUrl;
  final double rating;
  final String? vehicleInfo;
  final String? plateNumber;
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

        // ── Name + rating + vehicle ──
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
                  if (vehicleInfo != null && vehicleInfo!.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: const BoxDecoration(
                        color: AppColors.grayLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: IqText(
                        vehicleInfo!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (plateNumber != null && plateNumber!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.grayLightBg,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: IqText(
                    plateNumber!,
                    style: AppTypography.numberSmall.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    dir: TextDirection.ltr,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Chat + Call ──
        _PCircleActionBtn(
          icon: Icons.chat_bubble_outlined,
          color: AppColors.success,
          onTap: onChat,
        ),
        SizedBox(width: 8.w),
        _PCircleActionBtn(
          icon: Icons.phone_outlined,
          color: AppColors.primary,
          onTap: onCall,
        ),
      ],
    );
  }
}

class _PCircleActionBtn extends StatelessWidget {
  const _PCircleActionBtn({
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
// Bordered rounded address card.
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
          color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
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
// Fare + payment method row.
// ---------------------------------------------------------------------------

class _FarePaymentRow extends StatelessWidget {
  const _FarePaymentRow({
    required this.amount,
    required this.currencySymbol,
    this.paymentMethod,
  });

  final double amount;
  final String currencySymbol;
  final String? paymentMethod;

  String get _paymentText {
    if (paymentMethod == null || paymentMethod!.isEmpty) {
      return AppStrings.cash;
    }
    final lower = paymentMethod!.toLowerCase();
    if (lower.contains('wallet')) return AppStrings.walletPayment;
    if (lower.contains('card')) return AppStrings.cardPayment;
    return AppStrings.cash;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const fareColor = Color(0xFF669C1A);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: fareColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
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

class _WaitingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18.w, color: AppColors.warning),
          SizedBox(width: 8.w),
          Expanded(
            child: IqText(
              AppStrings.waitingChargeWarning,
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prevents multiple cancel dialogs from stacking.
bool _cancelDialogOpen = false;

/// Shows cancel confirmation dialog with reasons.
void _showCancelConfirmation(BuildContext context, String requestId) {
  // Guard: prevent multiple dialogs from appearing simultaneously
  if (_cancelDialogOpen) return;
  _cancelDialogOpen = true;

  final bloc = context.read<PassengerTripBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => CancelReasonsSheet(
      reasons: const [
        CancelReasonModel(id: 1, reason: AppStrings.cancelReasonChangedMind, userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 2, reason: AppStrings.cancelReasonDriverFar, userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 3, reason: AppStrings.cancelReasonFoundOther, userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 4, reason: AppStrings.cancelReasonMistake, userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 5, reason: AppStrings.cancelReasonOther, userType: 'user', arrivalStatus: 'before'),
      ],
      onConfirm: (reason, custom) {
        _cancelDialogOpen = false;
        Navigator.pop(context);
        bloc.add(PassengerTripCancelRequested(reason: reason));
      },
    ),
  ).whenComplete(() => _cancelDialogOpen = false);
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

/// Share trip details via the system share sheet.
Future<void> _shareTrip(
  BuildContext context, {
  required String driverName,
  required String pickAddress,
  required String dropAddress,
}) async {
  final text = '${AppStrings.shareTrip}\n'
      '${AppStrings.driver}: $driverName\n'
      'من: $pickAddress\n'
      'إلى: $dropAddress';
  await Share.share(text);
}

/// Call the admin SOS phone number.
Future<void> _callSos(BuildContext context) async {
  String? phone;
  try {
    final homeData = context.read<PassengerHomeBloc>().state.homeData;
    phone = homeData?.adminSosPhone;
  } catch (_) {}

  if (phone == null || phone.isEmpty) {
    // Fallback to 911
    phone = '911';
  }
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
