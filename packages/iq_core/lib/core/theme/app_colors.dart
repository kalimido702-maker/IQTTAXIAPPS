import 'package:flutter/material.dart';

/// IQ Taxi Color System - extracted from Figma designs
/// Both Passenger & Driver apps share the same color palette
class AppColors {
  AppColors._();

  // ─── Primary (Yellow/Gold) ───
  static const Color primary = Color(0xFFFEC400);
  static const Color primaryDark = Color(0xFFEDAE10);
  static const Color primaryLight = Color(0xFFF5BF28);
  static const Color primary50 = Color(0xFFFFFBE7);
  static const Color primary100 = Color(0xFFFFF1B1);
  static const Color primary200 = Color(0xFFFFE773);
  static const Color primary500 = Color(0xFFF5C73F);
  static const Color primary600 = Color(0xFFF5BF28);
  static const Color primary700 = Color(0xFFEDAE10);
  static const Color buttonYellow = Color(0xFFFFCC00);

  // ─── Base Colors ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color background = Color(0xFFF0ECE0);
  static const Color splashBackground = Color(0xFFF0ECE0);
  static const Color splashGradientLight = Color(0xFFF5F1EB);
  static const Color scaffoldBackground = Color(0xFFFFFFFF);

  // ─── Grays ───
  static const Color gray1 = Color(0xFFBDBDBD);
  static const Color gray2 = Color(0xFFA2A2A2);
  static const Color gray3 = Color(0xFF5C5C5C);
  static const Color grayLight = Color(0xFFAAAAAA);
  static const Color grayBorder = Color(0xFFE0E0E0);
  static const Color grayDivider = Color(0xFFF5F5F5);
  static const Color grayInactive = Color(0xFFD2D6DB);
  static const Color grayPlaceholder = Color(0xFF9E9E9E);

  // ─── Text Colors ───
  static const Color textDark = Color(0xFF1A212F);
  static const Color textDarkAlt = Color(0xFF1F2A37);
  static const Color textSubtitle = Color(0xFF575757);
  static const Color textHint = Color(0xFF777C83);

  // ─── Driver Status ───
  static const Color driverOnline = Color(0xFF118F28);
  static const Color driverOffline = Color(0xFFE53935);

  // ─── Drawer ───
  static const Color drawerShadow = Color(0xFF1A1A1A);

  // ─── Status Colors ───
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF388E3C);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ─── Online Status ───
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFFE53935);
  static const Color busy = Color(0xFFFF9800);

  // ─── Map ───
  static const Color pickupMarker = Color(0xFF4CAF50);
  static const Color dropoffMarker = Color(0xFFE53935);
  static const Color routeLine = Color(0xFF1A1A1A);

  // ─── Rating ───
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // ─── Additional Text/UI Colors ───
  static const Color textNearBlack = Color(0xFF030303);
  static const Color textSecondary = Color(0xFF535353);
  static const Color textAddress = Color(0xFF414141);
  static const Color textMuted = Color(0xFF747474);
  static const Color grayDate = Color(0xFF868686);
  static const Color grayLightBg = Color(0xFFF1F1F1);
  static const Color cardBackground = Color(0xFFFBFBFB);

  // ─── Shadow ───
  static const Color shadow = Color(0x40000000); // 25% black
  static const Color shadowLight = Color(0x1A000000); // 10% black

  // ─── Misc UI ───
  static const Color dragHandle = Color(0xFFD9D9D9);
  static const Color inputFill = Color(0xFFF4F5F6);
  static const Color grayCapacity = Color(0xFFA5A5A5);

  // ─── Input Field ───
  static const Color inputBorder = Color(0xFFFEB800);
  static const Color inputFocusBorder = Color(0xFFFEC400);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputHintColor = Color(0xFFAAAAAA);

  // ─── Wallet ───
  static const Color walletSubtitle = Color(0xFFC8C7CC);
  static const Color cancelRed = Color(0xFFFF0C0C);
  static const Color chipBorder = Color(0xFFD1D1D1);
  static const Color chipText = Color(0xFF7A7A7A);
  static const Color transactionCredit = Color(0xFF4CAF50);
  static const Color transactionDebit = Color(0xFFE53935);

  // ─── Trip Status ───
  static const Color statusCompletedBg = Color(0xFFE8FCF1);
  static const Color statusCompletedText = Color(0xFF18C161);
  static const Color statusCompletedBorder = Color(0xFFD9F4E5);
  static const Color statusCancelledBg = Color(0xFFFDECEF);
  static const Color statusCancelledText = Color(0xFFF52D56);
  static const Color statusCancelledBorder = Color(0xFFFCCDD6);
  static const Color statusOngoingBg = Color(0xFFECE8FC);
  static const Color statusOngoingText = Color(0xFF7253E5);
  static const Color statusOngoingBorder = Color(0xFFB6C5F8);

  // ─── Map Markers ───
  static const Color markerRed = Color(0xFFF52D56);
  static const Color markerGreen = Color(0xFF18C161);
  static const Color markerBlue = Color(0xFF1B18C1);
  static const Color markerTeal = Color(0xFF4CD7A0);
  static const Color circleBlue = Color(0xFF3F51B5);

  // ─── Badges / Tags ───
  static const Color taxiBadge = Color(0xFFBA9500);
  static const Color deliveryBadge = Color(0xFF0E9347);
  static const Color starRating = Color(0xFFFEB800);
  static const Color iraqFlagRed = Color(0xFFCE1126);

  // ─── Chat ───
  static const Color chatSubtitle = Color(0xFFBBC1CE);
  static const Color chatTimestamp = Color(0xFF9DA4AE);
  static const Color chatInputHint = Color(0xFFB8B8B8);
  static const Color chatShadow = Color(0x11000000);

  // ─── Incentive Page ───
  static const Color incentiveHeaderDark = Color(0xFF0A1F2E);
  static const Color incentiveSuccess = Color(0xFF2E7D32);
  static const Color incentivePartial = Color(0xFFE65100);

  // ─── Dark Mode Surfaces ───
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkInputBg = Color(0xFF2A2A2A);
  static const Color darkDivider = Color(0xFF3A3A3A);
  static const Color darkGray = Color(0xFF9E9E9E);

  // ─── Shimmer ───
  static const Color shimmerBase = Color(0xFFE0E0E0); // grey.shade300
  static const Color shimmerHighlight = Color(0xFFF5F5F5); // grey.shade100
  static const Color shimmerBaseDark = Color(0xFF616161); // grey.shade700
  static const Color shimmerHighlightDark = Color(0xFF757575); // grey.shade600

  // ─── Additional UI ───
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);
  static const Color beige = Color(0xFFF5F5DC);
  static const Color fareGreen = Color(0xFF669C1A);
  static const Color dividerLight = Color(0xFFDADADA);
  static const Color inactiveBar = Color(0xFFD9D9D9);
  static const Color markerText = Color(0xFF1A1A1A);
  static const Color carMarkerDark = Color(0xFF242E42);
  static const Color overlayDark = Color(0xCC000000);
  static const Color amber = Color(0xFFFFC107);
  static const Color muted = Color(0xFF595959);

  // ─── Google Brand Colors ───
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleRed = Color(0xFFEA4335);

  // ─── Overlay / Shadows ───
  static const Color shadow25 = Color(0x40000000); // 25% black
  static const Color shadow20 = Color(0x33000000); // 20% black
  static const Color shadow10 = Color(0x1A000000); // 10% black
  static const Color shadow06 = Color(0x0F000000); // 6% black
  static const Color shadow55 = Color(0x8C000000); // 55% black
  static const Color overlay50 = Color(0x80000000); // 50% black
}
