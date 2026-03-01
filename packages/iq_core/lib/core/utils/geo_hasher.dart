/// Lightweight geohash encoder for Firebase driver location nodes.
///
/// Encodes a (longitude, latitude) pair into a base-32 geohash string
/// compatible with the backend's GeoFire-based driver matching.
class GeoHasher {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode [longitude] and [latitude] to a geohash string.
  ///
  /// [precision] controls the length (default 12 chars ≈ ±0.019m).
  /// **Note:** parameter order is (longitude, latitude) — matching the
  /// old app's convention.
  String encode(double longitude, double latitude, {int precision = 12}) {
    double minLat = -90, maxLat = 90;
    double minLng = -180, maxLng = 180;

    final buffer = StringBuffer();
    var bits = 0;
    var currentChar = 0;
    var isLng = true;

    while (buffer.length < precision) {
      if (isLng) {
        final mid = (minLng + maxLng) / 2;
        if (longitude >= mid) {
          currentChar |= 1 << (4 - bits);
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude >= mid) {
          currentChar |= 1 << (4 - bits);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isLng = !isLng;
      bits++;

      if (bits == 5) {
        buffer.write(_base32[currentChar]);
        bits = 0;
        currentChar = 0;
      }
    }

    return buffer.toString();
  }
}
