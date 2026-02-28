import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/wallet_entity.dart';

/// Contract for wallet operations.
abstract class WalletRepository {
  /// Fetch wallet balance + transaction history.
  ///
  /// Calls `GET api/v1/payment/wallet/history?page={page}`
  Future<Either<Failure, WalletEntity>> getWalletHistory({required int page});

  /// Create a QiCard payment for adding money to wallet.
  ///
  /// Returns the payment URL to open in a WebView.
  /// Calls `POST api/v1/payment/qicard/create-payment`
  Future<Either<Failure, String>> createWalletPayment({
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
