import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result from a Google Directions API call.
class DirectionsResult {
  const DirectionsResult({
    required this.polylinePoints,
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    required this.boundsNE,
    required this.boundsSW,
  });

  /// Decoded list of LatLng points for drawing on the map.
  final List<LatLng> polylinePoints;

  /// The raw encoded polyline string (for sending to backend).
  final String encodedPolyline;

  /// Total distance in meters.
  final int distanceMeters;

  /// Human-readable distance (e.g., "12.3 km").
  final String distanceText;

  /// Total duration in seconds.
  final int durationSeconds;

  /// Human-readable duration (e.g., "18 mins").
  final String durationText;

  /// Northeast corner of the route bounds.
  final LatLng boundsNE;

  /// Southwest corner of the route bounds.
  final LatLng boundsSW;

  /// Distance in kilometers.
  double get distanceKm => distanceMeters / 1000.0;

  /// Duration in minutes.
  double get durationMinutes => durationSeconds / 60.0;
}

/// High-performance Google Maps web service client.
///
/// Uses the **Directions API** for accurate routing, distances, durations,
/// and encoded polylines — exactly like Uber.
///
/// Performance notes:
/// - Uses a dedicated [Dio] instance with short timeouts.
/// - Responses are parsed once; polyline is decoded in O(n).
/// - Singleton in DI — no re-creation overhead.
class GoogleMapsService {
  GoogleMapsService({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://maps.googleapis.com/maps/api/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final String apiKey;
  final Dio _dio;

  // ─── Directions API ──────────────────────────────────────────────

  /// Get driving directions between two points.
  ///
  /// Returns accurate route polyline, distance, and duration
  /// calculated by Google's routing engine.
  ///
  /// [waypoints] — optional intermediate stops (max 25).
  /// [alternatives] — whether to return alternative routes.
  /// [avoidTolls], [avoidHighways] — routing preferences.
  Future<DirectionsResult?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<LatLng>? waypoints,
    bool alternatives = false,
    bool avoidTolls = false,
    bool avoidHighways = false,
    String language = 'ar',
  }) async {
    try {
      final avoid = <String>[];
      if (avoidTolls) avoid.add('tolls');
      if (avoidHighways) avoid.add('highways');

      final params = <String, dynamic>{
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': 'driving',
        'language': language,
        'key': apiKey,
      };

      if (alternatives) params['alternatives'] = 'true';
      if (avoid.isNotEmpty) params['avoid'] = avoid.join('|');

      if (waypoints != null && waypoints.isNotEmpty) {
        params['waypoints'] = waypoints
            .map((w) => '${w.latitude},${w.longitude}')
            .join('|');
      }

      final response = await _dio.get(
        'directions/json',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') return null;

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List?;
      if (legs == null || legs.isEmpty) return null;

      // Aggregate distance and duration across all legs.
      int totalDistanceM = 0;
      int totalDurationS = 0;
      String distanceText = '';
      String durationText = '';

      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        totalDistanceM +=
            (legMap['distance']?['value'] as int?) ?? 0;
        totalDurationS +=
            (legMap['duration']?['value'] as int?) ?? 0;
      }

      // Use the summary texts from the first leg.
      final firstLeg = legs.first as Map<String, dynamic>;
      distanceText =
          firstLeg['distance']?['text']?.toString() ?? '${(totalDistanceM / 1000).toStringAsFixed(1)} km';
      durationText =
          firstLeg['duration']?['text']?.toString() ?? '${(totalDurationS / 60).round()} min';

      // Overview polyline — accurate enough and much lighter than
      // concatenating per-step polylines.
      final overviewPoly =
          route['overview_polyline']?['points'] as String? ?? '';

      final polylinePoints = decodePolyline(overviewPoly);

      // Bounds
      final bounds = route['bounds'] as Map<String, dynamic>?;
      final ne = bounds?['northeast'] as Map<String, dynamic>?;
      final sw = bounds?['southwest'] as Map<String, dynamic>?;

      return DirectionsResult(
        polylinePoints: polylinePoints,
        encodedPolyline: overviewPoly,
        distanceMeters: totalDistanceM,
        distanceText: distanceText,
        durationSeconds: totalDurationS,
        durationText: durationText,
        boundsNE: LatLng(
          (ne?['lat'] as num?)?.toDouble() ?? destLat,
          (ne?['lng'] as num?)?.toDouble() ?? destLng,
        ),
        boundsSW: LatLng(
          (sw?['lat'] as num?)?.toDouble() ?? originLat,
          (sw?['lng'] as num?)?.toDouble() ?? originLng,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Polyline Decoder ────────────────────────────────────────────

  /// Decodes an encoded polyline string into a list of [LatLng] points.
  ///
  /// Uses the Google Encoded Polyline Algorithm:
  /// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  ///
  /// Time complexity: O(n) where n is the encoded string length.
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude.
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude.
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
