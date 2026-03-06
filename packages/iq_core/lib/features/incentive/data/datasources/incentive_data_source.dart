import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/incentive_model.dart';

/// Contract for incentive-related API calls.
abstract class IncentiveDataSource {
  /// Fetch incentives.
  ///
  /// [type] — 0 = daily (today), 1 = weekly.
  Future<Either<Failure, IncentiveResponse>> getIncentives({
    required int type,
  });
}
