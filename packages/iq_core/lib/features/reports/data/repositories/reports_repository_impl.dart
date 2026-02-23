import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/reports_data_source.dart';
import '../../data/models/reports_model.dart';
import '../../domain/repositories/reports_repository.dart';

/// Production implementation of [ReportsRepository].
class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDataSource dataSource;

  const ReportsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, ReportsModel>> getEarningsReport({
    required String fromDate,
    required String toDate,
  }) =>
      dataSource.getEarningsReport(fromDate: fromDate, toDate: toDate);
}
