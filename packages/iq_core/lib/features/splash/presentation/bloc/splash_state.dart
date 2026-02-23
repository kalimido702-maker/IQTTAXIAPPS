import 'package:equatable/equatable.dart';

/// State for the splash screen
class SplashState extends Equatable {
  /// Whether the logo should be visible (faded in)
  final bool logoVisible;

  /// When true, the splash duration has elapsed
  final bool completed;

  const SplashState({
    this.logoVisible = false,
    this.completed = false,
  });

  SplashState copyWith({
    bool? logoVisible,
    bool? completed,
  }) {
    return SplashState(
      logoVisible: logoVisible ?? this.logoVisible,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [logoVisible, completed];
}
