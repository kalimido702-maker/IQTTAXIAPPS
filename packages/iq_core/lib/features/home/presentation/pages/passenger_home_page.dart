import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/map_performance.dart';
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
import '../../../ride_booking/presentation/pages/passenger/search_destination_page.dart';
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

  /// Current position — updated by the isolated map section via callback.
  /// No setState needed — this is only read when user taps search.
  LatLng? _currentPosition;

  /// Navigate to search destination page with current location.
  Future<void> _handleSearchTap() async {
    final lat = _currentPosition?.latitude ?? 33.3152;
    final lng = _currentPosition?.longitude ?? 44.3661;
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassengerHomeBloc, PassengerHomeState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.homeData != curr.homeData ||
          prev.rideModules != curr.rideModules,
      builder: (context, state) {
        // Extract user data from state
        final data = state.homeData;
        final userName = data?.name ?? '';
        final userRating = data?.rating ?? 0.0;
        final avatarUrl = data?.avatarUrl;

        // Build promo banners from API response
        final promoBanners =
            data?.banners
                .map(
                  (b) => PromoBanner(
                    imageUrl: b.image.isNotEmpty ? b.image : null,
                    redirectLink: b.redirectLink,
                  ),
                )
                .toList() ??
            [];

        // Build quick places from favourite locations
        final quickPlaces =
            data?.allFavouriteLocations
                .map(
                  (loc) =>
                      QuickPlace(name: loc.address, lat: loc.lat, lng: loc.lng),
                )
                .toList() ??
            [];

        // Build categories from ride modules (API) or fallback
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
            : _buildFallbackCategories(data?.enableModules ?? 'taxi');

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ZoomDrawer(
          menuScreen: IqSidebar(
            items: widget.sidebarItems,
            userName: userName,
            userSubtitle: data?.phone ?? '',
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
                  // ── Map Section ──────────────────────────────
                  // Fully isolated in its own StatefulWidget.
                  // BlocBuilder rebuilds do NOT touch the map.
                  Positioned.fill(
                    child: _HomeMapSection(
                      sheetFraction: _sheetMin,
                      onPositionChanged: (pos) => _currentPosition = pos,
                    ),
                  ),

                  // Loading overlay
                  if (state.status == HomeStatus.loading)
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

                  // Error snackbar-style banner
                  if (state.status == HomeStatus.error)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60.h,
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
                    ),

                  // Top bar (menu button — right side for RTL)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12.h,
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

                  // Bottom sheet
                  BlocBuilder<PassengerHomeBloc, PassengerHomeState>(
                    builder: (context, sheetState) {
                      return DraggableScrollableSheet(
                        initialChildSize: _sheetInitial,
                        minChildSize: _sheetMin,
                        maxChildSize: _sheetMax,
                        snap: true,
                        snapSizes: const [_sheetMin, _sheetMax],
                        builder: (context, scrollController) {
                          return HomeBottomSheet(
                            scrollController: scrollController,
                            categories: categories,
                            quickPlaces: quickPlaces,
                            activeCategory: sheetState.activeCategory,
                            onCategoryTap: (i) {
                              context.read<PassengerHomeBloc>().add(
                                PassengerHomeCategoryChanged(i),
                              );
                              widget.onCategoryChanged?.call(i);
                            },
                            onSearchTap: widget.onSearchTap ?? _handleSearchTap,
                            promoBanners: promoBanners,
                            promoBannerUrl: (data?.banners.isNotEmpty ?? false)
                                ? data!.banners.first.image
                                : null,
                            onPromoBannerTap: widget.onPromoBannerTap,
                            onQuickPlaceTap: widget.onQuickPlaceTap,
                          );
                        },
                      );
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
// This has its OWN State and lifecycle. When the parent's BlocBuilder
// rebuilds to update the bottom sheet, this widget is NOT rebuilt
// because Flutter recognises it hasn't changed (same widget, same key).
//
// Location tracking + pulsing overlay live here.
// ═════════════════════════════════════════════════════════════════════

class _HomeMapSection extends StatefulWidget {
  const _HomeMapSection({
    required this.sheetFraction,
    required this.onPositionChanged,
  });

  final double sheetFraction;
  final ValueChanged<LatLng> onPositionChanged;

  @override
  State<_HomeMapSection> createState() => _HomeMapSectionState();
}

class _HomeMapSectionState extends State<_HomeMapSection> {
  final _mapKey = GlobalKey<IqMapViewState>();

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;

  @override
  void dispose() {
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
      _updateMarker(latLng);

      // Start listening for position updates.
      // distanceFilter: 50 — update only every 50m to reduce rebuilds.
      _positionStream?.cancel();
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 50,
            ),
          ).listen((pos) {
            _updateMarker(LatLng(pos.latitude, pos.longitude));
          });
    } catch (_) {
      // Permission denied or location unavailable — stay at default.
    }
  }

  /// Update the marker + accuracy circle on the map.
  void _updateMarker(LatLng position) {
    _currentPosition = position;
    widget.onPositionChanged(position);
    setState(() {
      _markers = {
        Marker(
          markerId: MapMarkerIds.user,
          position: position,
          icon: MapIcons.user,
          anchor: const Offset(0.5, 0.5),
        ),
      };
      _circles = {
        Circle(
          circleId: const CircleId('accuracy'),
          center: position,
          radius: 80,
          fillColor: AppColors.markerTeal.withValues(alpha: 0.06),
          strokeColor: AppColors.markerTeal.withValues(alpha: 0.20),
          strokeWidth: 1,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The actual Google Map — only rebuilt when _markers/_circles change.
        Positioned.fill(
          child: IqMapView(
            key: _mapKey,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (_) => _goToUserLocation(),
            mapPadding: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * widget.sheetFraction,
            ),
          ),
        ),

        // Current location FAB
        Positioned(
          bottom:
              MediaQuery.of(context).size.height * widget.sheetFraction + 16.h,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: s * 0.55,
          color: iconColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}


