import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'otp_form_event.dart';
import 'otp_form_state.dart';

/// BLoC that manages OTP page UI state: timer countdown + OTP text.
///
/// Keeps the page as a pure [StatelessWidget].
class OtpFormBloc extends Bloc<OtpFormEvent, OtpFormState> {
  Timer? _timer;

  OtpFormBloc() : super(const OtpFormState()) {
    on<OtpFormChanged>(_onChanged);
    on<OtpFormTimerTick>(_onTick);
    on<OtpFormTimerStarted>(_onTimerStarted);
    on<OtpFormSubmitted>(_onSubmitted);

    // Auto-start timer on creation
    add(const OtpFormTimerStarted());
  }

  void _onChanged(OtpFormChanged event, Emitter<OtpFormState> emit) {
    emit(state.copyWith(otp: event.otp));
  }

  void _onTimerStarted(OtpFormTimerStarted event, Emitter<OtpFormState> emit) {
    _timer?.cancel();
    emit(state.copyWith(secondsRemaining: 60, canResend: false));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const OtpFormTimerTick());
    });
  }

  void _onTick(OtpFormTimerTick event, Emitter<OtpFormState> emit) {
    final next = state.secondsRemaining - 1;
    if (next <= 0) {
      _timer?.cancel();
      emit(state.copyWith(secondsRemaining: 0, canResend: true));
    } else {
      emit(state.copyWith(secondsRemaining: next));
    }
  }

  void _onSubmitted(OtpFormSubmitted event, Emitter<OtpFormState> emit) {
    // Nothing extra needed — the page handles dispatching AuthVerifyOtpEvent
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
