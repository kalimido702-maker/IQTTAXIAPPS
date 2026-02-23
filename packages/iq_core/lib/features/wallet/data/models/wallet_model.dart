import '../../domain/entities/wallet_entity.dart';

/// Safely parse any value (num, String, null) to double.
double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

/// Safely parse any value (num, String, null) to int.
int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

/// Response model for wallet history API.
class WalletHistoryResponse {
  final double walletBalance;
  final String currencyCode;
  final String currencySymbol;
  final int minimumAmount;
  final List<WalletTransactionEntity> transactions;
  final int currentPage;
  final int lastPage;

  const WalletHistoryResponse({
    required this.walletBalance,
    required this.currencyCode,
    required this.currencySymbol,
    required this.minimumAmount,
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
  });

  factory WalletHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse transactions
    final historyData = data['wallet_history'] as Map<String, dynamic>? ?? {};
    final historyList = historyData['data'] as List<dynamic>? ?? [];
    final meta = historyData['meta'] as Map<String, dynamic>? ?? {};

    final transactions = historyList
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WalletHistoryResponse(
      walletBalance: _toDouble(data['wallet_balance']),
      currencyCode: data['currency_code']?.toString() ?? 'IQD',
      currencySymbol: data['currency_symbol']?.toString() ?? 'IQD',
      minimumAmount: _toInt(data['minimum_amount_added_to_wallet']),
      transactions: transactions,
      currentPage: _toInt(meta['current_page'], 1),
      lastPage: _toInt(meta['last_page'], 1),
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      balance: walletBalance,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      minimumAmount: minimumAmount,
      transactions: transactions,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }
}

/// Model for a single wallet transaction.
class WalletTransactionModel extends WalletTransactionEntity {
  const WalletTransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.remarks,
    required super.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? 'credit',
      amount: _toDouble(json['amount']),
      remarks: json['remarks']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
