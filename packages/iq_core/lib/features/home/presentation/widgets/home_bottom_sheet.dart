import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iq_core/core/constants/app_assets.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/ongoing_ride_model.dart';
import 'ongoing_rides_carousel.dart';
import 'promo_banner_card.dart';
import 'service_category_card.dart';
import 'quick_place_tile.dart';

/// Service category data model.
class ServiceCategory {
  const ServiceCategory({
    required this.label,
    this.imagePath,
    this.imageUrl,
    this.id,
    this.transportType,
  });

  final String? id;
  final String label;

  /// Local asset path (fallback).
  final String? imagePath;

  /// Network image URL from backend.
  final String? imageUrl;

  /// `"taxi"` or `"delivery"` — from the API ride module.
  final String? transportType;
}

/// Quick place data model.
class QuickPlace {
  const QuickPlace({required this.name, this.lat, this.lng});

  final String name;
  final double? lat;
  final double? lng;
}

/// Promo banner data model used by the bottom sheet.
class PromoBanner {
  const PromoBanner({
    this.imageUrl,
    this.title,
    this.subtitle,
    this.statValue,
    this.statLabel,
    this.redirectLink,
  });

  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? statValue;
  final String? statLabel;
  final String? redirectLink;
}

/// The passenger home bottom sheet content.
///
/// Displays inside a [DraggableScrollableSheet]:
///   1. Drag handle
///   2. Service category cards row
///   3. Search bar ("إلى أين أنت ذاهب؟")
///   4. Promo banner (network or asset)
///   5. "أماكن سريعة" list
class HomeBottomSheet extends StatelessWidget {
  const HomeBottomSheet({
    super.key,
    required this.categories,
    required this.quickPlaces,
    this.isLoading = false,
    this.activeCategory = 0,
    this.onCategoryTap,
    this.onSearchTap,
    this.onQuickPlaceTap,
    this.promoBanners = const [],
    this.promoBannerUrl,
    this.onPromoBannerTap,
    this.scrollController,
    this.ongoingRides = const [],
    this.onOngoingRideTap,
  });

  /// When true, shows shimmer placeholders instead of real content.
  final bool isLoading;

  final List<ServiceCategory> categories;
  final List<QuickPlace> quickPlaces;
  final int activeCategory;
  final void Function(int index)? onCategoryTap;
  final VoidCallback? onSearchTap;
  final void Function(QuickPlace place)? onQuickPlaceTap;

  /// Rich promo banners (new design).
  final List<PromoBanner> promoBanners;

  /// Legacy single image URL — kept for backward compatibility.
  final String? promoBannerUrl;
  final VoidCallback? onPromoBannerTap;
  final ScrollController? scrollController;

  /// Active / ongoing rides to show in the carousel.
  final List<OngoingRideModel> ongoingRides;
  final void Function(OngoingRideModel ride)? onOngoingRideTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // Material.elevation uses drawShadow() — GPU-cached, NOT recomputed
    // per frame like BoxShadow's MaskFilter.blur(). Critical for smooth
    // DraggableScrollableSheet drag over a Google Maps platform view.
    return Material(
      elevation: 8,
      shadowColor: AppColors.shadow,
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      color: surfaceColor,
      child: isLoading
          ? _buildShimmerContent(surfaceColor)
          : _buildRealContent(surfaceColor),
    );
  }

  /// Shimmer placeholder shown while home data is loading.
  Widget _buildShimmerContent(Color surfaceColor) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // ─── Drag handle ───
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
            width: 50.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: SizedBox(
              height: 110.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(3, (_) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Container(
                      width: 90.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Search bar shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              height: 54.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Banner shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        // Quick places shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 12.h),
                ...List.generate(3, (_) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Container(
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Real content shown after data has loaded.
  Widget _buildRealContent(Color surfaceColor) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      cacheExtent: 300,
      children: [
        // ─── Drag handle ───
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
            width: 50.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
        ),

        // ─── Service categories ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: SizedBox(
            height: 110.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(categories.length, (i) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: ServiceCategoryCard(
                    label: categories[i].label,
                    imagePath: categories[i].imagePath,
                    imageUrl: categories[i].imageUrl,
                    isActive: i == activeCategory,
                    onTap: () => onCategoryTap?.call(i),
                  ),
                );
              }),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ─── Search bar ───
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 54.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.buttonYellow, width: 1.5),
              ),
              child: Row(
                children: [
                  IqImage(
                    AppAssets.searchIcon,
                    width: 20.w,
                    height: 20.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: IqText(
                      AppStrings.whereToGo,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textHint,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ─── Promo banners ───
        if (_hasBanners)
          _buildBannerSection(),
        if (_hasBanners) SizedBox(height: 20.h),

        // ─── Ongoing rides carousel ───
        if (ongoingRides.isNotEmpty) ...[
          OngoingRidesCarousel(
            rides: ongoingRides,
            onRideTap: onOngoingRideTap,
          ),
          SizedBox(height: 20.h),
        ],

        // ─── Quick places header ───
        if (quickPlaces.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: IqText(
              AppStrings.quickPlaces,
              style: AppTypography.heading3,
            ),
          ),
        if (quickPlaces.isNotEmpty) SizedBox(height: 8.h),

        // ─── Quick places list ───
        ...quickPlaces.map((place) {
          final isLast = place == quickPlaces.last;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                QuickPlaceTile(
                  name: place.name,
                  onTap: () => onQuickPlaceTap?.call(place),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: AppColors.grayDivider,
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 24.h),
      ],
    );
  }

  /// Whether there are any banners to show.
  /// Always true — falls back to the local asset banner if API provides none.
  bool get _hasBanners => true;

  /// Builds the promo banner section.
  ///
  /// Priority:
  ///   1. [promoBanners] list from API → PageView carousel
  ///   2. [promoBannerUrl] single URL (legacy) → single image card
  ///   3. Local asset fallback → [AppAssets.userHomeBanner]
  Widget _buildBannerSection() {
    // Multiple banners → horizontal PageView with indicators
    if (promoBanners.length > 1) {
      return _BannerCarousel(
        banners: promoBanners,
        onTap: onPromoBannerTap,
      );
    }

    // Single API banner
    if (promoBanners.length == 1) {
      final b = promoBanners.first;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: PromoBannerCard(
          imageUrl: b.imageUrl,
          title: b.title,
          subtitle: b.subtitle,
          statValue: b.statValue,
          statLabel: b.statLabel,
          onTap: onPromoBannerTap,
        ),
      );
    }

    // Legacy single URL
    if (promoBannerUrl != null && promoBannerUrl!.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: PromoBannerCard(
          imageUrl: promoBannerUrl,
          onTap: onPromoBannerTap,
        ),
      );
    }

    // Fallback: local asset banner
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: PromoBannerCard(
        assetImage: AppAssets.userHomeBanner,
        onTap: onPromoBannerTap,
      ),
    );
  }
}

/// A horizontally-swiping banner carousel with dot indicators.
///
/// Kept as a StatefulWidget internally so the page indicator works
/// while the parent [HomeBottomSheet] stays stateless.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.banners,
    this.onTap,
  });

  final List<PromoBanner> banners;
  final VoidCallback? onTap;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _currentPage = 0;
  final PageController _pageController =
      PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 130.h,
          child: PageView.builder(
            itemCount: widget.banners.length,
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final b = widget.banners[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: PromoBannerCard(
                  imageUrl: b.imageUrl,
                  title: b.title,
                  subtitle: b.subtitle,
                  statValue: b.statValue,
                  statLabel: b.statLabel,
                  onTap: widget.onTap,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        // ── Dot indicators ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 20.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.grayLight,
                borderRadius: BorderRadius.circular(100.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}
