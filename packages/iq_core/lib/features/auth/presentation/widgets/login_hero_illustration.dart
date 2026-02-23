import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/iq_image.dart';

/// The welcome illustration shown on the Passenger login page.
///
/// Matches the hero image from Figma node 7:662.
class LoginHeroIllustration extends StatelessWidget {
  const LoginHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360.w,
      height: 276.h,
      child: IqImage(
        AppAssets.loginHero,
        width: 360.w,
        height: 276.h,
        fit: BoxFit.contain,
      ),
    );
  }
}
