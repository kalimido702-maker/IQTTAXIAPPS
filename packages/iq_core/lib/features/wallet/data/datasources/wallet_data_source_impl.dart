import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../models/wallet_model.dart';
import 'wallet_data_source.dart';

/// Production implementation of [WalletDataSource].
class WalletDataSourceImpl implements WalletDataSource {
  final Dio dio;

  WalletDataSourceImpl({required this.dio});

  @override
  Future<Either<Failure, WalletHistoryResponse>> getWalletHistory({
    required int page,
  }) async {
    try {
      final response = await dio.get(
        'api/v1/payment/wallet/history',
        queryParameters: {'page': page},
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(WalletHistoryResponse.fromJson(body));
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToLoadWallet,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createWalletPayment({
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/payment/qicard/create-payment',
        data: {
          'amount': amount,
          'currency': 'IQD',
          'payment_for': 'wallet',
          'callback_url': 'https://taxi-new.elnoorphp.com/payment/callback',
        },
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final paymentUrl = data['payment_url']?.toString() ?? '';
        if (paymentUrl.isEmpty) {
          return Left(ServerFailure(message: AppStrings.paymentLinkNotReceived));
        }
        return Right(paymentUrl);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToCreatePayment,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> transferMoney({
    required double amount,
    required String mobile,
    required String role,
    required String countryCode,
  }) async {
    try {
      final response = await dio.post(
        'api/v1/payment/wallet/transfer-money-from-wallet',
        data: {
          'amount': amount,
          'mobile': mobile,
          'role': role,
          'country_code': countryCode,
        },
      );

      final body = response.data as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        return Right(body['message']?.toString() ?? AppStrings.transferSuccess);
      }

      return Left(ServerFailure(
        message: body['message']?.toString() ?? AppStrings.failedToTransfer,
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

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
