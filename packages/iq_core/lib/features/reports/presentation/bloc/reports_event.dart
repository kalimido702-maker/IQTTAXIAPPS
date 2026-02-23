import 'package:equatable/equatable.dart';

/// Events for [ReportsBloc].
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the reports page with default dates.
class ReportsInitialized extends ReportsEvent {
  const ReportsInitialized();
}

/// Update the "from" date.
class ReportsFromDateChanged extends ReportsEvent {
  final DateTime date;

  const ReportsFromDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

/// Update the "to" date.
class ReportsToDateChanged extends ReportsEvent {
  final DateTime date;

  const ReportsToDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

/// Request to filter / fetch report with current date range.
class ReportsFilterRequested extends ReportsEvent {
  const ReportsFilterRequested();
}
