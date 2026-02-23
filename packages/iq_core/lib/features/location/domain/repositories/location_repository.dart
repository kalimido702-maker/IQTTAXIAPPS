import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Location service contract
abstract class LocationRepository {
  /// Get current location (lat, lng)
  Future<Either<Failure, (double, double)>> getCurrentLocation();

  /// Update driver location (driver app)
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  });

  /// Get address from coordinates (reverse geocoding)
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Search for places by query
  Future<Either<Failure, List<Map<String, dynamic>>>> searchPlaces(
    String query,
  );

  /// Check & request location permission
  Future<Either<Failure, bool>> checkLocationPermission();
}
