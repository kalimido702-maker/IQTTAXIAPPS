import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single turn-by-turn navigation step.
class NavigationStep {
  const NavigationStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
  });

  /// Human-readable instruction (e.g., "انعطف يسارًا").
  final String instruction;

  /// Maneuver type from Routes API (e.g., "TURN_LEFT", "STRAIGHT", "UTURN_RIGHT").
  final String maneuver;

  /// Distance of this step in meters.
  final int distanceMeters;
}

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
    this.steps = const [],
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

  /// Turn-by-turn navigation steps.
  final List<NavigationStep> steps;

  /// Distance in kilometers.
  double get distanceKm => distanceMeters / 1000.0;

  /// Duration in minutes.
  double get durationMinutes => durationSeconds / 60.0;
}

/// High-performance Google Maps web service client.
///
/// Uses the **Routes API v2** for accurate routing, distances, durations,
/// and encoded polylines — exactly like the old app and backend server.
///
/// Performance notes:
/// - Uses dedicated [Dio] instances with short timeouts.
/// - Responses are parsed once; polyline is decoded in O(n).
/// - Singleton in DI — no re-creation overhead.
class GoogleMapsService {
  GoogleMapsService({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://maps.googleapis.com/maps/api/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        _routesDio = Dio(BaseOptions(
          baseUrl: 'https://routes.googleapis.com/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  final String apiKey;
  final Dio _dio;
  final Dio _routesDio;

  // ─── Routes API v2 ──────────────────────────────────────────────

  /// Get driving directions between two points using Google Routes API v2.
  ///
  /// This matches the exact API used by the old app and the backend server,
  /// ensuring consistent routes and fare calculations.
  ///
  /// Returns accurate route polyline, distance, and duration
  /// calculated by Google's routing engine with TRAFFIC_AWARE preference.
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
      // Build intermediates (waypoints) if any.
      final intermediates = <Map<String, dynamic>>[];
      if (waypoints != null && waypoints.isNotEmpty) {
        for (final wp in waypoints) {
          intermediates.add({
            'location': {
              'latLng': {
                'latitude': wp.latitude,
                'longitude': wp.longitude,
              },
            },
          });
        }
      }

      final body = <String, dynamic>{
        'origin': {
          'location': {
            'latLng': {'latitude': originLat, 'longitude': originLng},
          },
        },
        'destination': {
          'location': {
            'latLng': {'latitude': destLat, 'longitude': destLng},
          },
        },
        if (intermediates.isNotEmpty) 'intermediates': intermediates,
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'computeAlternativeRoutes': alternatives,
        'routeModifiers': {
          'avoidTolls': avoidTolls,
          'avoidHighways': avoidHighways,
          'avoidFerries': false,
        },
        'languageCode': language,
        'units': 'METRIC',
      };

      // Build platform-specific headers for API key restrictions.
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.viewport,routes.legs.steps.navigationInstruction,routes.legs.steps.distanceMeters',
      };

      final response = await _routesDio.post(
        'directions/v2:computeRoutes',
        data: body,
        options: Options(headers: headers),
      );

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;

      // Distance in meters.
      final distanceMeters = (route['distanceMeters'] as num?)?.toInt() ?? 0;

      // Duration — comes as a string like "1436s".
      final durationStr = (route['duration'] as String?) ?? '0s';
      final durationSeconds =
          int.tryParse(durationStr.replaceAll('s', '')) ?? 0;

      // Encoded polyline.
      final encodedPolyline =
          (route['polyline']?['encodedPolyline'] as String?) ?? '';
      final polylinePoints = decodePolyline(encodedPolyline);

      // Viewport bounds.
      final viewport = route['viewport'] as Map<String, dynamic>?;
      final low = viewport?['low'] as Map<String, dynamic>?;
      final high = viewport?['high'] as Map<String, dynamic>?;

      // Generate human-readable texts.
      final distanceText =
          '${(distanceMeters / 1000).toStringAsFixed(1)} km';
      final durationText =
          '${(durationSeconds / 60).round()} min';

      // Parse turn-by-turn navigation steps from legs.
      final steps = <NavigationStep>[];
      final legs = route['legs'] as List?;
      if (legs != null) {
        for (final leg in legs) {
          final legSteps = (leg as Map<String, dynamic>)['steps'] as List?;
          if (legSteps != null) {
            for (final s in legSteps) {
              final step = s as Map<String, dynamic>;
              final nav =
                  step['navigationInstruction'] as Map<String, dynamic>?;
              if (nav != null) {
                steps.add(NavigationStep(
                  instruction: (nav['instructions'] as String?) ?? '',
                  maneuver: (nav['maneuver'] as String?) ?? '',
                  distanceMeters:
                      (step['distanceMeters'] as num?)?.toInt() ?? 0,
                ));
              }
            }
          }
        }
      }

      return DirectionsResult(
        polylinePoints: polylinePoints,
        encodedPolyline: encodedPolyline,
        distanceMeters: distanceMeters,
        distanceText: distanceText,
        durationSeconds: durationSeconds,
        durationText: durationText,
        boundsNE: LatLng(
          (high?['latitude'] as num?)?.toDouble() ?? destLat,
          (high?['longitude'] as num?)?.toDouble() ?? destLng,
        ),
        boundsSW: LatLng(
          (low?['latitude'] as num?)?.toDouble() ?? originLat,
          (low?['longitude'] as num?)?.toDouble() ?? originLng,
        ),
        steps: steps,
      );
    } catch (e) {
      debugPrint('❌ [GoogleMapsService] Routes API v2 failed: $e');
      return null;
    }
  }

  // ─── Places Autocomplete API ─────────────────────────────────────

  /// Search for places using Google Places Autocomplete.
  ///
  /// Returns a list of place predictions with name, address, lat, lng.
  /// Uses [locationBias] to bias results near the user's location.
  Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
    String language = 'ar',
  }) async {
    try {
      final params = <String, dynamic>{
        'input': query,
        'key': apiKey,
        'language': language,
      };

      // Bias results near user's location (100km radius)
      if (lat != null && lng != null) {
        params['location'] = '$lat,$lng';
        params['radius'] = '100000';
      }

      final response = await _dio.get(
        'place/autocomplete/json',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK' && status != 'ZERO_RESULTS') return [];

      final predictions = data['predictions'] as List? ?? [];
      final results = <Map<String, dynamic>>[];

      for (final pred in predictions) {
        final p = pred as Map<String, dynamic>;
        final placeId = p['place_id'] as String?;
        final mainText =
            (p['structured_formatting']?['main_text'] ?? '').toString();
        final fullText = (p['description'] ?? '').toString();

        if (placeId == null) continue;

        // Get lat/lng from Place Details API
        final details = await _getPlaceDetails(placeId);

        results.add({
          'name': mainText.isNotEmpty ? mainText : fullText,
          'address': fullText,
          'lat': details?['lat'] ?? 0.0,
          'lng': details?['lng'] ?? 0.0,
          'place_id': placeId,
        });
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Get the lat/lng for a place by its placeId.
  Future<Map<String, double>?> _getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry',
          'key': apiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final location =
          data['result']?['geometry']?['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      return {
        'lat': (location['lat'] as num).toDouble(),
        'lng': (location['lng'] as num).toDouble(),
      };
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
