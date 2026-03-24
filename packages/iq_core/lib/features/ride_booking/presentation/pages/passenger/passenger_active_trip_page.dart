import 'package:firebase_database/firebase_database.dart';
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
import '../../../../../core/utils/car_color_helper.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_image.dart';
import '../../../../../core/widgets/iq_map_view.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../home/presentation/bloc/passenger_home_bloc.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/cancel_reason_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import '../../bloc/passenger/passenger_trip_event.dart';
import '../../bloc/passenger/passenger_trip_state.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../trip_chat/trip_chat.dart';
import '../../widgets/cancel_reasons_sheet.dart';
import '../../widgets/fake_car_markers.dart';
import '../../widgets/ride_bottom_sheets.dart';
import '../../widgets/searching_driver_animation.dart';
import '../../widgets/trip_action_buttons.dart';
import 'map_picker_page.dart';
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
          prev.status != curr.status ||
          prev.activeTripData != curr.activeTripData ||
          prev.dropAddress != curr.dropAddress ||
          prev.dropLat != curr.dropLat ||
          prev.dropLng != curr.dropLng,
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

                // My location FAB
                Positioned(
                  bottom: 340.h,
                  left: 16.w,
                  child: SizedBox(
                    width: 48.w,
                    height: 48.w,
                    child: FloatingActionButton(
                      heroTag: 'my_location_trip',
                      onPressed: () =>
                          _mapKey.currentState?.goToMyLocation(),
                      backgroundColor: AppColors.white,
                      elevation: 4,
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 24.w,
                      ),
                    ),
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

    // If the drop location changed (destination change), reset the route
    // so that it re-fetches directions for the new drop coordinates.
    if (old.state.dropLat != widget.state.dropLat ||
        old.state.dropLng != widget.state.dropLng) {
      _routePoints = null;
      _lastPolylineSource = null;
    }

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
    final phase = trip?.phase;
    final isDriverApproaching =
        phase == TripPhase.driverOnWay || phase == TripPhase.driverArrived;
    final hasDriverPos = trip != null && (trip.driverLat ?? 0) != 0;

    if (trip != null && !hasDriverPos) {
      debugPrint('⚠️ [Map] Driver lat/lng missing: lat=${trip.driverLat}, lng=${trip.driverLng}, phase=${trip.phase}');
    }

    // ── Markers ──

    // Total points = pickup + stops + dropoff → numbered 1..N.
    final stops = trip?.stops ?? const [];
    final totalPoints = 2 + stops.length; // 1=pickup, 2..N-1=stops, N=dropoff

    // During driver-on-way/arrived: show only pickup + driver car.
    // During in-progress: show pickup + stops + dropoff + driver car.
    // During searching: show pickup + stops + dropoff (fake cars handled separately).
    if (widget.state.pickLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(widget.state.pickLat, widget.state.pickLng),
        icon: MapIcons.numberedSync(1),
      ));
    }

    if (!isDriverApproaching && widget.state.dropLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(widget.state.dropLat, widget.state.dropLng),
        icon: MapIcons.numberedSync(totalPoints),
      ));
    } else if (isDriverApproaching) {
      // Remove dropoff marker during driver-approaching phase.
      _markerPool.remove(MapMarkerIds.dropoff.value);
    }

    // Intermediate stop markers (numbered 2..N-1)
    if (!isDriverApproaching) {
      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        if (stop.lat != 0 && stop.lng != 0) {
          _markerPool.upsert(Marker(
            markerId: MapMarkerIds.stop(i),
            position: LatLng(stop.lat, stop.lng),
            icon: MapIcons.numberedSync(i + 2),
          ));
        }
      }
    }

    // Driver car marker
    if (hasDriverPos) {
      debugPrint('🚗 [Map] Driver pos: ${trip.driverLat}, ${trip.driverLng}, bearing: ${trip.driverBearing}');
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.driver,
        position: LatLng(trip.driverLat ?? 0.0, trip.driverLng ?? 0.0),
        icon: MapIcons.car,
        rotation: trip.driverBearing ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    // ── Polyline ──

    if (isDriverApproaching && hasDriverPos) {
      // Driver → Pickup polyline
      final driverPos = LatLng(trip.driverLat!, trip.driverLng!);
      final pickupPos = LatLng(widget.state.pickLat, widget.state.pickLng);
      _polylinePool.upsert(MapRouteStyle.fallbackLine(
        from: driverPos,
        to: pickupPos,
      ));
    } else if (isDriverApproaching && !hasDriverPos) {
      // Driver approaching but no position yet — clear any old polyline.
      _polylinePool.clear();
    } else {
      // Pickup → Dropoff polyline
      final routePts = _routePoints;
      final pickup = LatLng(widget.state.pickLat, widget.state.pickLng);
      final dropoff = LatLng(widget.state.dropLat, widget.state.dropLng);
      if (routePts != null && routePts.length >= 2) {
        final snapped = RouteHelper.snapToEndpoints(routePts, pickup, dropoff);
        _polylinePool.upsert(MapRouteStyle.route(points: snapped));
      } else if (widget.state.pickLat != 0 && widget.state.dropLat != 0) {
        _polylinePool.upsert(MapRouteStyle.fallbackLine(
          from: pickup,
          to: dropoff,
        ));
      }
    }

    return IqMapView(
      key: widget.mapKey,
      initialTarget: widget.state.pickLat != 0
          ? LatLng(widget.state.pickLat, widget.state.pickLng)
          : null,
      markers: {..._markerPool.markers, ..._fakeCarsMarkers},
      polylines: _polylinePool.polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
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
            PassengerTripCancelRequested(
              reason: AppStrings.driverNotFound,
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
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
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

                // ── Phase-specific ETA header ──
                _TripPhaseHeader(trip: trip),
                SizedBox(height: 16.h),

                // ── Waiting charge warning (driver arrived) ──
                if (trip.phase == TripPhase.driverArrived) _WaitingBanner(),

                // ── Driver info ──
                _DriverRow(
                  name: trip.driverName ?? '',
                  photoUrl: trip.driverProfilePic,
                  rating: trip.driverRatingValue,
                  vehicleInfo: trip.vehicleTypeName,
                  plateNumber: trip.vehicleNumber,
                  vehicleColor: trip.vehicleColor,
                  onChat: trip.driverMobile != null &&
                          trip.driverMobile!.isNotEmpty
                      ? () => _openTripChat(
                            context,
                            requestId: state.requestId ?? '',
                            otherPartyName: trip.driverName ?? '',
                            otherPartyPhotoUrl: trip.driverProfilePic,
                          )
                      : null,
                  onCall: trip.driverMobile != null &&
                          trip.driverMobile!.isNotEmpty
                      ? () => _callPhone(context, trip.driverMobile)
                      : null,
                ),
                SizedBox(height: 16.h),

                // ── Pickup address ──
                _BorderedAddressCard(
                  address: state.pickAddress,
                  iconColor: AppColors.markerRed,
                ),
                SizedBox(height: 8.h),

                // ── Drop address with change button ──
                _BorderedAddressCard(
                  address: state.dropAddress,
                  iconColor: AppColors.circleBlue,
                  showChange: true,
                  onChangeTap: () => _changeDropLocation(
                    context,
                    currentDropLat: state.dropLat,
                    currentDropLng: state.dropLng,
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Payment method ──
                _PaymentMethodRow(
                  paymentMethod: trip.paymentMethod,
                  onTap: () => _showChangePaymentSheet(
                    context,
                    state.requestId ?? '',
                    currentPayment: int.tryParse(trip.paymentMethod ?? '1') ?? 1,
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Action buttons (in progress) ──
                if (trip.phase == TripPhase.inProgress) ...[
                  TripActionButtons(
                    onLocate: () {
                      if ((trip.driverLat ?? 0) != 0) {
                        mapKey.currentState?.animateTo(
                          LatLng(
                              trip.driverLat ?? 0.0, trip.driverLng ?? 0.0),
                        );
                      }
                    },
                    onShareTrip: () => _shareTrip(
                      context,
                      driverName: trip.driverName ?? '',
                      pickAddress: state.pickAddress,
                      dropAddress: state.dropAddress,
                    ),
                    onSos: () => _callSos(context),
                  ),
                ],

                // ── Bottom: Cancel + Fare (before trip starts) ──
                if (trip.phase != TripPhase.inProgress) ...[
                  _CancelFareRow(
                    fareAmount: trip.totalAmount,
                    currencySymbol: trip.currencySymbol,
                    onCancel: () => _showCancelConfirmation(
                      context,
                      state.requestId ?? '',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase-specific header: ETA for on-way, status text for arrived/in-progress.
// ---------------------------------------------------------------------------

class _TripPhaseHeader extends StatelessWidget {
  const _TripPhaseHeader({required this.trip});
  final ActiveTripModel trip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (trip.phase) {
      case TripPhase.driverOnWay:
        // Show ETA: "سيصلك السائق خلال X دقائق"
        final minutes =
            (trip.pickupDuration > 0) ? trip.pickupDuration.toInt() : 1;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Center(
            child: Text.rich(
              TextSpan(
                style: AppTypography.heading2.copyWith(
                  color: isDark ? AppColors.white : AppColors.textDark,
                ),
                children: [
                  TextSpan(text: '${AppStrings.driverArrivingIn} '),
                  TextSpan(
                    text: '$minutes',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: ' ${AppStrings.minutesPlural}'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case TripPhase.driverArrived:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Center(
            child: IqText(
              AppStrings.driverArrived,
              style: AppTypography.heading3.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );

      case TripPhase.inProgress:
        final etaMinutes =
            trip.duration > 0 ? trip.duration.ceil() : null;
        final distKm = trip.distance > 0 ? trip.distance : null;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IqText(
                AppStrings.onWayToDropoff,
                style: AppTypography.heading3.copyWith(
                  color: isDark ? AppColors.white : AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (etaMinutes != null || distKm != null) ...[
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (etaMinutes != null) ...[
                      Icon(Icons.access_time_rounded,
                          size: 16.w, color: AppColors.primaryDark),
                      SizedBox(width: 4.w),
                      IqText(
                        '$etaMinutes ${AppStrings.minutesPlural}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (etaMinutes != null && distKm != null)
                      SizedBox(width: 16.w),
                    if (distKm != null) ...[
                      Icon(Icons.straighten_rounded,
                          size: 16.w, color: AppColors.primaryDark),
                      SizedBox(width: 4.w),
                      IqText(
                        '${distKm.toStringAsFixed(1)} ${AppStrings.km}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                        dir: TextDirection.ltr,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
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
    this.vehicleColor,
    this.onChat,
    this.onCall,
  });

  final String name;
  final String? photoUrl;
  final double rating;
  final String? vehicleInfo;
  final String? plateNumber;
  final String? vehicleColor;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  /// Try to parse a vehicle colour name into a Flutter [Color].
  Color? get _parsedColor => tryGetCarColor(vehicleColor);

  @override
  Widget build(BuildContext context) {
    final avatarSize = 52.w;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

        // ── Name + rating + vehicle info ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver name
              Row(
                children: [
                  IqText(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.white : AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: 8.h),
                  
                  // Rating
                  Row(
                    children: [
                      IqText(
                        rating.toStringAsFixed(1),
                        style: AppTypography.numberSmall.copyWith(
                          color: isDark ? AppColors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        dir: TextDirection.ltr,
                      ),
                      SizedBox(width: 2.w),
                      Icon(Icons.star_rounded,
                          size: 16.w, color: AppColors.starFilled),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 4.h),

              // Vehicle make + plate number + color dot
              Row(
                children: [
                  if (vehicleInfo != null && vehicleInfo!.isNotEmpty) ...[
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
                  if (plateNumber != null && plateNumber!.isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInputBg
                            : AppColors.grayLightBg,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: IqText(
                        plateNumber!,
                        style: AppTypography.numberSmall.copyWith(
                          color: isDark ? AppColors.white : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                        dir: TextDirection.ltr,
                      ),
                    ),
                  ],
                  if (_parsedColor != null) ...[
                    SizedBox(width: 6.w),
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: _parsedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.grayBorder,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Chat + Call ──
        if (onCall != null) ...[
          _PCircleActionBtn(
            icon: Icons.phone_outlined,
            color: AppColors.primary,
            onTap: onCall,
          ),
          SizedBox(width: 8.w),
        ],
        if (onChat != null)
          _PCircleActionBtn(
            icon: Icons.chat_bubble_outlined,
            color: AppColors.primary,
            onTap: onChat,
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
          color: color,
          border: Border.all(color: color),
        ),
        child: Icon(icon, size: 20.w, color: AppColors.black),
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
    this.showChange = false,
    this.onChangeTap,
  });

  final String address;
  final Color iconColor;
  final bool showChange;
  final VoidCallback? onChangeTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(30.r),
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
          if (showChange) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onChangeTap == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onChangeTap!();
                    },
              child: IqText(
                AppStrings.changeText,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment method row — tappable to change payment.
// ---------------------------------------------------------------------------

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    this.paymentMethod,
    this.onTap,
  });

  final String? paymentMethod;
  final VoidCallback? onTap;

  String get _paymentLabel {
    if (paymentMethod == null || paymentMethod!.isEmpty) {
      return AppStrings.cash;
    }
    final lower = paymentMethod!.toLowerCase().trim();
    // Handle integer payment_opt: 1=cash, 2=wallet, 3+=card
    if (lower == '1') return AppStrings.cash;
    if (lower == '2') return AppStrings.walletPayment;
    if (lower.contains('wallet')) return AppStrings.walletPayment;
    if (lower.contains('card')) return AppStrings.cardPayment;
    return AppStrings.cash;
  }

  IconData get _paymentIcon {
    if (paymentMethod == null || paymentMethod!.isEmpty) {
      return Icons.payments_outlined;
    }
    final lower = paymentMethod!.toLowerCase().trim();
    if (lower == '2' || lower.contains('wallet')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lower.contains('card')) return Icons.credit_card;
    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(_paymentIcon, size: 22.w, color: AppColors.success),
            SizedBox(width: 10.w),
            IqText(
              _paymentLabel,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IqText(
              AppStrings.changePaymentMethod,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_left, size: 18.w, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cancel button + fare amount row at the bottom.
// ---------------------------------------------------------------------------

class _CancelFareRow extends StatelessWidget {
  const _CancelFareRow({
    required this.fareAmount,
    required this.currencySymbol,
    required this.onCancel,
  });

  final double fareAmount;
  final String currencySymbol;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Fare amount (start = right in RTL)
        IqText(
          '${fareAmount.toStringAsFixed(0)} $currencySymbol',
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w800,
          ),
          dir: TextDirection.ltr,
        ),
        const Spacer(),
        // Cancel button (end = left in RTL)
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1000.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: IqText(
            AppStrings.cancelTrip,
            style: AppTypography.button.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
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
        color: AppColors.transparent,
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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prevents multiple cancel dialogs from stacking.
bool _cancelDialogOpen = false;

/// Navigate to the map picker and dispatch change-drop event on return.
Future<void> _changeDropLocation(
  BuildContext context, {
  required double currentDropLat,
  required double currentDropLng,
}) async {
  final result = await Navigator.push<MapPickResult>(
    context,
    MaterialPageRoute(
      builder: (_) => MapPickerPage(
        initialLat: currentDropLat,
        initialLng: currentDropLng,
      ),
    ),
  );

  if (result != null && context.mounted) {
    context.read<PassengerTripBloc>().add(
      PassengerTripChangeDropRequested(
        dropLat: result.lat,
        dropLng: result.lng,
        dropAddress: result.address,
      ),
    );
  }
}

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
      reasons: [
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

/// Shows the shared payment method sheet and calls the change-payment API.
Future<void> _showChangePaymentSheet(
  BuildContext context,
  String requestId, {
  int currentPayment = 1,
}) async {
  // Parse current payment from the trip's paymentMethod string
  final result = await showPaymentMethodSheet(
    context,
    currentPayment: currentPayment,
  );
  if (result != null && context.mounted) {
    final apiResult = await sl<BookingRepository>().changePaymentMethod(
      requestId: requestId,
      paymentOpt: result,
    );
    if (context.mounted) {
      apiResult.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        ),
        (_) {
          // Update Firebase so the stream pushes the new payment method
          // to ActiveTripModel.paymentMethod → UI rebuilds.
          FirebaseDatabase.instance
              .ref('requests')
              .child(requestId)
              .update({'payment_opt': result.toString()});
        },
      );
    }
  }
}

/// Opens the trip chat page between passenger and driver.
void _openTripChat(
  BuildContext context, {
  required String requestId,
  required String otherPartyName,
  String? otherPartyPhotoUrl,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => TripChatBloc(
          repository: TripChatRepositoryImpl(
            dataSource: TripChatDataSourceImpl(
              dio: sl<ApiClient>().dio,
            ),
          ),
          requestId: requestId,
          myFromType: 1, // passenger = from_type 1
        ),
        child: TripChatPage(
          otherPartyName: otherPartyName,
          otherPartyPhotoUrl: otherPartyPhotoUrl,
        ),
      ),
    ),
  );
}

/// Opens the phone dialer with the given phone number.
Future<void> _callPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.phoneNotAvailable)),
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
      '${AppStrings.fromLabel} $pickAddress\n'
      '${AppStrings.toLabel} $dropAddress';
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

// end of file
