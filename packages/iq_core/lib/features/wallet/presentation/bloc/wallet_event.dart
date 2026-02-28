part of 'wallet_bloc.dart';

/// Events for the Wallet BLoC.
sealed class WalletEvent {
  const WalletEvent();
}

/// Load wallet balance + history (page 1).
class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

/// Load more transaction history (next page).
class WalletLoadMoreRequested extends WalletEvent {
  const WalletLoadMoreRequested();
}

/// Refresh wallet (pull-to-refresh).
class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}

/// Deposit money into wallet (creates QiCard payment).
class WalletDepositRequested extends WalletEvent {
  final double amount;
  const WalletDepositRequested({required this.amount});
}

/// Payment WebView completed — refresh wallet.
class WalletPaymentCompleted extends WalletEvent {
  final bool success;
  const WalletPaymentCompleted({required this.success});
}

/// Transfer money from wallet to another user.
class WalletTransferRequested extends WalletEvent {
  final double amount;
  final String mobile;
  final String role;
  final String countryCode;

  const WalletTransferRequested({
    required this.amount,
    required this.mobile,
    required this.role,
    required this.countryCode,
  });
}
