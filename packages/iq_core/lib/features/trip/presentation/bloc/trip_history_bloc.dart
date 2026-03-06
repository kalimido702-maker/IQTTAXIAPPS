import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/trip_repository.dart';
import 'trip_history_event.dart';
import 'trip_history_state.dart';

/// BLoC for the Trip History feature.
///
/// Manages tab switching, pagination, and API calls.
/// 100% event-driven — NO StatefulWidget, NO setState.
class TripHistoryBloc extends Bloc<TripHistoryEvent, TripHistoryState> {
  final TripRepository _repository;

  /// Maps tab index → API filter type.
  static const _tabTypes = [
    'is_completed', // tab 0 — مكتمل
    'is_later', // tab 1 — قادم
    'is_cancelled', // tab 2 — تم الالغاء
  ];

  TripHistoryBloc({required TripRepository repository})
      : _repository = repository,
        super(const TripHistoryInitial()) {
    on<TripHistoryLoadRequested>(_onLoad);
    on<TripHistoryTabChanged>(_onTabChanged);
    on<TripHistoryLoadMoreRequested>(_onLoadMore);
    on<TripHistoryRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
    TripHistoryLoadRequested event,
    Emitter<TripHistoryState> emit,
  ) async {
    emit(TripHistoryLoading(activeTab: state.activeTab));
    await _fetchPage(1, emit);
  }

  Future<void> _onTabChanged(
    TripHistoryTabChanged event,
    Emitter<TripHistoryState> emit,
  ) async {
    if (event.tabIndex == state.activeTab) return;
    emit(TripHistoryLoading(activeTab: event.tabIndex));
    await _fetchPage(1, emit, tabIndex: event.tabIndex);
  }

  Future<void> _onLoadMore(
    TripHistoryLoadMoreRequested event,
    Emitter<TripHistoryState> emit,
  ) async {
    final current = state;
    if (current is! TripHistoryLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final type = _tabTypes[current.activeTab];

    final result = await _repository.getTripHistory(
      page: nextPage,
      type: type,
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (response) {
        final allTrips = [...current.trips, ...response.trips];
        emit(TripHistoryLoaded(
          activeTab: current.activeTab,
          trips: allTrips,
          currentPage: response.currentPage,
          hasMore: response.hasMore,
        ));
      },
    );
  }

  Future<void> _onRefresh(
    TripHistoryRefreshRequested event,
    Emitter<TripHistoryState> emit,
  ) async {
    await _fetchPage(1, emit);
  }

  Future<void> _fetchPage(
    int page,
    Emitter<TripHistoryState> emit, {
    int? tabIndex,
  }) async {
    final activeTab = tabIndex ?? state.activeTab;
    final type = _tabTypes[activeTab];

    final result = await _repository.getTripHistory(
      page: page,
      type: type,
    );

    result.fold(
      (failure) => emit(TripHistoryError(
        activeTab: activeTab,
        message: failure.message,
      )),
      (response) {
        emit(TripHistoryLoaded(
          activeTab: activeTab,
          trips: response.trips,
          currentPage: response.currentPage,
          hasMore: response.hasMore,
        ));
      },
    );
  }
}
