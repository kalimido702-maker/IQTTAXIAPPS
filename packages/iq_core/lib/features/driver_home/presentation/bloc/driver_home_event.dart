import 'package:equatable/equatable.dart';

/// Events for DriverHomePage
abstract class DriverHomeEvent extends Equatable {
  const DriverHomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load driver home data from API
class DriverHomeLoadRequested extends DriverHomeEvent {
  const DriverHomeLoadRequested();
}

/// Driver toggled online/offline status
class DriverHomeStatusToggled extends DriverHomeEvent {
  const DriverHomeStatusToggled();
}

/// App resumed from background — re-establish Firebase presence
class DriverHomeResumed extends DriverHomeEvent {
  const DriverHomeResumed();
}
