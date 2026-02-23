import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/data/models/home_data_model.dart';
import '../../domain/repositories/favourite_location_repository.dart';
import '../datasources/favourite_location_data_source.dart';

/// Production implementation of [FavouriteLocationRepository].
class FavouriteLocationRepositoryImpl implements FavouriteLocationRepository {
  final FavouriteLocationDataSource dataSource;

  const FavouriteLocationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<FavouriteLocationModel>>>
      listFavouriteLocations() =>
          dataSource.listFavouriteLocations();

  @override
  Future<Either<Failure, FavouriteLocationModel>> addFavouriteLocation({
    required double lat,
    required double lng,
    required String address,
    required String addressName,
  }) =>
      dataSource.addFavouriteLocation(
        lat: lat,
        lng: lng,
        address: address,
        addressName: addressName,
      );

  @override
  Future<Either<Failure, void>> deleteFavouriteLocation(int id) =>
      dataSource.deleteFavouriteLocation(id);
}
