part of 'wallet_bloc.dart';

enum WalletStatus { initial, loading, loaded, loadingMore, error }

enum WalletActionStatus { idle, processing, success, failed, paymentUrlReady }

class WalletState {
  final WalletStatus status;
  final double balance;
  final String currencyCode;
  final List<WalletTransactionEntity> transactions;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final String? errorMessage;
  final WalletActionStatus actionStatus;
  final String? actionMessage;
  final String? paymentUrl;

  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0.0,
    this.currencyCode = 'IQD',
    this.transactions = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasMore = false,
    this.errorMessage,
    this.actionStatus = WalletActionStatus.idle,
    this.actionMessage,
    this.paymentUrl,
  });

  String get formattedBalance =>
      '$currencyCode ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    String? currencyCode,
    List<WalletTransactionEntity>? transactions,
    int? currentPage,
    int? lastPage,
    bool? hasMore,
    String? errorMessage,
    WalletActionStatus? actionStatus,
    String? actionMessage,
    String? paymentUrl,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
      paymentUrl: paymentUrl ?? this.paymentUrl,
    );
  }
}
