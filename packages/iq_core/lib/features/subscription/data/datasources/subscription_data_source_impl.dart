import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/subscription_models.dart';
import 'subscription_data_source.dart';

class SubscriptionDataSourceImpl implements SubscriptionDataSource {
  final Dio dio;

  SubscriptionDataSourceImpl({required this.dio});

  // ─────────────────────────────────────────────
  //  GET api/v1/driver/list_of_plans
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() async {
    try {
      final response = await dio.get('api/v1/driver/list_of_plans');
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final rawData = body['data'];
        final List<SubscriptionPlan> plans = [];

        if (rawData is List) {
          for (final item in rawData) {
            if (item is Map<String, dynamic>) {
              plans.add(SubscriptionPlan.fromJson(item));
            }
          }
        } else if (rawData is Map<String, dynamic>) {
          // API returns a single object — wrap in list (old backend behavior).
          plans.add(SubscriptionPlan.fromJson(rawData));
        }

        return Right(plans);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToLoadSubscriptionPlans,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      debugPrint('❌ SubscriptionDataSource.getPlans error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────────────────────
  //  POST api/v1/driver/subscribe
  // ─────────────────────────────────────────────

  @override
  Future<Either<Failure, SubscribeResult>> subscribe({
    required int paymentOpt,
    required int day,
    required List<int> planIds,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/driver/subscribe',
        data: {
          'payment_opt': paymentOpt,
          'day': day.toString(),
          'plan_id': planIds,
          'callback_url': 'https://iqttaxi.com/payment/callback',
        },
      );
      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final message = body['message']?.toString();

        // Card payment → returns payment_url for WebView
        final paymentUrl = data['payment_url']?.toString();
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          return Right(SubscribeResult(
            paymentUrl: paymentUrl,
            message: message,
          ));
        }

        // Free subscription → returns expiry info
        if (data.containsKey('expired_at')) {
          return Right(SubscribeResult(
            isSubscribed: true,
            freeDays: (data['free_days'] as num?)?.toInt(),
            remainingFreeDays: (data['remaining_free_days'] as num?)?.toInt(),
            expiredAt: data['expired_at']?.toString(),
            message: message,
          ));
        }

        // Wallet payment → returns is_subscribed
        final isSubscribed = data['is_subscribed']?.toString() == '1';
        return Right(SubscribeResult(
          isSubscribed: isSubscribed,
          message: message,
        ));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToSubscribe,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      debugPrint('❌ SubscriptionDataSource.subscribe error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ─────────────────────────────────────────────

  ServerFailure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ServerFailure(message: AppStrings.connectionTimeout);
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return ServerFailure(
          message: data['message']?.toString() ?? AppStrings.serverError,
          statusCode: e.response!.statusCode,
        );
      }
    }
    return ServerFailure(message: e.message ?? AppStrings.unexpectedError);
  }
}
