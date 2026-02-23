/// Wallet balance + metadata entity.
class WalletEntity {
  final double balance;
  final String currencyCode;
  final String currencySymbol;
  final int minimumAmount;
  final List<WalletTransactionEntity> transactions;
  final int currentPage;
  final int lastPage;

  const WalletEntity({
    required this.balance,
    required this.currencyCode,
    required this.currencySymbol,
    required this.minimumAmount,
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMorePages => currentPage < lastPage;

  String get formattedBalance => '$currencyCode ${balance.toStringAsFixed(0)}';
}

/// A single wallet transaction.
class WalletTransactionEntity {
  final int id;

  /// `"credit"` = money added, `"debit"` = money deducted.
  final String type;
  final double amount;
  final String remarks;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.remarks,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';
}
