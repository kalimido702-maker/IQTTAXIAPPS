import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/reports_model.dart';

/// Repository contract for reports operations.
abstract class ReportsRepository {
  /// Fetch earnings report between [fromDate] and [toDate].
  Future<Either<Failure, ReportsModel>> getEarningsReport({
    required String fromDate,
    required String toDate,
  });
}
