import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// IQ Taxi Typography System - extracted from Figma designs
/// Fonts: Almarai (Arabic UI), Outfit (Latin/Numbers), Montserrat (Status bar)
///
/// **No hardcoded colors** — text color is inherited from the current
/// [Theme]'s `colorScheme.onSurface` so dark-mode works automatically.
class AppTypography {
  AppTypography._();

  // ─── Font Families ───
  static const String fontFamilyArabic = 'Almarai';
  static const String fontFamilyLatin = 'Outfit';
  static const String fontFamilyMontserrat = 'Montserrat';

  // ─── Heading Styles ───
  static TextStyle heading1 = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 24.sp,
  );

  static TextStyle heading2 = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 20.sp,
  );

  static TextStyle heading3 = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 18.sp,
  );

  // ─── Body Styles ───
  static TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.normal,
    fontSize: 16.sp,
    height: 1.5,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.normal,
    fontSize: 14.sp,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.normal,
    fontSize: 12.sp,
  );

  // ─── Label Styles ───
  static TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 16.sp,
  );

  static TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 14.sp,
  );

  static TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 12.sp,
  );

  // ─── Button Text ───
  static TextStyle button = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 18.sp,
  );

  // ─── Number/Latin Styles ───
  static TextStyle numberLarge = TextStyle(
    fontFamily: fontFamilyLatin,
    fontWeight: FontWeight.w600,
    fontSize: 20.sp,
  );

  static TextStyle numberMedium = TextStyle(
    fontFamily: fontFamilyLatin,
    fontWeight: FontWeight.normal,
    fontSize: 16.sp,
  );

  static TextStyle numberSmall = TextStyle(
    fontFamily: fontFamilyLatin,
    fontWeight: FontWeight.normal,
    fontSize: 14.sp,
  );

  // ─── Input Styles ───
  static TextStyle inputText = TextStyle(
    fontFamily: fontFamilyLatin,
    fontWeight: FontWeight.normal,
    fontSize: 16.sp,
  );

  static TextStyle inputHint = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.normal,
    fontSize: 16.sp,
    color: AppColors.grayLight,
  );

  // ─── AppBar Title ───
  static TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.bold,
    fontSize: 20.sp,
    color: AppColors.black
  );

  // ─── Caption ───
  static TextStyle caption = TextStyle(
    fontFamily: fontFamilyArabic,
    fontWeight: FontWeight.normal,
    fontSize: 12.sp,
    color: AppColors.gray3,
  );
}
