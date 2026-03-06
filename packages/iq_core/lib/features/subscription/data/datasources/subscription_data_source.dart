import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/subscription_models.dart';

/// Contract for subscription-related API calls.
abstract class SubscriptionDataSource {
  /// GET api/v1/driver/list_of_plans
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();

  /// POST api/v1/driver/subscribe
  ///
  /// [paymentOpt]: 0 = card, 2 = wallet
  /// [day]: 0 = free day, 1 = paid
  /// [planIds]: list of plan IDs to subscribe to
  Future<Either<Failure, SubscribeResult>> subscribe({
    required int paymentOpt,
    required int day,
    required List<int> planIds,
  });
}
