// Splash feature barrel export
// Splash screen is shared between both Passenger & Driver apps
// with the same design (Figma node 1:12005).
export 'presentation/splash_page.dart';
export 'presentation/bloc/splash_bloc.dart';
export 'presentation/bloc/splash_event.dart';
export 'presentation/bloc/splash_state.dart';

/// Configuration for the splash screen behaviour.
class SplashConfig {
  final Duration duration;
  final String nextRoute;

  const SplashConfig({
    this.duration = const Duration(seconds: 3),
    required this.nextRoute,
  });
}
