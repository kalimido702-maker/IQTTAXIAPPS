import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// BLoC that manages onboarding page index + completion.
///
/// Keeps [OnboardingPage] as a pure [StatelessWidget].
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({int totalPages = 3})
      : super(OnboardingState(totalPages: totalPages)) {
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingNextPressed>(_onNext);
    on<OnboardingBackPressed>(_onBack);
    on<OnboardingSkipped>(_onSkipped);
  }

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(currentPage: event.page));
  }

  void _onNext(
    OnboardingNextPressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isLastPage) {
      emit(state.copyWith(completed: true));
    } else {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  void _onBack(
    OnboardingBackPressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentPage > 0) {
      emit(state.copyWith(currentPage: state.currentPage - 1));
    }
  }

  void _onSkipped(
    OnboardingSkipped event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(completed: true));
  }
}
