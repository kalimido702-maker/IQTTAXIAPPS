import 'package:equatable/equatable.dart';

/// State for onboarding page UI
class OnboardingState extends Equatable {
  final int currentPage;
  final int totalPages;

  /// When true the page should call `onComplete`.
  final bool completed;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 3,
    this.completed = false,
  });

  bool get isLastPage => currentPage >= totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    bool? completed,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [currentPage, totalPages, completed];
}
