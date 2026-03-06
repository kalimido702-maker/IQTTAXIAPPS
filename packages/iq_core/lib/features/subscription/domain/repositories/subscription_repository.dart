import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/subscription_models.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();
  Future<Either<Failure, SubscribeResult>> subscribe({
    required int paymentOpt,
    required int day,
    required List<int> planIds,
  });
}
