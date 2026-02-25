import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'iq_text.dart';

/// Sidebar menu item data.
class IqSidebarItem {
  const IqSidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Called when the item is tapped.
  ///
  /// Receives the **live** [BuildContext] from the sidebar widget so
  /// [Navigator.of] always uses a mounted context.
  final void Function(BuildContext context) onTap;
}

/// Shared sidebar / drawer for IQ Taxi apps.
///
/// Matches the Figma design: dark background (#000),
/// profile header at the top with avatar, name, subtitle, star rating,
/// followed by a scrollable list of menu items.
class IqSidebar extends StatelessWidget {
  const IqSidebar({
    super.key,
    required this.items,
    this.userName = '',
    this.userSubtitle = '',
    this.userRating = 0.0,
    this.avatarUrl,
    this.onProfileTap,
  });

  final List<IqSidebarItem> items;
  final String userName;
  final String userSubtitle;
  final double userRating;
  final String? avatarUrl;
  final void Function(BuildContext context)? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // ─── Close / menu button ───
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 24.w),
                child: GestureDetector(
                  onTap: () => ZoomDrawer.of(context)?.toggle(),
                  child: Icon(Icons.menu, color: AppColors.white, size: 28.w),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // ─── Profile section ───
            _ProfileHeader(
              userName: userName,
              userSubtitle: userSubtitle,
              userRating: userRating,
              avatarUrl: avatarUrl,
              onTap: onProfileTap,
            ),
            SizedBox(height: 32.h),
            // ─── Menu items ───
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) => _MenuItem(item: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private widgets ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.userSubtitle,
    required this.userRating,
    this.avatarUrl,
    this.onTap,
  });

  final String userName;
  final String userSubtitle;
  final double userRating;
  final String? avatarUrl;
  final void Function(BuildContext context)? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ZoomDrawer.of(context)?.close();
        onTap?.call(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 47.5.w,
              backgroundColor: AppColors.gray3,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, size: 48.w, color: AppColors.white)
                  : null,
            ),
            SizedBox(height: 12.h),
            // Name
            IqText(
              userName,
              style: AppTypography.heading2.copyWith(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Subtitle
            IqText(
              userSubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSubtitle,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            // Rating
            if (userRating > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IqText(
                    userRating.toStringAsFixed(1),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.white,
                      fontFamily: AppTypography.fontFamilyLatin,
                    ),
                    dir: TextDirection.ltr,
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.starFilled,
                    size: 18.w,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});

  final IqSidebarItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ZoomDrawer.of(context)?.close();
        item.onTap(context);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        child: Row(
          children: [
            // Icon on the right side (RTL)
            Icon(item.icon, color: AppColors.white, size: 24.w),
            SizedBox(width: 16.w),
            // Label
            IqText(
              item.label,
              style: AppTypography.labelLarge.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
