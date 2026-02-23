import 'package:equatable/equatable.dart';

/// Events for [TripHistoryBloc].
abstract class TripHistoryEvent extends Equatable {
  const TripHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load trip history for the given tab.
class TripHistoryLoadRequested extends TripHistoryEvent {
  const TripHistoryLoadRequested();
}

/// Change the active tab (completed / upcoming / cancelled).
class TripHistoryTabChanged extends TripHistoryEvent {
  /// Index 0 = completed, 1 = upcoming, 2 = cancelled
  final int tabIndex;

  const TripHistoryTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

/// Load more trips (pagination).
class TripHistoryLoadMoreRequested extends TripHistoryEvent {
  const TripHistoryLoadMoreRequested();
}

/// Refresh the current tab.
class TripHistoryRefreshRequested extends TripHistoryEvent {
  const TripHistoryRefreshRequested();
}
