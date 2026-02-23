import 'package:equatable/equatable.dart';

import '../../data/models/reports_model.dart';

/// States for [ReportsBloc].
abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

/// Initial / idle state with date range but no data fetched yet.
class ReportsIdle extends ReportsState {
  final DateTime fromDate;
  final DateTime toDate;

  const ReportsIdle({
    required this.fromDate,
    required this.toDate,
  });

  ReportsIdle copyWith({DateTime? fromDate, DateTime? toDate}) {
    return ReportsIdle(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  @override
  List<Object?> get props => [fromDate, toDate];
}

/// Loading report data.
class ReportsLoading extends ReportsState {
  final DateTime fromDate;
  final DateTime toDate;

  const ReportsLoading({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

/// Report data loaded successfully.
class ReportsLoaded extends ReportsState {
  final DateTime fromDate;
  final DateTime toDate;
  final ReportsModel report;

  const ReportsLoaded({
    required this.fromDate,
    required this.toDate,
    required this.report,
  });

  @override
  List<Object?> get props => [fromDate, toDate, report];
}

/// Error fetching report.
class ReportsError extends ReportsState {
  final DateTime fromDate;
  final DateTime toDate;
  final String message;

  const ReportsError({
    required this.fromDate,
    required this.toDate,
    required this.message,
  });

  @override
  List<Object?> get props => [fromDate, toDate, message];
}
