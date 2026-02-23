import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

/// BLoC for the Reports feature (driver only).
///
/// Manages date range selection and API calls for earnings reports.
/// Uses 100% event-driven flow — NO StatefulWidget, NO setState.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _repository;

  ReportsBloc({required ReportsRepository repository})
      : _repository = repository,
        super(ReportsIdle(
          fromDate: DateTime.now().subtract(const Duration(days: 30)),
          toDate: DateTime.now(),
        )) {
    on<ReportsInitialized>(_onInitialized);
    on<ReportsFromDateChanged>(_onFromDateChanged);
    on<ReportsToDateChanged>(_onToDateChanged);
    on<ReportsFilterRequested>(_onFilter);
  }

  void _onInitialized(
    ReportsInitialized event,
    Emitter<ReportsState> emit,
  ) {
    emit(ReportsIdle(
      fromDate: DateTime.now().subtract(const Duration(days: 30)),
      toDate: DateTime.now(),
    ));
  }

  void _onFromDateChanged(
    ReportsFromDateChanged event,
    Emitter<ReportsState> emit,
  ) {
    final current = _currentDates;
    emit(ReportsIdle(fromDate: event.date, toDate: current.$2));
  }

  void _onToDateChanged(
    ReportsToDateChanged event,
    Emitter<ReportsState> emit,
  ) {
    final current = _currentDates;
    emit(ReportsIdle(fromDate: current.$1, toDate: event.date));
  }

  Future<void> _onFilter(
    ReportsFilterRequested event,
    Emitter<ReportsState> emit,
  ) async {
    final dates = _currentDates;
    final from = dates.$1;
    final to = dates.$2;

    emit(ReportsLoading(fromDate: from, toDate: to));

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final result = await _repository.getEarningsReport(
      fromDate: fromStr,
      toDate: toStr,
    );

    result.fold(
      (failure) =>
          emit(ReportsError(fromDate: from, toDate: to, message: failure.message)),
      (report) =>
          emit(ReportsLoaded(fromDate: from, toDate: to, report: report)),
    );
  }

  /// Extract current dates from whatever state we're in.
  (DateTime, DateTime) get _currentDates {
    final s = state;
    if (s is ReportsIdle) return (s.fromDate, s.toDate);
    if (s is ReportsLoading) return (s.fromDate, s.toDate);
    if (s is ReportsLoaded) return (s.fromDate, s.toDate);
    if (s is ReportsError) return (s.fromDate, s.toDate);
    return (
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );
  }
}
