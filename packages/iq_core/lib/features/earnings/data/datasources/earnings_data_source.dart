import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/weekly_earnings_model.dart';

/// Contract for earnings-related API calls.
abstract class EarningsDataSource {
  /// Fetch weekly earnings.
  ///
  /// [weekNumber] — optional week-of-year; defaults to current week.
  /// Calls `GET api/v1/driver/weekly-earnings`.
  Future<Either<Failure, WeeklyEarningsModel>> getWeeklyEarnings({
    int? weekNumber,
  });
}
