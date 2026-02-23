import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/trip_entity.dart';
import '../models/trip_history_model.dart';

/// Contract for trip-related API calls.
abstract class TripDataSource {
  /// Fetch trip history with pagination and filter.
  ///
  /// [type] must be one of: `"is_completed"`, `"is_cancelled"`, `"is_later"`
  /// Calls `GET api/v1/request/history?page={page}&type={type}`
  Future<Either<Failure, TripHistoryResponse>> getTripHistory({
    required int page,
    required String type,
  });

  /// Fetch a single trip's details by ID.
  ///
  /// Uses the same history endpoint but filters locally,
  /// or can be extended to a dedicated endpoint if available.
  Future<Either<Failure, TripEntity>> getTripDetails(String tripId);
}
