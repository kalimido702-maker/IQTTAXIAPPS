import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/reports_model.dart';

/// Contract for reports-related API calls.
abstract class ReportsDataSource {
  /// Fetch earnings report between [fromDate] and [toDate].
  ///
  /// Dates must be in `yyyy-MM-dd` format.
  /// Calls `GET api/v1/driver/earnings-report/{fromDate}/{toDate}`.
  Future<Either<Failure, ReportsModel>> getEarningsReport({
    required String fromDate,
    required String toDate,
  });
}
