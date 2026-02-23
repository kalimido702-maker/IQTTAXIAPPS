import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_map_view.dart';
import '../../../../core/widgets/iq_menu_button.dart';
import '../../../../core/widgets/iq_text.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../../../core/widgets/iq_sidebar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../bloc/driver_home_bloc.dart';
import '../bloc/driver_home_event.dart';
import '../bloc/driver_home_state.dart';
import '../widgets/driver_status_badge.dart';
import '../widgets/earnings_bottom_sheet.dart';

/// Driver Home Page — **100% StatelessWidget**.
///
/// Creates its own [DriverHomeBloc] internally and dispatches
/// [DriverHomeLoadRequested] to fetch data from the API.
class DriverHomePage extends StatelessWidget {
  const DriverHomePage({
    super.key,
    required this.sidebarItems,
    this.onProfileTap,
  });

  final List<IqSidebarItem> sidebarItems;
  final void Function(BuildContext context)? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DriverHomeBloc(repository: sl<HomeRepository>())
            ..add(const DriverHomeLoadRequested()),
      child: _DriverHomeBody(
        sidebarItems: sidebarItems,
        onProfileTap: onProfileTap,
      ),
    );
  }
}

class _DriverHomeBody extends StatefulWidget {
  const _DriverHomeBody({required this.sidebarItems, this.onProfileTap});

  final List<IqSidebarItem> sidebarItems;
  final void Function(BuildContext context)? onProfileTap;

  @override
  State<_DriverHomeBody> createState() => _DriverHomeBodyState();
}

class _DriverHomeBodyState extends State<_DriverHomeBody>
    with SingleTickerProviderStateMixin {
  final _mapKey = GlobalKey<IqMapViewState>();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  BitmapDescriptor? _markerIcon;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _createMarkerIcon();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addListener(_updateAccuracyCircle);
  }

  @override
  void dispose() {
    _pulseController.removeListener(_updateAccuracyCircle);
    _pulseController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  /// Create a small teal dot marker icon (no accuracy ring — ring is a Circle).
  Future<void> _createMarkerIcon() async {
    const double canvasSize = 80;
    const double dotRadius = 16;
    const double borderWidth = 3.5;
    const Color teal = AppColors.markerTeal;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(canvasSize / 2, canvasSize / 2);

    // Shadow
    canvas.drawCircle(
      center + const Offset(0, 2),
      dotRadius + borderWidth,
      Paint()
        ..color = teal.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // White border
    canvas.drawCircle(
      center,
      dotRadius + borderWidth,
      Paint()..color = Colors.white,
    );

    // Teal fill
    canvas.drawCircle(center, dotRadius, Paint()..color = teal);

    // Navigation arrow
    final a = dotRadius * 0.75;
    final path = Path()
      ..moveTo(center.dx, center.dy - a * 0.8)
      ..lineTo(center.dx - a * 0.55, center.dy + a * 0.5)
      ..lineTo(center.dx, center.dy + a * 0.1)
      ..lineTo(center.dx + a * 0.55, center.dy + a * 0.5)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      _markerIcon = BitmapDescriptor.bytes(
        byteData.buffer.asUint8List(),
        imagePixelRatio: 1.0,
      );
    }
  }

  /// Rebuild the pulsing accuracy circle on each animation tick.
  void _updateAccuracyCircle() {
    if (_currentPosition == null) return;
    final opacity = _pulseAnimation.value;
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('accuracy'),
          center: _currentPosition!,
          radius: 50,
          fillColor: AppColors.markerTeal.withValues(alpha: 0.08 * opacity),
          strokeColor: AppColors.markerTeal.withValues(alpha: 0.25 * opacity),
          strokeWidth: 1,
        ),
      };
    });
  }

  /// Request location permission, move map, and start position stream.
  Future<void> _goToUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapKey.currentState?.animateTo(latLng, zoom: 15.0);
      _updateMarker(latLng);

      // Start listening for position updates
      _positionStream?.cancel();
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((pos) {
            _updateMarker(LatLng(pos.latitude, pos.longitude));
          });
    } catch (_) {}
  }

  /// Update the marker position on the map.
  void _updateMarker(LatLng position) {
    _currentPosition = position;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('my_location'),
          position: position,
          icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
        ),
      };
    });
    _updateAccuracyCircle();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return BlocBuilder<DriverHomeBloc, DriverHomeState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.homeData != curr.homeData,
      builder: (context, state) {
        final data = state.homeData;
        final userName = data?.name ?? '';
        final userSubtitle = data?.driverSubtitle ?? '';
        final userRating = data?.rating ?? 0.0;
        final avatarUrl = data?.avatarUrl;

        // Build earnings from API data
        final earnings = TodayEarnings(
          tripsCount: data?.totalRidesTaken ?? 0,
          distanceKm: data?.totalKms ?? 0,
          activeHours: data?.activeHours ?? 0,
          activeMinutes: data?.activeMinutes ?? 0,
          totalEarningsIQD: data?.totalEarnings ?? 0,
        );

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ZoomDrawer(
          menuScreen: IqSidebar(
            items: widget.sidebarItems,
            userName: userName,
            userSubtitle: userSubtitle,
            userRating: userRating,
            avatarUrl: avatarUrl,
            onProfileTap: widget.onProfileTap,
          ),
          mainScreen: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: AppColors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: AppColors.transparent,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  // Full-screen Map with custom teal marker
                  Positioned.fill(
                    child: IqMapView(
                      key: _mapKey,
                      markers: _markers,
                      circles: _circles,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      onMapCreated: (_) => _goToUserLocation(),
                      mapPadding: EdgeInsets.only(bottom: 240.h),
                    ),
                  ),

                  // Loading overlay
                  if (state.status == DriverHomeStatus.loading)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.white.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.buttonYellow,
                          ),
                        ),
                      ),
                    ),

                  // Error banner
                  if (state.status == DriverHomeStatus.error)
                    Positioned(
                      top: topPadding + 60.h,
                      left: 24.w,
                      right: 24.w,
                      child: Material(
                        borderRadius: BorderRadius.circular(12.r),
                        color: AppColors.error,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: IqText(
                                  state.errorMessage ?? 'حدث خطأ',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.read<DriverHomeBloc>().add(
                                  const DriverHomeLoadRequested(),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  color: AppColors.white,
                                  size: 24.w,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Top bar
                  Positioned(
                    top: topPadding + 12.h,
                    left: 16.w,
                    right: 16.w,
                    child: Row(
                      children: [
                        const Spacer(),
                        // Online/Offline badge
                        BlocBuilder<DriverHomeBloc, DriverHomeState>(
                          buildWhen: (prev, curr) =>
                              prev.isOnline != curr.isOnline ||
                              prev.isToggling != curr.isToggling,
                          builder: (context, badgeState) {
                            return DriverStatusBadge(
                              isOnline: badgeState.isOnline,
                              isLoading: badgeState.isToggling,
                              onToggle: () => context
                                  .read<DriverHomeBloc>()
                                  .add(const DriverHomeStatusToggled()),
                            );
                          },
                        ),
                        const Spacer(),
                        // Menu button
                        Builder(
                          builder: (drawerCtx) => IqMenuButton(
                            onTap: () => ZoomDrawer.of(drawerCtx)?.toggle(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom earnings sheet
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: EarningsBottomSheet(earnings: earnings),
                  ),
                ],
              ),
            ),
          ),
          slideWidth: MediaQuery.of(context).size.width * 0.65,
          isRtl: true,
          borderRadius: 24.0,
          showShadow: true,
          angle: 0.0,
          disableDragGesture: true,
          drawerShadowsBackgroundColor: AppColors.drawerShadow,
          mainScreenTapClose: true,
        );
      },
    );
  }
}
