import 'package:equatable/equatable.dart';

/// Events for PassengerHomePage
abstract class PassengerHomeEvent extends Equatable {
  const PassengerHomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load home data from API
class PassengerHomeLoadRequested extends PassengerHomeEvent {
  const PassengerHomeLoadRequested();
}

/// User tapped a service category
class PassengerHomeCategoryChanged extends PassengerHomeEvent {
  final int index;
  const PassengerHomeCategoryChanged(this.index);

  @override
  List<Object?> get props => [index];
}
