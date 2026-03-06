import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/incentive_model.dart';

/// Repository contract for incentive operations.
abstract class IncentiveRepository {
  /// Fetch incentives.
  ///
  /// [type] — 0 = daily, 1 = weekly.
  Future<Either<Failure, IncentiveResponse>> getIncentives({
    required int type,
  });
}
