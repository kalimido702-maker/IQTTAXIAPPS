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

class _DriverHomeBody extends StatelessWidget {
  const _DriverHomeBody({required this.sidebarItems, this.onProfileTap});

  final List<IqSidebarItem> sidebarItems;
  final void Function(BuildContext context)? onProfileTap;

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
      child: _buildDrawer(context, topPadding),
    );
  }

  Widget _buildDrawer(BuildContext context, double topPadding) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ZoomDrawer(
      menuScreen: BlocBuilder<DriverHomeBloc, DriverHomeState>(
        buildWhen: (prev, curr) => prev.homeData != curr.homeData,
        builder: (context, state) {
          final data = state.homeData;
          return IqSidebar(
            items: sidebarItems,
            userName: data?.name ?? '',
            userSubtitle: data?.driverSubtitle ?? '',
            userRating: data?.rating ?? 0.0,
            avatarUrl: data?.avatarUrl,
            onProfileTap: onProfileTap,
          );
        },
      ),
      mainScreen: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: AppColors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          body: Stack(
            children: [
              // ── Map Section ──────────────────────────
              const Positioned.fill(child: _DriverMapSection()),

              // Loading / Error overlays — only these rebuild
              BlocBuilder<DriverHomeBloc, DriverHomeState>(
                buildWhen: (prev, curr) => prev.status != curr.status,
                builder: (context, state) {
                  if (state.status == DriverHomeStatus.loading) {
                    return Positioned.fill(
                      child: Container(
                        color: AppColors.white.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.buttonYellow,
                          ),
                        ),
                      ),
                    );
                  }
                  if (state.status == DriverHomeStatus.error) {
                    return Positioned(
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
                    );
                  }
                  return const SizedBox.shrink();
                },
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

              // Bottom earnings sheet — isolated repaint layer
              RepaintBoundary(
                child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
                  buildWhen: (prev, curr) =>
                      prev.homeData != curr.homeData,
                  builder: (context, state) {
                    final data = state.homeData;
                    final earnings = TodayEarnings(
                      tripsCount: data?.totalRidesTaken ?? 0,
                      distanceKm: data?.totalKms ?? 0,
                      activeHours: data?.activeHours ?? 0,
                      activeMinutes: data?.activeMinutes ?? 0,
                      totalEarningsIQD: data?.totalEarnings ?? 0,
                    );
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: EarningsBottomSheet(earnings: earnings),
                    );
                  },
                ),
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
  }
}

// ═════════════════════════════════════════════════════════════════════
// _DriverMapSection — Fully isolated map widget.
//
// This has its OWN State and lifecycle. The parent BlocBuilder
// does NOT touch this widget when it rebuilds for earnings/status.
// ═════════════════════════════════════════════════════════════════════

class _DriverMapSection extends StatefulWidget {
  const _DriverMapSection();

  @override
  State<_DriverMapSection> createState() => _DriverMapSectionState();
}

class _DriverMapSectionState extends State<_DriverMapSection> {
  final _mapKey = GlobalKey<IqMapViewState>();

  @override
  void dispose() {
    super.dispose();
  }

  /// Request location permission and move map to current location.
  Future<void> _goToUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapKey.currentState?.animateTo(latLng, zoom: 15.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual Google Map — uses default blue dot for location.
        Positioned.fill(
          child: IqMapView(
            key: _mapKey,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            onMapCreated: (_) => _goToUserLocation(),
            mapPadding: EdgeInsets.only(bottom: 240.h),
          ),
        ),
      ],
    );
  }
}
