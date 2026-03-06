import 'dart:math';

/// Geographical utility functions for trip distance calculations.
class GeoUtils {
  GeoUtils._();

  /// Calculate the Haversine distance between two GPS coordinates.
  ///
  /// Returns distance in **kilometres**.
  ///
  /// This matches the old driver app's `calculateDistance()` function.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
