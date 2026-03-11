import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';

/// A promotional banner card displayed below the search bar on the home page.
///
/// Supports two modes:
///   1. **Network image** — if [imageUrl] is provided, renders the remote image
///      covering the full card area (backward compatible with API banners).
///   2. **Rich card** — if [imageUrl] is null, renders a styled design-studio
///      card with [title], [subtitle], [statValue], and decorative accents.
class PromoBannerCard extends StatelessWidget {
  const PromoBannerCard({
    super.key,
    this.imageUrl,
    this.assetImage,
    this.title,
    this.subtitle,
    this.statValue,
    this.statLabel,
    this.onTap,
  });

  /// Network image URL — when provided, renders as a full-bleed image banner.
  final String? imageUrl;

  /// Local asset path — used as fallback when [imageUrl] is null.
  final String? assetImage;

  /// Main headline text (e.g. "رحلتك الأولى مجاناً").
  final String? title;

  /// Secondary descriptive text below the title.
  final String? subtitle;

  /// Big stat number displayed in the highlight bubble (e.g. "200K").
  final String? statValue;

  /// Small label below the stat (e.g. "رحلة مكتملة").
  final String? statLabel;

  /// Called when the user taps the banner.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: _hasNetworkImage
          ? _buildImageBanner(imageUrl!)
          : _hasAssetImage
              ? _buildImageBanner(assetImage!)
              : _buildRichBanner(isDark),
    );
  }

  bool get _hasNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get _hasAssetImage => assetImage != null && assetImage!.isNotEmpty;

  /// Full-bleed image banner (network or asset).
  Widget _buildImageBanner(String source) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: IqImage(
        source,
        height: 130.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Mode 2 — rich designed banner (inspired by design-studio style).
  Widget _buildRichBanner(bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final textColor = isDark ? AppColors.white : AppColors.textDark;
    final subtitleColor = isDark ? AppColors.white.withValues(alpha: 0.70) : AppColors.textHint;

    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // ── Decorative yellow accent (top-left circle) ──
            Positioned(
              top: -30.h,
              left: -20.w,
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),

            // ── Decorative yellow accent (bottom-right circle) ──
            Positioned(
              bottom: -40.h,
              right: -25.w,
              child: Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ── Yellow accent stripe on the left ──
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    bottomLeft: Radius.circular(16.r),
                  ),
                ),
              ),
            ),

            // ── Content ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  // Left: text content
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        IqText(
                          title ?? AppStrings.firstTripFree,
                          style: AppTypography.heading3.copyWith(
                            color: textColor,
                            fontSize: 17.sp,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        // Subtitle
                        IqText(
                          subtitle ?? AppStrings.firstTripFreeSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: subtitleColor,
                            fontSize: 12.sp,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Right: stat bubble
                  if (statValue != null) _buildStatBubble(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBubble(bool isDark) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IqText(
            statValue!,
            style: AppTypography.numberLarge.copyWith(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          if (statLabel != null)
            IqText(
              statLabel!,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 9.sp,
                color: AppColors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}
