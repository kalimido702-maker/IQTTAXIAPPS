import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/subscription_data_source.dart';
import '../../data/models/subscription_models.dart';
import 'subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource dataSource;

  SubscriptionRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() {
    return dataSource.getPlans();
  }

  @override
  Future<Either<Failure, SubscribeResult>> subscribe({
    required int paymentOpt,
    required int day,
    required List<int> planIds,
  }) {
    return dataSource.subscribe(
      paymentOpt: paymentOpt,
      day: day,
      planIds: planIds,
    );
  }
}
