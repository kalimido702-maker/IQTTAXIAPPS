import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../home/data/models/home_data_model.dart';
import 'favourite_location_data_source.dart';

/// Production implementation of [FavouriteLocationDataSource].
class FavouriteLocationDataSourceImpl implements FavouriteLocationDataSource {
  final Dio dio;

  FavouriteLocationDataSourceImpl({required this.dio});

  // ─────────────────────────── LIST ───────────────────────────

  @override
  Future<Either<Failure, List<FavouriteLocationModel>>>
      listFavouriteLocations() async {
    try {
      final response =
          await dio.get('api/v1/user/list-favourite-location');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final listData = body['data'];
        if (listData is List) {
          return Right(
            listData
                .whereType<Map<String, dynamic>>()
                .map(FavouriteLocationModel.fromJson)
                .toList(),
          );
        }
        return const Right([]);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToLoadFavourites,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────── ADD ────────────────────────────

  @override
  Future<Either<Failure, FavouriteLocationModel>> addFavouriteLocation({
    required double lat,
    required double lng,
    required String address,
    required String addressName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'pick_lat': lat,
        'pick_lng': lng,
        'pick_address': address,
        'address_name': addressName,
      });

      final response = await dio.post(
        'api/v1/user/add-favourite-location',
        data: formData,
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final locData = body['data'] as Map<String, dynamic>? ?? {};
        return Right(FavouriteLocationModel.fromJson(locData));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToAddLocation,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ────────────────────────── DELETE ──────────────────────────

  @override
  Future<Either<Failure, void>> deleteFavouriteLocation(int id) async {
    try {
      final response = await dio.get(
        'api/v1/user/delete-favourite-location/$id',
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToDeleteLocation,
        statusCode: response.statusCode,
      ));
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
      return NetworkFailure(message: AppStrings.connectionTimeout);
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure();
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ServerFailure(
        message: data['message']?.toString() ?? AppStrings.serverError,
        statusCode: e.response?.statusCode,
      );
    }
    return ServerFailure(
      message: e.message ?? AppStrings.serverError,
      statusCode: e.response?.statusCode,
    );
  }
}
