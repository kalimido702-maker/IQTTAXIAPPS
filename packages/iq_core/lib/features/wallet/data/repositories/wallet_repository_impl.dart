import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_data_source.dart';

/// Production implementation of [WalletRepository].
class WalletRepositoryImpl implements WalletRepository {
  final WalletDataSource dataSource;

  WalletRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, WalletEntity>> getWalletHistory({
    required int page,
  }) async {
    final result = await dataSource.getWalletHistory(page: page);
    return result.map((response) => response.toEntity());
  }

  @override
  Future<Either<Failure, String>> addMoneyToWallet({
    required double amount,
  }) {
    return dataSource.addMoneyToWallet(amount: amount);
  }

  @override
  Future<Either<Failure, String>> transferMoney({
    required double amount,
    required String mobile,
    required String role,
    required String countryCode,
  }) {
    return dataSource.transferMoney(
      amount: amount,
      mobile: mobile,
      role: role,
      countryCode: countryCode,
    );
  }
}
