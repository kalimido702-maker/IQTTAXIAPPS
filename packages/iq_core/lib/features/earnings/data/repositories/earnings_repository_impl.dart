import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/earnings_data_source.dart';
import '../../data/models/weekly_earnings_model.dart';
import '../../domain/repositories/earnings_repository.dart';

/// Production implementation of [EarningsRepository].
class EarningsRepositoryImpl implements EarningsRepository {
  final EarningsDataSource dataSource;

  const EarningsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, WeeklyEarningsModel>> getWeeklyEarnings({
    int? weekNumber,
  }) =>
      dataSource.getWeeklyEarnings(weekNumber: weekNumber);
}
