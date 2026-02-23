import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_data_source.dart';
import '../models/trip_history_model.dart';

/// Production implementation of [TripRepository].
class TripRepositoryImpl implements TripRepository {
  final TripDataSource dataSource;

  const TripRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, TripHistoryResponse>> getTripHistory({
    required int page,
    required String type,
  }) =>
      dataSource.getTripHistory(page: page, type: type);

  @override
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId) =>
      dataSource.getTripDetails(tripId);
}
