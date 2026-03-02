import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/home_data_model.dart';
import '../../data/models/ongoing_ride_model.dart';
import '../../data/models/ride_module_model.dart';

/// Repository contract for home data operations.
abstract class HomeRepository {
  /// Fetch user details from API.
  Future<Either<Failure, HomeDataModel>> getUserDetails();

  /// Toggle driver online/offline status.
  Future<Either<Failure, bool>> toggleDriverStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  /// Fetch available ride modules (service categories) with icon URLs.
  Future<Either<Failure, List<RideModuleModel>>> getRideModules();

  /// Fetch ongoing (active) rides for the current user.
  Future<Either<Failure, List<OngoingRideModel>>> getOngoingRides();
}
