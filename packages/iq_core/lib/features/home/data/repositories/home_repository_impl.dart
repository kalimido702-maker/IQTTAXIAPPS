import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/home_data_source.dart';
import '../../data/models/home_data_model.dart';
import '../../data/models/ride_module_model.dart';
import '../../domain/repositories/home_repository.dart';

/// Production implementation of [HomeRepository].
///
/// Delegates to [HomeDataSource].
class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource dataSource;

  const HomeRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, HomeDataModel>> getUserDetails() =>
      dataSource.getUserDetails();

  @override
  Future<Either<Failure, bool>> toggleDriverStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  }) =>
      dataSource.toggleDriverStatus(
        isOnline: isOnline,
        lat: lat,
        lng: lng,
      );

  @override
  Future<Either<Failure, List<RideModuleModel>>> getRideModules() =>
      dataSource.getRideModules();
}
