import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/data/models/home_data_model.dart';

/// Repository contract for favourite location operations.
abstract class FavouriteLocationRepository {
  /// Fetch all favourite locations for the authenticated user.
  Future<Either<Failure, List<FavouriteLocationModel>>>
      listFavouriteLocations();

  /// Add a new favourite location.
  Future<Either<Failure, FavouriteLocationModel>> addFavouriteLocation({
    required double lat,
    required double lng,
    required String address,
    required String addressName,
  });

  /// Delete a favourite location by [id].
  Future<Either<Failure, void>> deleteFavouriteLocation(int id);
}
