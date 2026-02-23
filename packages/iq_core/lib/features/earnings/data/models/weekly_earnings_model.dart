import 'package:equatable/equatable.dart';

/// Weekly earnings data from the `GET api/v1/driver/weekly-earnings` API.
class WeeklyEarningsModel extends Equatable {
  /// Per-day earnings (keys: mon, tues, wed, thurs, fri, sat, sun).
  final Map<String, double> weekDays;

  final String currentDate;
  final int currentWeekNumber;
  final String startOfWeek;
  final String endOfWeek;
  final bool disableNextWeek;
  final bool disablePreviousWeek;

  final int totalTripsCount;
  final double totalTripKms;
  final double totalEarnings;
  final double totalCashTripAmount;
  final double totalWalletTripAmount;
  final int totalCashTripCount;
  final int totalWalletTripCount;
  final String currencySymbol;
  final String totalHoursWorked;

  const WeeklyEarningsModel({
    this.weekDays = const {},
    this.currentDate = '',
    this.currentWeekNumber = 0,
    this.startOfWeek = '',
    this.endOfWeek = '',
    this.disableNextWeek = true,
    this.disablePreviousWeek = false,
    this.totalTripsCount = 0,
    this.totalTripKms = 0,
    this.totalEarnings = 0,
    this.totalCashTripAmount = 0,
    this.totalWalletTripAmount = 0,
    this.totalCashTripCount = 0,
    this.totalWalletTripCount = 0,
    this.currencySymbol = 'IQD',
    this.totalHoursWorked = '',
  });

  factory WeeklyEarningsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse week_days map
    final raw = data['week_days'];
    final weekDays = <String, double>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        weekDays[entry.key.toString()] =
            (entry.value as num?)?.toDouble() ?? 0.0;
      }
    }

    return WeeklyEarningsModel(
      weekDays: weekDays,
      currentDate: (data['current_date'] ?? '').toString(),
      currentWeekNumber: (data['current_week_number'] as num?)?.toInt() ?? 0,
      startOfWeek: (data['start_of_week'] ?? '').toString(),
      endOfWeek: (data['end_of_week'] ?? '').toString(),
      disableNextWeek: data['disable_next_week'] == true,
      disablePreviousWeek: data['disable_previous_week'] == true,
      totalTripsCount: (data['total_trips_count'] as num?)?.toInt() ?? 0,
      totalTripKms: (data['total_trip_kms'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (data['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalCashTripAmount:
          (data['total_cash_trip_amount'] as num?)?.toDouble() ?? 0.0,
      totalWalletTripAmount:
          (data['total_wallet_trip_amount'] as num?)?.toDouble() ?? 0.0,
      totalCashTripCount: (data['total_cash_trip_count'] as num?)?.toInt() ?? 0,
      totalWalletTripCount:
          (data['total_wallet_trip_count'] as num?)?.toInt() ?? 0,
      currencySymbol: (data['currency_symbol'] ?? 'IQD').toString(),
      totalHoursWorked: (data['total_hours_worked'] ?? '').toString(),
    );
  }

  /// Ordered day keys matching Mon → Sun.
  static const dayKeys = ['mon', 'tues', 'wed', 'thurs', 'fri', 'sat', 'sun'];

  /// Short display labels for each day.
  static const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Get earnings for a specific day index (0 = Mon, 6 = Sun).
  double earningsForDay(int index) {
    if (index < 0 || index >= dayKeys.length) return 0;
    return weekDays[dayKeys[index]] ?? 0;
  }

  /// Maximum daily earning (for bar chart scaling).
  double get maxDailyEarning {
    if (weekDays.isEmpty) return 0;
    double max = 0;
    for (final key in dayKeys) {
      final val = weekDays[key] ?? 0;
      if (val > max) max = val;
    }
    return max;
  }

  @override
  List<Object?> get props => [
    weekDays,
    currentWeekNumber,
    totalTripsCount,
    totalEarnings,
    totalCashTripAmount,
    totalWalletTripAmount,
    totalTripKms,
    totalHoursWorked,
  ];
}
