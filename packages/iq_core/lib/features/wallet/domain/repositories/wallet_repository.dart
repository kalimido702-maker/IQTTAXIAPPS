import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet_entity.dart';

/// Contract for wallet operations.
abstract class WalletRepository {
  /// Fetch wallet balance + transaction history.
  ///
  /// Calls `GET api/v1/payment/wallet/history?page={page}`
  Future<Either<Failure, WalletEntity>> getWalletHistory({required int page});

  /// Add money to wallet.
  ///
  /// Calls `POST api/v1/payment/stripe/add-money-to-wallet`
  Future<Either<Failure, String>> addMoneyToWallet({
    required double amount,
  });

  /// Transfer money from wallet to another user.
  ///
  /// Calls `POST api/v1/payment/wallet/transfer-money-from-wallet`
  Future<Either<Failure, String>> transferMoney({
    required double amount,
    required String mobile,
    required String role,
    required String countryCode,
  });
}
