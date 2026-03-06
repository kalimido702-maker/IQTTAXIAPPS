import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/incentive_model.dart';
import '../../domain/repositories/incentive_repository.dart';
import '../datasources/incentive_data_source.dart';

/// Implementation of [IncentiveRepository].
class IncentiveRepositoryImpl implements IncentiveRepository {
  final IncentiveDataSource dataSource;

  IncentiveRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, IncentiveResponse>> getIncentives({
    required int type,
  }) {
    return dataSource.getIncentives(type: type);
  }
}
