import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/weekly_earnings_model.dart';

/// Repository contract for earnings operations.
abstract class EarningsRepository {
  /// Fetch weekly earnings, optionally for a specific [weekNumber].
  Future<Either<Failure, WeeklyEarningsModel>> getWeeklyEarnings({
    int? weekNumber,
  });
}
