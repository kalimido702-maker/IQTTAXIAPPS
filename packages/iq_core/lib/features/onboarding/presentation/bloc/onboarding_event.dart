import 'package:equatable/equatable.dart';

/// Events for onboarding page UI state
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Page changed via swipe or button
class OnboardingPageChanged extends OnboardingEvent {
  final int page;
  const OnboardingPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

/// "Next" / "Get Started" button pressed
class OnboardingNextPressed extends OnboardingEvent {
  const OnboardingNextPressed();
}

/// "Back" arrow pressed
class OnboardingBackPressed extends OnboardingEvent {
  const OnboardingBackPressed();
}

/// "Skip" pressed
class OnboardingSkipped extends OnboardingEvent {
  const OnboardingSkipped();
}
