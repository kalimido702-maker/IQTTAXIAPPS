import 'package:equatable/equatable.dart';

/// Top-level incentive response parsed from the API.
class IncentiveResponse extends Equatable {
  final List<IncentiveHistory> history;

  const IncentiveResponse({required this.history});

  factory IncentiveResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final historyList = data['incentive_history'] as List<dynamic>? ?? [];
    return IncentiveResponse(
      history: historyList
          .map((e) =>
              IncentiveHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [history];
}

/// A date-range bucket (e.g. one week).
class IncentiveHistory extends Equatable {
  final String fromDate;
  final String toDate;
  final List<IncentiveDate> dates;

  const IncentiveHistory({
    required this.fromDate,
    required this.toDate,
    required this.dates,
  });

  factory IncentiveHistory.fromJson(Map<String, dynamic> json) {
    final datesList = json['dates'] as List<dynamic>? ?? [];
    return IncentiveHistory(
      fromDate: (json['from_date'] ?? '').toString(),
      toDate: (json['to_date'] ?? '').toString(),
      dates: datesList
          .map((e) => IncentiveDate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [fromDate, toDate, dates];
}

/// A single day/week entry with its incentive milestones.
class IncentiveDate extends Equatable {
  final String day;
  final String date;
  final bool isCurrentWeek;
  final bool isCurrentDate;
  final int totalRides;
  final double totalIncentiveEarned;
  final int earnUpto;
  final List<UpcomingIncentive> upcomingIncentives;

  const IncentiveDate({
    required this.day,
    required this.date,
    required this.isCurrentWeek,
    required this.isCurrentDate,
    required this.totalRides,
    required this.totalIncentiveEarned,
    required this.earnUpto,
    required this.upcomingIncentives,
  });

  factory IncentiveDate.fromJson(Map<String, dynamic> json) {
    final list = json['upcoming_incentives'] as List<dynamic>? ?? [];
    return IncentiveDate(
      day: (json['day'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      isCurrentWeek: json['is_current_week'] == true,
      isCurrentDate: json['is_today'] == true,
      totalRides: _toInt(json['total_rides']),
      totalIncentiveEarned: _toDouble(json['total_incentive_earned']),
      earnUpto: _toInt(json['earn_upto']),
      upcomingIncentives: list
          .map((e) =>
              UpcomingIncentive.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [date, day, totalRides, earnUpto];
}

/// A single incentive milestone (e.g. complete 5 rides → earn 5000).
class UpcomingIncentive extends Equatable {
  final int rideCount;
  final double incentiveAmount;
  final bool isCompleted;

  const UpcomingIncentive({
    required this.rideCount,
    required this.incentiveAmount,
    required this.isCompleted,
  });

  factory UpcomingIncentive.fromJson(Map<String, dynamic> json) {
    return UpcomingIncentive(
      rideCount: _toInt(json['ride_count']),
      incentiveAmount: _toDouble(json['incentive_amount']),
      isCompleted: json['is_completed'] == true,
    );
  }

  @override
  List<Object?> get props => [rideCount, incentiveAmount, isCompleted];
}

// ─── Helpers ───

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
