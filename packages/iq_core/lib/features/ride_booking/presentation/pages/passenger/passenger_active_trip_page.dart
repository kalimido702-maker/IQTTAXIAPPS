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
import '../../../../../core/widgets/iq_outlined_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/cancel_reason_model.dart';
import '../../bloc/passenger/passenger_trip_bloc.dart';
import '../../bloc/passenger/passenger_trip_event.dart';
import '../../bloc/passenger/passenger_trip_state.dart';
import '../../widgets/cancel_reasons_sheet.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/searching_driver_animation.dart';
import '../../widgets/trip_action_buttons.dart';
import '../../widgets/trip_address_row.dart';
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

  /// Cached hue icons — avoid repeated SDK look-ups every build.
  static final _pickupIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  static final _dropoffIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  static final _driverIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);

  @override
  void initState() {
    super.initState();
    _updateRoute();
    _syncMarkersAndPolylines();
  }

  @override
  void didUpdateWidget(covariant _TripMap old) {
    super.didUpdateWidget(old);
    _updateRoute();
    _syncMarkersAndPolylines();
  }

  void _updateRoute() {
    final trip = widget.state.activeTripData;

    // 1) If Firebase has an encoded polyline, decode it.
    if (trip?.polyline != null &&
        trip!.polyline!.isNotEmpty &&
        trip.polyline != _lastPolylineSource) {
      _lastPolylineSource = trip.polyline;
      final decoded = GoogleMapsService.decodePolyline(trip.polyline!);
      if (decoded.isNotEmpty) {
        setState(() => _routePoints = simplifyPolyline(decoded));
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
    try {
      final service = sl<GoogleMapsService>();
      final result = await service.getDirections(
        originLat: widget.state.pickLat,
        originLng: widget.state.pickLng,
        destLat: widget.state.dropLat,
        destLng: widget.state.dropLng,
      );
      if (result != null && mounted) {
        setState(() {
          _routePoints = simplifyPolyline(result.polylinePoints);
          _lastPolylineSource = result.encodedPolyline;
        });
      }
    } catch (_) {
      // Silently fail — straight line fallback.
    }
  }

  /// Rebuild marker/polyline pools only when data differs.
  void _syncMarkersAndPolylines() {
    final state = widget.state;
    final trip = state.activeTripData;

    // Pickup marker
    if (state.pickLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(state.pickLat, state.pickLng),
        icon: _pickupIcon,
      ));
    }

    // Dropoff marker
    if (state.dropLat != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(state.dropLat, state.dropLng),
        icon: _dropoffIcon,
      ));
    }

    // Driver marker
    if (trip != null && (trip.driverLat ?? 0) != 0) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.driver,
        position: LatLng(trip.driverLat ?? 0.0, trip.driverLng ?? 0.0),
        icon: _driverIcon,
        rotation: trip.driverBearing ?? 0.0,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    // Route polyline
    final routePts = _routePoints;
    if (routePts != null && routePts.length >= 2) {
      _polylinePool.upsert(Polyline(
        polylineId: MapPolylineIds.route,
        color: AppColors.routeLine,
        width: 5,
        geodesic: true,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        points: routePts,
      ));
    } else if (state.pickLat != 0 && state.dropLat != 0) {
      _polylinePool.upsert(Polyline(
        polylineId: MapPolylineIds.route,
        color: AppColors.routeLine,
        width: 4,
        points: [
          LatLng(state.pickLat, state.pickLng),
          LatLng(state.dropLat, state.dropLng),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IqMapView(
      key: widget.mapKey,
      initialTarget: widget.state.pickLat != 0
          ? LatLng(widget.state.pickLat, widget.state.pickLng)
          : null,
      markers: _markerPool.markers,
      polylines: _polylinePool.polylines,
      mapPadding: EdgeInsets.only(bottom: 320.h),
    );
  }
}

/// Searching for driver overlay with pulse animation + cancel.
class _SearchingOverlay extends StatelessWidget {
  const _SearchingOverlay({required this.state});
  final PassengerTripState state;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.white.withValues(alpha: 0.95),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 60.h),
              const Expanded(
                child: SearchingDriverAnimation(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: IqOutlinedButton(
                  text: 'إلغاء',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showCancelConfirmation(context, state.requestId ?? '');
                  },
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for active trip phases (driver on way, arrived, in progress).
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

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
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
        child: SingleChildScrollView(
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
              SizedBox(height: 12.h),

              // Status text
              _StatusHeader(phase: trip.phase),
              SizedBox(height: 16.h),

              // Waiting charge warning (driver arrived)
              if (trip.phase == TripPhase.driverArrived)
                _WaitingBanner(),

              // Driver info
              DriverInfoCard(
                name: trip.driverName ?? '',
                photoUrl: trip.driverProfilePic,
                rating: trip.driverRatingValue,
                carModel: trip.vehicleTypeName,
                carColor: trip.vehicleColor,
                plateNumber: trip.vehicleNumber,
                onChat: () {
                  // TODO: Navigate to chat
                },
                onCall: () {
                  // TODO: Launch phone call
                },
              ),
              SizedBox(height: 16.h),

              // Addresses
              TripAddressRow(
                pickAddress: state.pickAddress,
                dropAddress: state.dropAddress,
                compact: true,
              ),

              // Action buttons (in progress only)
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
                    // TODO: Share trip link
                  },
                  onSos: () {
                    // TODO: SOS emergency
                  },
                ),
              ],

              SizedBox(height: 16.h),

              // Price + cancel row
              Row(
                children: [
                  // Price
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: IqText(
                      '${trip.totalAmount.toStringAsFixed(0)} ${trip.currencySymbol}',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary700,
                      ),
                      dir: TextDirection.ltr,
                    ),
                  ),
                  const Spacer(),
                  // Cancel (not during in-progress)
                  if (trip.phase != TripPhase.inProgress)
                    TextButton(
                      onPressed: () => _showCancelConfirmation(
                        context,
                        state.requestId ?? '',
                      ),
                      child: IqText(
                        'إلغاء',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.phase});
  final TripPhase phase;

  String get _text {
    switch (phase) {
      case TripPhase.driverOnWay:
        return 'السائق في الطريق إليك';
      case TripPhase.driverArrived:
        return 'السائق وصل';
      case TripPhase.inProgress:
        return 'الوصول للوجهة';
      default:
        return '';
    }
  }

  IconData get _icon {
    switch (phase) {
      case TripPhase.driverOnWay:
        return Icons.directions_car_rounded;
      case TripPhase.driverArrived:
        return Icons.flag_rounded;
      case TripPhase.inProgress:
        return Icons.navigation_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(_icon, size: 20.w, color: AppColors.primary700),
        ),
        SizedBox(width: 10.w),
        IqText(
          _text,
          style: AppTypography.heading3.copyWith(color: AppColors.textDark),
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
              'سيتم احتساب رسوم الانتظار بعد مرور الوقت المجاني',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows cancel confirmation dialog with reasons.
void _showCancelConfirmation(BuildContext context, String requestId) {
  // Fetch cancel reasons then show sheet
  final bloc = context.read<PassengerTripBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CancelReasonsSheet(
      reasons: const [
        CancelReasonModel(id: 1, reason: 'تغير رأيي', userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 2, reason: 'السائق بعيد جداً', userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 3, reason: 'وجدت وسيلة أخرى', userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 4, reason: 'طلبت بالخطأ', userType: 'user', arrivalStatus: 'before'),
        CancelReasonModel(id: 5, reason: 'أخرى', userType: 'user', arrivalStatus: 'before'),
      ],
      onConfirm: (reason, custom) {
        Navigator.pop(context);
        bloc.add(PassengerTripCancelRequested(reason: reason));
      },
    ),
  );
}
