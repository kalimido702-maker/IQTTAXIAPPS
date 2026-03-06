import 'package:equatable/equatable.dart';

/// Events for [IncentiveBloc].
abstract class IncentiveEvent extends Equatable {
  const IncentiveEvent();

  @override
  List<Object?> get props => [];
}

/// Load incentives from the API.
///
/// [type] — 0 = daily, 1 = weekly.
class IncentiveLoadRequested extends IncentiveEvent {
  final int type;

  const IncentiveLoadRequested({required this.type});

  @override
  List<Object?> get props => [type];
}

/// User selected a date in the date strip.
class IncentiveDateSelected extends IncentiveEvent {
  final int dateIndex;

  const IncentiveDateSelected({required this.dateIndex});

  @override
  List<Object?> get props => [dateIndex];
}
