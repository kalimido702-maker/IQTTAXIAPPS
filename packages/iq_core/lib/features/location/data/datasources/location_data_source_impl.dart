import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/google_maps_service.dart';
import 'location_data_source.dart';

/// Location data source — uses Google Places Autocomplete for search
/// and Nominatim for reverse geocoding.
class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl({
    required this.dio,
    required this.googleMapsService,
  });

  final Dio dio;
  final GoogleMapsService googleMapsService;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchPlaces(
    String query,
  ) async {
    debugPrint('🔍 [searchPlaces] query="$query" → using Google Places');
    try {
      final results = await googleMapsService.searchPlaces(query);
      debugPrint('🔍 [searchPlaces] Google Places returned ${results.length} results');
      for (final r in results) {
        debugPrint('🔍 [searchPlaces]   → ${r['name']} (${r['lat']}, ${r['lng']})');
      }

      if (results.isNotEmpty) {
        return Right(results);
      }

      // Fallback: if Google returns empty, return empty list
      debugPrint('🔍 [searchPlaces] Google returned 0 results');
      return const Right([]);
    } catch (e) {
      debugPrint('🔍 [searchPlaces] ❌ Google Places error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/user/update-location',
        data: {
          'current_lat': latitude,
          'current_lng': longitude,
        },
      );

      final body = response.data;
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'فشل تحديث الموقع'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.get(
        '$_nominatimBase/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'json',
        },
        options: Options(
          headers: const {
            'User-Agent': 'iq_taxi_app',
          },
        ),
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final address = (map['display_name'] ?? '').toString();
        return Right(address.isNotEmpty ? address : 'الموقع الحالي');
      }

      return const Left(ServerFailure(message: 'فشل في تحديد العنوان'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(message: 'انتهت مهلة الاتصال');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    return const ServerFailure(message: 'حدث خطأ في الخادم');
  }
}
