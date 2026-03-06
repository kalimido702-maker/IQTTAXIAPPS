import 'package:equatable/equatable.dart';

import '../../data/models/incentive_model.dart';

/// States for [IncentiveBloc].
abstract class IncentiveState extends Equatable {
  const IncentiveState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class IncentiveInitial extends IncentiveState {
  const IncentiveInitial();
}

/// Loading state.
class IncentiveLoading extends IncentiveState {
  const IncentiveLoading();
}

/// Incentive data loaded successfully.
class IncentiveLoaded extends IncentiveState {
  /// Currently active tab: 0 = daily, 1 = weekly.
  final int activeTab;

  /// All history entries returned by the API.
  final List<IncentiveHistory> history;

  /// Flat list of all dates across histories.
  final List<IncentiveDate> dates;

  /// Index of the currently selected date in [dates].
  final int selectedDateIndex;

  const IncentiveLoaded({
    required this.activeTab,
    required this.history,
    required this.dates,
    required this.selectedDateIndex,
  });

  /// The currently selected date's data, or null if no selection.
  IncentiveDate? get selectedDate =>
      (selectedDateIndex >= 0 && selectedDateIndex < dates.length)
          ? dates[selectedDateIndex]
          : null;

  IncentiveLoaded copyWith({
    int? activeTab,
    List<IncentiveHistory>? history,
    List<IncentiveDate>? dates,
    int? selectedDateIndex,
  }) {
    return IncentiveLoaded(
      activeTab: activeTab ?? this.activeTab,
      history: history ?? this.history,
      dates: dates ?? this.dates,
      selectedDateIndex: selectedDateIndex ?? this.selectedDateIndex,
    );
  }

  @override
  List<Object?> get props => [activeTab, history, dates, selectedDateIndex];
}

/// Error state.
class IncentiveError extends IncentiveState {
  final String message;

  const IncentiveError(this.message);

  @override
  List<Object?> get props => [message];
}
