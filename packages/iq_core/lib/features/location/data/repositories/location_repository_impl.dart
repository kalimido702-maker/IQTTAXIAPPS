import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

/// Production implementation of [LocationRepository].
class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl({required this.dataSource});

  final LocationDataSource dataSource;

  @override
  Future<Either<Failure, (double, double)>> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return Left(PermissionFailure(message: AppStrings.locationPermissionDenied));
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return Right((pos.latitude, pos.longitude));
    } catch (e) {
      return Left(LocationFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const Right(false);
      }
      return const Right(true);
    } catch (e) {
      return Left(PermissionFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  }) {
    return dataSource.updateLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) {
    return dataSource.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchPlaces(
    String query,
  ) {
    return dataSource.searchPlaces(query);
  }
}
