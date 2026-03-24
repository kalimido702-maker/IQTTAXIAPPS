import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../home/data/models/home_data_model.dart';

/// A single favourite location tile with icon, title, address, and delete.
///
/// Extracted from [FavouriteLocationPage] per project rules.
class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.address,
    this.iconColor,
    this.onDelete,
    this.showDelete = true,
  });

  /// Convenience constructor from a [FavouriteLocationModel].
  factory LocationTile.fromModel({
    Key? key,
    required FavouriteLocationModel model,
    required IconData icon,
    required String title,
    Color? iconColor,
    VoidCallback? onDelete,
  }) {
    return LocationTile(
      key: key,
      icon: icon,
      title: title,
      address: model.address,
      iconColor: iconColor,
      onDelete: onDelete,
    );
  }

  final IconData icon;
  final String title;
  final String address;
  final Color? iconColor;
  final VoidCallback? onDelete;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ──
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkInputBg
                      : AppColors.grayLightBg,
                ),
                child: Icon(
                  icon,
                  size: 24.w,
                  color: iconColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 10.w),

              // ── Text content ──
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IqText(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    IqText(
                      address,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textAddress,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Delete button ──
              // if (showDelete)
                GestureDetector(
                  onTap: onDelete == null ? null : () { HapticFeedback.mediumImpact(); onDelete!(); },
                  child: Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Icon(
                      Icons.close,
                      size: 18.w,
                      color: AppColors.error,
                    ),
                  ),
                ),
              // else
              //   SizedBox(width: 18.w),

            ],
          ),
        ),
        Divider(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkDivider
              : AppColors.grayBorder,
          height: 1.h,
        ),
      ],
    );
  }
}
