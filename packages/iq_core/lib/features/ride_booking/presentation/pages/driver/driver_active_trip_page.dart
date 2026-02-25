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
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/cancel_reason_model.dart';
import '../../../data/models/incoming_request_model.dart';
import '../../bloc/driver/driver_trip_bloc.dart';
import '../../bloc/driver/driver_trip_event.dart';
import '../../bloc/driver/driver_trip_state.dart';
import '../passenger/trip_invoice_page.dart';
import '../../widgets/cancel_reasons_sheet.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/trip_address_row.dart';
import '../../widgets/waiting_timer_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverTripBloc, DriverTripState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == DriverTripStatus.tripCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TripInvoicePage(
                requestId: state.requestId ?? '',
                isDriver: true,
              ),
            ),
          );
        }
        if (state.status == DriverTripStatus.cancelled) {
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
                  child: _DriverTripMap(
                    mapKey: _mapKey,
                    state: state,
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
  bool _hasFetched = false;

  /// Object pools — avoid re-creating Set<Marker>/Set<Polyline> on every frame.
  final MarkerPool _markerPool = MarkerPool();
  final PolylinePool _polylinePool = PolylinePool();

  /// Cached hue icons — avoid repeated SDK look-ups every build.
  static final _pickupIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  static final _dropoffIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  static final _driverIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

  @override
  void initState() {
    super.initState();
    _fetchRouteIfNeeded();
    _syncMarkersAndPolylines();
  }

  @override
  void didUpdateWidget(covariant _DriverTripMap old) {
    super.didUpdateWidget(old);
    _fetchRouteIfNeeded();
    _syncMarkersAndPolylines();
  }

  void _fetchRouteIfNeeded() {
    final req = widget.state.incomingRequest;
    if (_hasFetched || req == null) return;
    if (req.pickLat == 0 || req.dropLat == 0) return;
    _hasFetched = true;
    _fetchDirections(req);
  }

  Future<void> _fetchDirections(IncomingRequestModel req) async {
    try {
      final service = sl<GoogleMapsService>();
      final result = await service.getDirections(
        originLat: req.pickLat,
        originLng: req.pickLng,
        destLat: req.dropLat,
        destLng: req.dropLng,
      );
      if (result != null && mounted) {
        setState(() => _routePoints = simplifyPolyline(result.polylinePoints));
        // Fit camera to route bounds.
        final bounds = calculateBounds(result.polylinePoints);
        widget.mapKey.currentState?.fitBounds(bounds);
      }
    } catch (_) {}
  }

  /// Rebuild marker/polyline pools only when widget config changes.
  void _syncMarkersAndPolylines() {
    final req = widget.state.incomingRequest;
    final trip = widget.state.activeTripData;

    if (req != null) {
      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.pickup,
        position: LatLng(req.pickLat, req.pickLng),
        icon: _pickupIcon,
      ));

      _markerPool.upsert(Marker(
        markerId: MapMarkerIds.dropoff,
        position: LatLng(req.dropLat, req.dropLng),
        icon: _dropoffIcon,
      ));

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
      } else {
        _polylinePool.upsert(Polyline(
          polylineId: MapPolylineIds.route,
          color: AppColors.routeLine,
          width: 4,
          points: [
            LatLng(req.pickLat, req.pickLng),
            LatLng(req.dropLat, req.dropLng),
          ],
        ));
      }
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return IqMapView(
      key: widget.mapKey,
      markers: _markerPool.markers,
      polylines: _polylinePool.polylines,
      mapPadding: EdgeInsets.only(bottom: 350.h),
      myLocationEnabled: true,
    );
  }
}

class _DriverTripSheet extends StatelessWidget {
  const _DriverTripSheet({required this.state});
  final DriverTripState state;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTripData;
    final phase = trip?.phase;

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

            // Status header
            _DriverStatusHeader(status: state.status),
            SizedBox(height: 16.h),

            // Waiting timer banner (arrived at pickup)
            if (phase == TripPhase.driverArrived)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: WaitingTimerBanner(
                  message: 'الوقت المتبقي لانتظار الراكب',
                  warningMessage: 'سيتم احتساب رسوم الانتظار بعد انتهاء الوقت المجاني',
                  startTime: DateTime.now(),
                ),
              ),

            // Distance/time banner (in progress)
            if (phase == TripPhase.inProgress && trip != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IqText(
                        '${trip.distance.toStringAsFixed(1)} km',
                        style: AppTypography.numberMedium.copyWith(
                          color: AppColors.primary700,
                        ),
                        dir: TextDirection.ltr,
                      ),
                      IqText(
                        '${trip.duration} min',
                        style: AppTypography.numberMedium.copyWith(
                          color: AppColors.primary700,
                        ),
                        dir: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ),

            // User info
            if (state.incomingRequest != null)
              UserInfoCard(
                name: state.incomingRequest!.userName ?? '',
                photoUrl: state.incomingRequest!.userImage,
                rating: double.tryParse(state.incomingRequest!.userRating ?? '') ?? 0.0,
                onChat: () {
                  // TODO: Open chat
                },
                onCall: () {
                  // TODO: Call user
                },
              ),
            SizedBox(height: 16.h),

            // Addresses
            if (state.incomingRequest != null)
              TripAddressRow(
                pickAddress: state.incomingRequest!.pickAddress,
                dropAddress: state.incomingRequest!.dropAddress,
                compact: true,
              ),

            // Price
            if (state.incomingRequest != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  IqText(
                    'السعر: ',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  IqText(
                    '${state.incomingRequest!.totalAmount.toStringAsFixed(0)} IQD',
                    style: AppTypography.numberLarge.copyWith(
                      color: AppColors.primary700,
                      fontWeight: FontWeight.w700,
                    ),
                    dir: TextDirection.ltr,
                  ),
                ],
              ),
            ],

            SizedBox(height: 20.h),

            // Action buttons based on phase
            _DriverActionButtons(
              status: state.status,
              requestId: state.requestId ?? '',
              trip: trip,
              incomingRequest: state.incomingRequest,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStatusHeader extends StatelessWidget {
  const _DriverStatusHeader({required this.status});
  final DriverTripStatus status;

  String get _text {
    switch (status) {
      case DriverTripStatus.navigatingToPickup:
        return 'في الطريق';
      case DriverTripStatus.arrivedAtPickup:
        return 'وصل السائق';
      case DriverTripStatus.tripInProgress:
        return 'في الطريق إلى موقع الإنزال';
      default:
        return 'حالة الرحلة';
    }
  }

  Color get _color {
    switch (status) {
      case DriverTripStatus.navigatingToPickup:
        return AppColors.info;
      case DriverTripStatus.arrivedAtPickup:
        return AppColors.warning;
      case DriverTripStatus.tripInProgress:
        return AppColors.success;
      default:
        return AppColors.textDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: IqText(
        _text,
        style: AppTypography.labelMedium.copyWith(color: _color),
      ),
    );
  }
}

class _DriverActionButtons extends StatelessWidget {
  const _DriverActionButtons({
    required this.status,
    required this.requestId,
    this.trip,
    this.incomingRequest,
  });

  final DriverTripStatus status;
  final String requestId;
  final ActiveTripModel? trip;
  final IncomingRequestModel? incomingRequest;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DriverTripStatus.navigatingToPickup:
        return Row(
          children: [
            Expanded(
              child: IqOutlinedButton(
                text: 'إلغاء',
                onPressed: () => _showDriverCancelSheet(context, requestId),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: IqPrimaryButton(
                text: 'وصلت الرحلة',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<DriverTripBloc>().add(
                        DriverTripMarkArrived(requestId),
                      );
                },
              ),
            ),
          ],
        );

      case DriverTripStatus.arrivedAtPickup:
        return Row(
          children: [
            Expanded(
              child: IqOutlinedButton(
                text: 'إلغاء',
                onPressed: () => _showDriverCancelSheet(context, requestId),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: IqPrimaryButton(
                text: 'إبدأ الرحلة',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<DriverTripBloc>().add(
                        DriverTripStartRide(
                          requestId: requestId,
                          pickLat: incomingRequest?.pickLat ?? 0,
                          pickLng: incomingRequest?.pickLng ?? 0,
                        ),
                      );
                },
              ),
            ),
          ],
        );

      case DriverTripStatus.tripInProgress:
        return IqPrimaryButton(
          text: 'نهاية الرحلة',
          onPressed: () {
            HapticFeedback.heavyImpact();
            context.read<DriverTripBloc>().add(
                  DriverTripEndRide(
                    requestId: requestId,
                    dropLat: incomingRequest?.dropLat ?? 0,
                    dropLng: incomingRequest?.dropLng ?? 0,
                    distance: trip?.distance ?? 0,
                  ),
                );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

void _showDriverCancelSheet(BuildContext context, String requestId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CancelReasonsSheet(
      title: 'سبب الإلغاء',
      reasons: const [
        CancelReasonModel(
          id: 1,
          reason: 'مشكلة في السيارة أو ظرف طارئ',
          userType: 'driver',
          arrivalStatus: 'before',
        ),
        CancelReasonModel(
          id: 2,
          reason: 'الراكب لا يرد على الهاتف أو الرسائل',
          userType: 'driver',
          arrivalStatus: 'before',
        ),
        CancelReasonModel(
          id: 3,
          reason: 'أخرى',
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
