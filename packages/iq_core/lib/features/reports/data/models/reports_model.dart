import 'package:equatable/equatable.dart';

/// Report data model from the earnings-report API.
class ReportsModel extends Equatable {
  final int totalTrips;
  final double totalWalletAmount;
  final double totalCashAmount;
  final double totalTripKms;
  final double walletInstallment;
  final double cashInstallment;
  final double netEarnings;
  final String currencySymbol;

  const ReportsModel({
    this.totalTrips = 0,
    this.totalWalletAmount = 0,
    this.totalCashAmount = 0,
    this.totalTripKms = 0,
    this.walletInstallment = 0,
    this.cashInstallment = 0,
    this.netEarnings = 0,
    this.currencySymbol = 'IQD',
  });

  factory ReportsModel.fromJson(Map<String, dynamic> json) {
    // The API returns { success, message, data: { ... } }.
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final currency =
        (data['currency_symbol'] ?? json['currency_symbol'] ?? 'IQD')
            .toString();

    final totalEarnings = (data['total_earnings'] as num?)?.toDouble() ?? 0;
    final walletAmount =
        (data['total_wallet_trip_amount'] as num?)?.toDouble() ?? 0;
    final cashAmount =
        (data['total_cash_trip_amount'] as num?)?.toDouble() ?? 0;

    return ReportsModel(
      totalTrips: (data['total_trips_count'] as num?)?.toInt() ?? 0,
      totalWalletAmount: walletAmount,
      totalCashAmount: cashAmount,
      totalTripKms: (data['total_trip_kms'] as num?)?.toDouble() ?? 0,
      walletInstallment: walletAmount,
      cashInstallment: cashAmount,
      netEarnings: totalEarnings,
      currencySymbol: currency,
    );
  }

  @override
  List<Object?> get props => [
    totalTrips,
    totalWalletAmount,
    totalCashAmount,
    totalTripKms,
    walletInstallment,
    cashInstallment,
    netEarnings,
    currencySymbol,
  ];
}
