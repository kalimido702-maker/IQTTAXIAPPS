import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/incentive_model.dart';
import '../../domain/repositories/incentive_repository.dart';
import 'incentive_event.dart';
import 'incentive_state.dart';

/// BLoC for the Incentives feature (driver only).
class IncentiveBloc extends Bloc<IncentiveEvent, IncentiveState> {
  final IncentiveRepository _repository;

  IncentiveBloc({required IncentiveRepository repository})
      : _repository = repository,
        super(const IncentiveInitial()) {
    on<IncentiveLoadRequested>(_onLoad);
    on<IncentiveDateSelected>(_onDateSelected);
  }

  Future<void> _onLoad(
    IncentiveLoadRequested event,
    Emitter<IncentiveState> emit,
  ) async {
    emit(const IncentiveLoading());

    final result = await _repository.getIncentives(type: event.type);

    result.fold(
      (failure) => emit(IncentiveError(failure.message)),
      (response) {
        // Flatten all dates from all history entries.
        final allDates = <IncentiveDate>[];
        for (final h in response.history) {
          allDates.addAll(h.dates);
        }

        // Auto-select the current date/week.
        int selectedIndex = -1;
        if (event.type == 0) {
          // Daily: find the date marked as today.
          selectedIndex =
              allDates.indexWhere((d) => d.isCurrentDate);
          if (selectedIndex < 0) {
            // Fallback: try matching today's date by parsing.
            final todayStr = DateFormat('dd-MMM-yy').format(DateTime.now());
            selectedIndex =
                allDates.indexWhere((d) => d.date == todayStr);
          }
        } else {
          // Weekly: find the entry marked as current week.
          selectedIndex =
              allDates.indexWhere((d) => d.isCurrentWeek);
        }

        // If still nothing, select the last item.
        if (selectedIndex < 0 && allDates.isNotEmpty) {
          selectedIndex = allDates.length - 1;
        }

        emit(IncentiveLoaded(
          activeTab: event.type,
          history: response.history,
          dates: allDates,
          selectedDateIndex: selectedIndex,
        ));
      },
    );
  }

  void _onDateSelected(
    IncentiveDateSelected event,
    Emitter<IncentiveState> emit,
  ) {
    final s = state;
    if (s is IncentiveLoaded) {
      emit(s.copyWith(selectedDateIndex: event.dateIndex));
    }
  }

  /// Format a date string for display in the date strip.
  ///
  /// [dateStr] — raw date string from API (e.g. "01-Jan-25").
  /// [type] — 0 = daily (show day number), 1 = weekly (show range "01-07").
  String formatDateLabel(String dateStr, int type) {
    if (type == 0) {
      // Daily: extract the day number.
      try {
        final dt = DateFormat('dd-MMM-yy').parse(dateStr);
        return dt.day.toString();
      } catch (_) {
        final parts = dateStr.split('-');
        return parts.isNotEmpty ? parts[0] : dateStr;
      }
    } else {
      // Weekly: show date range from the from/to fields.
      // The date string itself is the "from" date for that week entry.
      try {
        final dt = DateFormat('dd-MMM-yy').parse(dateStr);
        return '${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        final parts = dateStr.split('-');
        return parts.isNotEmpty ? parts[0] : dateStr;
      }
    }
  }
}
