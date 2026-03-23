import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';

/// Rounded-square button used for the hamburger menu on the home page.
///
/// Matches the Figma design: white surface, soft shadow, rounded rectangle
/// with the three-bar (≡) icon.
class IqMenuButton extends StatelessWidget {
  const IqMenuButton({
    super.key,
    required this.onTap,
    this.size,
    this.icon = Icons.menu,
  });

  final VoidCallback onTap;
  final double? size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 46.w;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: s * 0.5,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
