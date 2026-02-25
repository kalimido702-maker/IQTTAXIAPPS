import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/map_performance.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_map_view.dart';
import '../../../../core/widgets/iq_menu_button.dart';
import '../../../../core/widgets/iq_text.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../../../core/widgets/iq_sidebar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../ride_booking/presentation/bloc/driver/driver_trip_bloc.dart';
import '../../../ride_booking/presentation/bloc/driver/driver_trip_event.dart';
import '../../../ride_booking/presentation/bloc/driver/driver_trip_state.dart';
import '../../../ride_booking/presentation/pages/driver/driver_active_trip_page.dart';
import '../../../ride_booking/presentation/pages/driver/incoming_request_overlay.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              DriverHomeBloc(repository: sl<HomeRepository>())
                ..add(const DriverHomeLoadRequested()),
        ),
        BlocProvider.value(value: sl<DriverTripBloc>()),
      ],
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
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  GoogleMapController? _mapController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStream?.cancel();
    super.dispose();
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
          markerId: MapMarkerIds.user,
          position: position,
          icon: MapIcons.user,
          anchor: const Offset(0.5, 0.5),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return MultiBlocListener(
      listeners: [
        // When driver goes online/offline, start/stop listening for requests
        BlocListener<DriverHomeBloc, DriverHomeState>(
          listenWhen: (prev, curr) => prev.isOnline != curr.isOnline,
          listener: (context, homeState) {
            if (homeState.isOnline) {
              final driverId = homeState.homeData?.id ?? '';
              context.read<DriverTripBloc>().add(
                DriverTripListenRequested(driverId),
              );
            } else {
              context.read<DriverTripBloc>().add(const DriverTripReset());
            }
          },
        ),
        // When driver accepts a request, navigate to active trip page
        BlocListener<DriverTripBloc, DriverTripState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, tripState) {
            if (tripState.status == DriverTripStatus.navigatingToPickup) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  maintainState: false,
                  builder: (_) => const DriverActiveTripPage(),
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
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
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
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
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _goToUserLocation();
                        },
                        mapPadding: EdgeInsets.only(bottom: 240.h),
                      ),
                    ),

                    // Pulsing accuracy circle — painted as Flutter overlay,
                    // NOT as a GoogleMap circle.
                    if (_currentPosition != null && _mapController != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _PulsingAccuracyOverlay(
                            animation: _pulseAnimation,
                            controller: _mapController!,
                            center: _currentPosition!,
                            color: AppColors.markerTeal,
                          ),
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
                                  onTap: () => context
                                      .read<DriverHomeBloc>()
                                      .add(const DriverHomeLoadRequested()),
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

                    // Incoming request overlay
                    BlocBuilder<DriverTripBloc, DriverTripState>(
                      buildWhen: (prev, curr) =>
                          prev.status != curr.status ||
                          prev.incomingRequest != curr.incomingRequest,
                      builder: (context, tripState) {
                        if (tripState.status ==
                                DriverTripStatus.incomingRequest &&
                            tripState.incomingRequest != null) {
                          return Positioned.fill(
                            child: IncomingRequestOverlay(
                              request: tripState.incomingRequest!,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
      ),
    );
  }
}

/// Paints the pulsing accuracy circle as a Flutter overlay.
class _PulsingAccuracyOverlay extends StatefulWidget {
  const _PulsingAccuracyOverlay({
    required this.animation,
    required this.controller,
    required this.center,
    required this.color,
  });

  final Animation<double> animation;
  final GoogleMapController controller;
  final LatLng center;
  final Color color;

  @override
  State<_PulsingAccuracyOverlay> createState() =>
      _PulsingAccuracyOverlayState();
}

class _PulsingAccuracyOverlayState extends State<_PulsingAccuracyOverlay> {
  Offset? _screenPos;

  @override
  void initState() {
    super.initState();
    _updateScreenPos();
  }

  @override
  void didUpdateWidget(_PulsingAccuracyOverlay old) {
    super.didUpdateWidget(old);
    if (old.center != widget.center) {
      _updateScreenPos();
    }
  }

  Future<void> _updateScreenPos() async {
    try {
      final coord = await widget.controller.getScreenCoordinate(widget.center);
      if (!mounted) return;
      final dpr = MediaQuery.of(context).devicePixelRatio;
      setState(() {
        _screenPos = Offset(coord.x / dpr, coord.y / dpr);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_screenPos == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _CirclePainter(
            center: _screenPos!,
            opacity: widget.animation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.center,
    required this.opacity,
    required this.color,
  });

  final Offset center;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = 30 + (20 * opacity);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.08 * opacity)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.25 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.center != center;
  }
}
