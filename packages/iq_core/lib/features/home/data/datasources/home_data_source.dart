import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/home_data_model.dart';
import '../models/ride_module_model.dart';

/// Contract for fetching home screen data from the API.
///
/// Shared between passenger and driver features.
abstract class HomeDataSource {
  /// Fetch user details including profile, banners, favourites,
  /// feature flags, and (for drivers) earnings/vehicle info.
  ///
  /// Calls `GET api/v1/user`.
  Future<Either<Failure, HomeDataModel>> getUserDetails();

  /// Toggle driver online/offline status.
  ///
  /// Calls `POST api/v1/driver/online-offline`.
  Future<Either<Failure, bool>> toggleDriverStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  /// Fetch available ride modules (service categories) with icon URLs.
  ///
  /// Calls `GET api/v1/common/ride_modules`.
  Future<Either<Failure, List<RideModuleModel>>> getRideModules();
}
