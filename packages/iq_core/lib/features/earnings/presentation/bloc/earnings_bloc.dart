import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/weekly_earnings_model.dart';
import '../../domain/repositories/earnings_repository.dart';
import 'earnings_event.dart';
import 'earnings_state.dart';

/// BLoC for the Earnings feature (driver only).
///
/// Fetches weekly earnings data and manages day selection.
class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  final EarningsRepository _repository;

  EarningsBloc({required EarningsRepository repository})
    : _repository = repository,
      super(const EarningsInitial()) {
    on<EarningsLoadRequested>(_onLoad);
    on<EarningsWeekChanged>(_onWeekChanged);
    on<EarningsDaySelected>(_onDaySelected);
  }

  /// Load current week's earnings.
  Future<void> _onLoad(
    EarningsLoadRequested event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const EarningsLoading());

    final result = await _repository.getWeeklyEarnings();

    result.fold((failure) => emit(EarningsError(failure.message)), (
      WeeklyEarningsModel earnings,
    ) {
      // Auto-select today's day index (0 = Mon, 6 = Sun).
      final todayIndex = DateTime.now().weekday - 1; // weekday: 1=Mon → 0
      emit(
        EarningsLoaded(
          earnings: earnings,
          selectedDayIndex: todayIndex.clamp(0, 6),
        ),
      );
    });
  }

  /// Navigate to a different week.
  Future<void> _onWeekChanged(
    EarningsWeekChanged event,
    Emitter<EarningsState> emit,
  ) async {
    emit(const EarningsLoading());

    final result = await _repository.getWeeklyEarnings(
      weekNumber: event.weekNumber,
    );

    result.fold((failure) => emit(EarningsError(failure.message)), (
      WeeklyEarningsModel earnings,
    ) {
      emit(
        EarningsLoaded(
          earnings: earnings,
          selectedDayIndex: -1, // no day selected when navigating weeks
        ),
      );
    });
  }

  /// Select a day within the loaded week.
  void _onDaySelected(EarningsDaySelected event, Emitter<EarningsState> emit) {
    final currentState = state;
    if (currentState is EarningsLoaded) {
      emit(currentState.copyWith(selectedDayIndex: event.dayIndex));
    }
  }
}
