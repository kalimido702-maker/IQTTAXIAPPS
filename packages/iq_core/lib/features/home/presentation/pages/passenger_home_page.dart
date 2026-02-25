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

class _PassengerHomeBodyState extends State<_PassengerHomeBody>
    with SingleTickerProviderStateMixin {
  final _mapKey = GlobalKey<IqMapViewState>();

  /// Sheet snap sizes: collapsed ~35%, expanded ~70%
  static const double _sheetMin = 0.35;
  static const double _sheetMax = 0.70;
  static const double _sheetInitial = 0.35;

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
              distanceFilter: 10, // update every 10 meters
            ),
          ).listen((pos) {
            _updateMarker(LatLng(pos.latitude, pos.longitude));
          });
    } catch (_) {
      // Permission denied or location unavailable — stay at default.
    }
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
        final bannerUrl = (data?.banners.isNotEmpty ?? false)
            ? data!.banners.first.image
            : null;

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
                      mapPadding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * _sheetMin,
                      ),
                    ),
                  ),

                  // Pulsing accuracy circle — painted as Flutter overlay,
                  // NOT as a GoogleMap circle. This avoids rebuilding the
                  // entire native map widget 60 times per second.
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

                  // Current location FAB
                  Positioned(
                    bottom:
                        MediaQuery.of(context).size.height * _sheetMin + 16.h,
                    left: 16.w,
                    child: _CircleButton(
                      icon: Icons.my_location,
                      size: 48.w,
                      iconColor: AppColors.primary,
                      onTap: _goToUserLocation,
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
                            promoBannerUrl: bannerUrl,
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

// Reusable circle button
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

/// Paints the pulsing accuracy circle as a Flutter overlay
/// instead of a native map circle.
///
/// This approach avoids rebuilding the expensive GoogleMap
/// widget 60 times per second. Only this lightweight widget
/// repaints on each animation tick — the map stays untouched.
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
    final radius = 30 + (20 * opacity); // Pulse between 30-50 pixels

    // Fill
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.08 * opacity)
        ..style = PaintingStyle.fill,
    );

    // Stroke
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
