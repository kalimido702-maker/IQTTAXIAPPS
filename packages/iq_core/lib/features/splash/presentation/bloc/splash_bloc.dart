import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC that manages splash screen state:
/// - Fade-in logo immediately
/// - Complete after [splashDuration]
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final Duration splashDuration;
  Timer? _timer;

  SplashBloc({
    this.splashDuration = const Duration(seconds: 3),
  }) : super(const SplashState()) {
    on<SplashStarted>(_onStarted);
  }

  void _onStarted(SplashStarted event, Emitter<SplashState> emit) async {
    // Immediately show the logo (triggers fade-in)
    emit(state.copyWith(logoVisible: true));

    // Wait for the splash duration then complete
    final completer = Completer<void>();
    _timer = Timer(splashDuration, () => completer.complete());
    await completer.future;

    emit(state.copyWith(completed: true));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
