import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_typography.dart';
import 'iq_text.dart';

/// Custom AppBar matching IQ Taxi Figma design
/// White background, centered Arabic title, back arrow
class IqAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const IqAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (onBackPressed != null) {
                  onBackPressed!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24.w,
              ),
            )
          : null,
      title: IqText(
        title,
        style: AppTypography.appBarTitle,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
