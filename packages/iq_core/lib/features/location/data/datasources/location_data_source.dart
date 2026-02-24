import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Remote data source for location operations (search + reverse geocode).
abstract class LocationDataSource {
  Future<Either<Failure, List<Map<String, dynamic>>>> searchPlaces(
    String query,
  );

  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });
}
