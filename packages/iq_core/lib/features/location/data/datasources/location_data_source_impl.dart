import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import 'location_data_source.dart';

/// OpenStreetMap (Nominatim) implementation for address search & reverse geocode.
class LocationDataSourceImpl implements LocationDataSource {
  LocationDataSourceImpl({required this.dio});

  final Dio dio;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchPlaces(
    String query,
  ) async {
    try {
      final response = await dio.get(
        '$_nominatimBase/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 10,
        },
        options: Options(
          headers: const {
            'User-Agent': 'iq_taxi_app',
          },
        ),
      );

      final data = response.data;
      if (data is List) {
        final results = data.whereType<Map<String, dynamic>>().map((item) {
          final display = (item['display_name'] ?? '').toString();
          final name = display.split(',').first.trim();
          return {
            'name': name.isNotEmpty ? name : display,
            'address': display,
            'lat': double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0,
            'lng': double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0,
          };
        }).toList();
        return Right(results);
      }

      return const Left(ServerFailure(message: 'فشل البحث عن الأماكن'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
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
          'latitude': latitude,
          'longitude': longitude,
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
