import 'package:equatable/equatable.dart';

/// Events for the splash screen
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Splash started — begin the timer + fade-in
class SplashStarted extends SplashEvent {
  const SplashStarted();
}

/// Timer tick (called internally)
class SplashTimerTick extends SplashEvent {
  const SplashTimerTick();
}
