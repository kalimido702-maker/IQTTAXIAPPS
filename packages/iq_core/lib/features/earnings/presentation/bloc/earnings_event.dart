import 'package:equatable/equatable.dart';

/// Events for [EarningsBloc].
abstract class EarningsEvent extends Equatable {
  const EarningsEvent();

  @override
  List<Object?> get props => [];
}

/// Load earnings for the current week (or refresh).
class EarningsLoadRequested extends EarningsEvent {
  const EarningsLoadRequested();
}

/// Navigate to a different week.
class EarningsWeekChanged extends EarningsEvent {
  final int weekNumber;

  const EarningsWeekChanged(this.weekNumber);

  @override
  List<Object?> get props => [weekNumber];
}

/// Select a specific day within the current week (0 = Mon, 6 = Sun).
class EarningsDaySelected extends EarningsEvent {
  final int dayIndex;

  const EarningsDaySelected(this.dayIndex);

  @override
  List<Object?> get props => [dayIndex];
}
