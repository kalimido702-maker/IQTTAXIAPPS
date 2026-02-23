import 'package:equatable/equatable.dart';

import '../../data/models/weekly_earnings_model.dart';

/// States for [EarningsBloc].
abstract class EarningsState extends Equatable {
  const EarningsState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

/// Loading state.
class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

/// Earnings data loaded successfully.
class EarningsLoaded extends EarningsState {
  final WeeklyEarningsModel earnings;

  /// Currently selected day index (0 = Mon, 6 = Sun).
  final int selectedDayIndex;

  const EarningsLoaded({
    required this.earnings,
    this.selectedDayIndex = -1,
  });

  EarningsLoaded copyWith({
    WeeklyEarningsModel? earnings,
    int? selectedDayIndex,
  }) {
    return EarningsLoaded(
      earnings: earnings ?? this.earnings,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }

  @override
  List<Object?> get props => [earnings, selectedDayIndex];
}

/// Error state.
class EarningsError extends EarningsState {
  final String message;

  const EarningsError(this.message);

  @override
  List<Object?> get props => [message];
}
