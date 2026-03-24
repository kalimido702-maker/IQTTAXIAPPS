import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_image.dart';
import '../../../../core/widgets/iq_text.dart';

/// A single service category card (e.g. تاكسي, مندوبك, تاكسيVIP, محافظات).
///
/// Matches the Figma design: 90×100 rounded card with an image on top
/// and label below. Active card has filled yellow (#FFCC00) background,
/// inactive has white background with #FFCC00 border.
///
/// Supports both network images ([imageUrl]) and local assets ([imagePath]).
/// Network images take priority when provided.
class ServiceCategoryCard extends StatelessWidget {
  const ServiceCategoryCard({
    super.key,
    required this.label,
    this.imagePath,
    this.imageUrl,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final String? imagePath;
  final String? imageUrl;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap!(); },
      child: Container(
        width: 90.w,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.buttonYellow
              : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive
                ? AppColors.buttonYellow
                : (isDark ? AppColors.darkDivider : AppColors.buttonYellow),
            width: isActive ? 0 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.buttonYellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Car image — prefer network URL, fallback to asset
            _buildImage(),
            SizedBox(height: 4.h),
            // Label
            IqText(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppColors.black
                    : (isDark ? AppColors.white : null),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Prefer network URL, then local asset, then icon fallback
    final source = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl!
        : (imagePath != null && imagePath!.isNotEmpty)
            ? imagePath!
            : null;

    if (source != null) {
      return IqImage(
        source,
        width: 90.w,
        height: 60.h,
        fit: BoxFit.contain,
        errorWidget: _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.local_taxi,
      size: 42.w,
      color: isActive ? AppColors.black : AppColors.buttonYellow,
    );
  }
}
