import 'package:equatable/equatable.dart';

import '../../domain/entities/trip_entity.dart';

/// States for [TripHistoryBloc].
abstract class TripHistoryState extends Equatable {
  /// The currently active tab index (0=completed, 1=upcoming, 2=cancelled).
  final int activeTab;

  const TripHistoryState({this.activeTab = 0});

  @override
  List<Object?> get props => [activeTab];
}

/// Initial / idle state — no data loaded yet.
class TripHistoryInitial extends TripHistoryState {
  const TripHistoryInitial({super.activeTab});
}

/// Loading trip data (first page).
class TripHistoryLoading extends TripHistoryState {
  const TripHistoryLoading({super.activeTab});
}

/// Trip data loaded successfully.
class TripHistoryLoaded extends TripHistoryState {
  final List<TripEntity> trips;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const TripHistoryLoaded({
    super.activeTab,
    required this.trips,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  TripHistoryLoaded copyWith({
    int? activeTab,
    List<TripEntity>? trips,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TripHistoryLoaded(
      activeTab: activeTab ?? this.activeTab,
      trips: trips ?? this.trips,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [activeTab, trips, currentPage, hasMore, isLoadingMore];
}

/// Error fetching trips.
class TripHistoryError extends TripHistoryState {
  final String message;

  const TripHistoryError({
    super.activeTab,
    required this.message,
  });

  @override
  List<Object?> get props => [activeTab, message];
}
