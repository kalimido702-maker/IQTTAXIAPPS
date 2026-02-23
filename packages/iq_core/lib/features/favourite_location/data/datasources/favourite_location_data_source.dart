import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../home/data/models/home_data_model.dart';

/// Contract for favourite location API calls.
abstract class FavouriteLocationDataSource {
  /// Fetch all favourite locations for the authenticated user.
  ///
  /// Calls `GET api/v1/user/list-favourite-location`.
  Future<Either<Failure, List<FavouriteLocationModel>>>
      listFavouriteLocations();

  /// Add a new favourite location.
  ///
  /// Calls `POST api/v1/user/add-favourite-location`.
  Future<Either<Failure, FavouriteLocationModel>> addFavouriteLocation({
    required double lat,
    required double lng,
    required String address,
    required String addressName,
  });

  /// Delete a favourite location by [id].
  ///
  /// Calls `GET api/v1/user/delete-favourite-location/{id}`.
  Future<Either<Failure, void>> deleteFavouriteLocation(int id);
}
