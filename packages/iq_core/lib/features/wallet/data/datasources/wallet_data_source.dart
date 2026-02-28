import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../models/wallet_model.dart';

/// Contract for wallet API calls.
abstract class WalletDataSource {
  /// Fetch wallet balance + history.
  Future<Either<Failure, WalletHistoryResponse>> getWalletHistory({
    required int page,
  });

  /// Create a QiCard payment and return the payment URL.
  Future<Either<Failure, String>> createWalletPayment({
    required double amount,
  });

  /// Transfer money from wallet to another user.
  Future<Either<Failure, String>> transferMoney({
    required double amount,
    required String mobile,
    required String role,
    required String countryCode,
  });
}
