import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/iq_map_view.dart';
import '../../../../core/widgets/iq_menu_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../../../../core/widgets/iq_sidebar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../location/domain/repositories/location_repository.dart';
import '../../../ride_booking/presentation/bloc/passenger/passenger_trip_bloc.dart';
import '../../../ride_booking/presentation/bloc/passenger/passenger_trip_event.dart';
import '../../../ride_booking/presentation/pages/passenger/passenger_active_trip_page.dart';
import '../../../ride_booking/presentation/pages/passenger/search_destination_page.dart';
import '../../data/models/ongoing_ride_model.dart';
import '../bloc/passenger_home_bloc.dart';
import '../bloc/passenger_home_event.dart';
import '../bloc/passenger_home_state.dart';
import '../widgets/home_bottom_sheet.dart';

/// Passenger Home Page — **100% StatelessWidget**.
///
/// Creates its own [PassengerHomeBloc] internally and dispatches
/// [PassengerHomeLoadRequested] to fetch data from the API.
class PassengerHomePage extends StatelessWidget {
  const PassengerHomePage({
    super.key,
    required this.sidebarItems,
    this.onSearchTap,
    this.onProfileTap,
    this.onPromoBannerTap,
    this.onQuickPlaceTap,
    this.onCategoryChanged,
    this.initialCategory = 0,
  });

  final List<IqSidebarItem> sidebarItems;
  final VoidCallback? onSearchTap;
  final void Function(BuildContext context)? onProfileTap;
  final VoidCallback? onPromoBannerTap;
  final void Function(QuickPlace)? onQuickPlaceTap;
  final void Function(int index)? onCategoryChanged;
  final int initialCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PassengerHomeBloc(
        repository: sl<HomeRepository>(),
        initialCategory: initialCategory,
      )..add(const PassengerHomeLoadRequested()),
      child: _PassengerHomeBody(
        sidebarItems: sidebarItems,
        onSearchTap: onSearchTap,
        onProfileTap: onProfileTap,
        onPromoBannerTap: onPromoBannerTap,
        onQuickPlaceTap: onQuickPlaceTap,
        onCategoryChanged: onCategoryChanged,
      ),
    );
  }
}

class _PassengerHomeBody extends StatefulWidget {
  const _PassengerHomeBody({
    required this.sidebarItems,
    this.onSearchTap,
    this.onProfileTap,
    this.onPromoBannerTap,
    this.onQuickPlaceTap,
    this.onCategoryChanged,
  });

  final List<IqSidebarItem> sidebarItems;
  final VoidCallback? onSearchTap;
  final void Function(BuildContext context)? onProfileTap;
  final VoidCallback? onPromoBannerTap;
  final void Function(QuickPlace)? onQuickPlaceTap;
  final void Function(int index)? onCategoryChanged;

  @override
  State<_PassengerHomeBody> createState() => _PassengerHomeBodyState();
}

class _PassengerHomeBodyState extends State<_PassengerHomeBody> {
  /// Sheet snap sizes: collapsed ~35%, expanded ~70%
  static const double _sheetMin = 0.35;
  static const double _sheetMax = 0.70;
  static const double _sheetInitial = 0.35;

  /// Navigate to search destination page with current location.
  /// Uses [Geolocator.getLastKnownPosition] for instant access to the
  /// most recent cached position — no stream subscription needed.
  Future<void> _handleSearchTap() async {
    double lat = 33.3152;
    double lng = 44.3661;

    // Instantly read the most recent position from the system cache.
    // myLocationEnabled: true keeps the cache fresh via the map SDK.
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        lat = lastPos.latitude;
        lng = lastPos.longitude;
      }
    } catch (_) {}

    String address = 'الموقع الحالي';

    final homeData = context.read<PassengerHomeBloc>().state.homeData;
    final quickPlaces =
        homeData?.allFavouriteLocations
            .map(
              (loc) => {
                'name': loc.addressName.isNotEmpty
                    ? loc.addressName
                    : loc.address,
                'address': loc.address,
                'lat': loc.lat,
                'lng': loc.lng,
              },
            )
            .toList() ??
        <Map<String, dynamic>>[];

    try {
      final repo = sl<LocationRepository>();
      final result = await repo.getAddressFromCoordinates(
        latitude: lat,
        longitude: lng,
      );
      result.fold((_) {}, (addr) => address = addr);
    } catch (_) {}

    if (!mounted) return;

    // Reset bloc for a fresh trip flow
    sl<PassengerTripBloc>().add(const PassengerTripReset());

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchDestinationPage(
          pickupAddress: address,
          pickupLat: lat,
          pickupLng: lng,
          quickPlaces: quickPlaces,
        ),
      ),
    );
  }

  /// Tap on an ongoing ride from the carousel.
  ///
  /// Completed rides → TODO: navigate to invoice (not yet implemented).
  /// Active / searching rides → set up TripBloc & navigate to active trip page.
  void _handleOngoingRideTap(BuildContext ctx, OngoingRideModel ride) {
    final tripBloc = sl<PassengerTripBloc>();

    // Reset any previous trip state first
    tripBloc.add(const PassengerTripReset());

    // Restore as a searching/active trip — Firebase stream will
    // pick up the real phase (driverOnWay, inProgress, etc.)
    tripBloc.add(PassengerTripRestoreOngoing(
      requestId: ride.id,
      pickAddress: ride.pickAddress,
      dropAddress: ride.dropAddress,
      pickLat: ride.pickLat,
      pickLng: ride.pickLng,
      dropLat: ride.dropLat,
      dropLng: ride.dropLng,
    ));

    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => const PassengerActiveTripPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use granular MediaQuery accessors — prevents rebuilds when
    // unrelated properties change (e.g. keyboard appearing).
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ZoomDrawer(
      menuScreen: BlocBuilder<PassengerHomeBloc, PassengerHomeState>(
        buildWhen: (prev, curr) => prev.homeData != curr.homeData,
        builder: (context, state) {
          final data = state.homeData;
          return IqSidebar(
            items: widget.sidebarItems,
            userName: data?.name ?? '',
            userSubtitle: data?.phone ?? '',
            userRating: data?.rating ?? 0.0,
            avatarUrl: data?.avatarUrl,
            onProfileTap: widget.onProfileTap,
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
          // Map page — keyboard should not resize the layout.
          resizeToAvoidBottomInset: false,
          body: Stack(
            // Clip.none avoids an extra save-layer on the GPU
            // compositing thread. None of our children overflow.
            clipBehavior: Clip.none,
            children: [
              // ── Map Section ──────────────────────────────
              // Fully isolated in its own StatefulWidget.
              Positioned.fill(
                child: const _HomeMapSection(),
              ),

              // Loading / Error overlays — only these rebuild
              BlocBuilder<PassengerHomeBloc, PassengerHomeState>(
                buildWhen: (prev, curr) => prev.status != curr.status,
                builder: (context, state) {
                  if (state.status == HomeStatus.loading) {
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
                  if (state.status == HomeStatus.error) {
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
                                    .read<PassengerHomeBloc>()
                                    .add(const PassengerHomeLoadRequested()),
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

              // Top bar (menu button — right side for RTL)
              Positioned(
                top: topPadding + 12.h,
                left: 16.w,
                right: 16.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (drawerCtx) => IqMenuButton(
                        onTap: () => ZoomDrawer.of(drawerCtx)?.toggle(),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom sheet — persistent, only inner content rebuilds.
              // RepaintBoundary isolates sheet repaints from the map
              // layer so the GPU never re-composites the platform view
              // while the user drags the sheet.
              RepaintBoundary(
                child: DraggableScrollableSheet(
                  initialChildSize: _sheetInitial,
                  minChildSize: _sheetMin,
                  maxChildSize: _sheetMax,
                  snap: true,
                  snapSizes: const [_sheetMin, _sheetMax],
                  builder: (context, scrollController) {
                    return BlocBuilder<PassengerHomeBloc, PassengerHomeState>(
                      buildWhen: (prev, curr) =>
                          prev.homeData != curr.homeData ||
                          prev.rideModules != curr.rideModules ||
                          prev.activeCategory != curr.activeCategory ||
                          prev.ongoingRides != curr.ongoingRides,
                      builder: (context, state) {
                        final data = state.homeData;

                        final promoBanners =
                            data?.banners
                                .map(
                                  (b) => PromoBanner(
                                    imageUrl:
                                        b.image.isNotEmpty ? b.image : null,
                                    redirectLink: b.redirectLink,
                                  ),
                                )
                                .toList() ??
                            [];

                        final quickPlaces =
                            data?.allFavouriteLocations
                                .map(
                                  (loc) => QuickPlace(
                                    name: loc.address,
                                    lat: loc.lat,
                                    lng: loc.lng,
                                  ),
                                )
                                .toList() ??
                            [];

                        final categories = state.rideModules.isNotEmpty
                            ? state.rideModules
                                  .map(
                                    (m) => ServiceCategory(
                                      id: m.id,
                                      label: m.name,
                                      imageUrl: m.icon,
                                    ),
                                  )
                                  .toList()
                            : _buildFallbackCategories(
                                data?.enableModules ?? 'taxi',
                              );

                        return HomeBottomSheet(
                          scrollController: scrollController,
                          categories: categories,
                          quickPlaces: quickPlaces,
                          activeCategory: state.activeCategory,
                          onCategoryTap: (i) {
                            context.read<PassengerHomeBloc>().add(
                              PassengerHomeCategoryChanged(i),
                            );
                            widget.onCategoryChanged?.call(i);
                          },
                          onSearchTap:
                              widget.onSearchTap ?? _handleSearchTap,
                          promoBanners: promoBanners,
                          promoBannerUrl:
                              (data?.banners.isNotEmpty ?? false)
                                  ? data!.banners.first.image
                                  : null,
                          onPromoBannerTap: widget.onPromoBannerTap,
                          onQuickPlaceTap: widget.onQuickPlaceTap,
                          ongoingRides: state.ongoingRides,
                          onOngoingRideTap: (ride) =>
                              _handleOngoingRideTap(context, ride),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      slideWidth: screenWidth * 0.65,
      isRtl: true,
      borderRadius: 24.0,
      showShadow: true,
      angle: 0.0,
      disableDragGesture: true,
      drawerShadowsBackgroundColor: AppColors.drawerShadow,
      mainScreenTapClose: true,
    );
  }

  /// Fallback categories when ride modules API is unavailable.
  List<ServiceCategory> _buildFallbackCategories(String enableModules) {
    // Always show taxi categories; delivery categories depend on flag
    const fallbackImage = 'assets/images/fake_car.png';
    final cats = <ServiceCategory>[
      const ServiceCategory(label: 'تاكسي', imagePath: fallbackImage),
      const ServiceCategory(label: 'تاكسيVIP', imagePath: fallbackImage),
      const ServiceCategory(label: 'محافظات', imagePath: fallbackImage),
    ];

    if (enableModules == 'delivery' || enableModules == 'both') {
      cats.insert(
        1,
        const ServiceCategory(label: 'مندوبك', imagePath: fallbackImage),
      );
    }

    return cats;
  }
}

// ═════════════════════════════════════════════════════════════════════
// _HomeMapSection — Fully isolated map widget.
//
// const-constructable: Flutter skips didUpdateWidget, ensuring the
// map platform view is NEVER disturbed by parent rebuilds.
//
// Uses myLocationEnabled: true for the blue dot; position for search
// is read lazily via Geolocator.getLastKnownPosition().
// ═════════════════════════════════════════════════════════════════════

class _HomeMapSection extends StatefulWidget {
  const _HomeMapSection();

  @override
  State<_HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<_HomeMapSection> {
  final _mapKey = GlobalKey<IqMapViewState>();

  /// Map bottom padding — matches sheet collapsed height.
  static const double _sheetFraction = 0.35;

  /// Request location permission and move map to current location.
  /// Deferred to postFrameCallback so the first frame renders instantly
  /// without waiting for GPS.
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
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _mapKey.currentState?.animateTo(
        LatLng(pos.latitude, pos.longitude),
        zoom: 15.0,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        Positioned.fill(
          child: IqMapView(
            key: _mapKey,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            onMapCreated: (_) {
              // Defer GPS + camera animation to after the first frame
              // so the map renders instantly without blocking.
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _goToUserLocation();
              });
            },
            mapPadding: EdgeInsets.only(
              bottom: screenHeight * _sheetFraction,
            ),
          ),
        ),

        // Current location FAB
        Positioned(
          bottom: screenHeight * _sheetFraction + 16.h,
          left: 16.w,
          child: _CircleButton(
            icon: Icons.my_location,
            size: 48.w,
            iconColor: AppColors.primary,
            onTap: _goToUserLocation,
          ),
        ),
      ],
    );
  }
}

// ─── Reusable circle button ─────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double? size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 40.w;
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
            size: s * 0.55,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}


