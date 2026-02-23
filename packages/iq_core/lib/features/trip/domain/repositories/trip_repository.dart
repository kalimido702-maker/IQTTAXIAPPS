import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/trip_history_model.dart';
import '../entities/trip_entity.dart';

/// Trip repository contract (Domain layer)
abstract class TripRepository {
  /// Get trip history with pagination and status filter.
  ///
  /// [type] must be one of: `"is_completed"`, `"is_cancelled"`, `"is_later"`
  Future<Either<Failure, TripHistoryResponse>> getTripHistory({
    required int page,
    required String type,
  });

  /// Get trip details by ID
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId);
}
