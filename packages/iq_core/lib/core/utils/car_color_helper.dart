import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Shared car-colour lookup used across trip detail, invoice,
/// and active-trip pages.
final Map<String, Color> _carColorMap = <String, Color>{
  // English names
  'red': Colors.red,
  'blue': Colors.blue,
  'green': Colors.green,
  'white': Colors.white,
  'black': Colors.black,
  'yellow': Colors.yellow,
  'orange': Colors.orange,
  'grey': Colors.grey,
  'gray': Colors.grey,
  'silver': Color(0xFFC0C0C0),
  'brown': Colors.brown,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'gold': Color(0xFFFFD700),
  'beige': Color(0xFFF5F5DC),
  // Arabic names
  AppStrings.colorRed: Colors.red,
  AppStrings.colorBlue: Colors.blue,
  AppStrings.colorGreen: Colors.green,
  AppStrings.colorWhite: Colors.white,
  AppStrings.colorBlack: Colors.black,
  AppStrings.colorYellow: Colors.yellow,
  AppStrings.colorOrange: Colors.orange,
  AppStrings.colorGrey: Colors.grey,
  AppStrings.colorSilver: Color(0xFFC0C0C0),
  AppStrings.colorBrown: Colors.brown,
};

/// Returns a [Color] for the given vehicle color name (English or Arabic).
///
/// Falls back to [Colors.grey] when the name is unrecognised.
/// Also handles `#RRGGBB` hex strings.
Color getCarColor(String colorName) {
  final lower = colorName.toLowerCase().trim();
  final match = _carColorMap[lower];
  if (match != null) return match;
  // Try hex
  if (lower.startsWith('#') && lower.length >= 7) {
    final hex = lower.replaceFirst('#', '');
    final parsed = int.tryParse('FF$hex', radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return Colors.grey;
}

/// Returns a [Color] for the given vehicle color name, or `null` if not found.
Color? tryGetCarColor(String? colorName) {
  if (colorName == null || colorName.isEmpty) return null;
  return _carColorMap[colorName.toLowerCase().trim()];
}
