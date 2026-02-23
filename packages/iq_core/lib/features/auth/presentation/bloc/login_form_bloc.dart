import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_form_event.dart';
import 'login_form_state.dart';

/// BLoC that manages login form validation state.
///
/// Keeps the phone text + validation error in BLoC state so the page
/// can be a pure [StatelessWidget].
class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  LoginFormBloc() : super(const LoginFormState()) {
    on<LoginFormPhoneChanged>(_onPhoneChanged);
    on<LoginFormSubmitted>(_onSubmitted);
    on<LoginFormErrorCleared>(_onErrorCleared);
  }

  void _onPhoneChanged(
    LoginFormPhoneChanged event,
    Emitter<LoginFormState> emit,
  ) {
    emit(state.copyWith(
      phone: event.phone,
      phoneError: () => null,
      validationPassed: false,
    ));
  }

  void _onSubmitted(
    LoginFormSubmitted event,
    Emitter<LoginFormState> emit,
  ) {
    final phone = state.phone.trim();

    if (phone.isEmpty) {
      emit(state.copyWith(
        phoneError: () => '\u064A\u0631\u062C\u0649 \u0625\u062F\u062E\u0627\u0644 \u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644',
        validationPassed: false,
      ));
      return;
    }
    if (phone.length < 10) {
      emit(state.copyWith(
        phoneError: () => '\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D',
        validationPassed: false,
      ));
      return;
    }

    // Validation passed — signal the listener to dispatch AuthSendOtpEvent.
    emit(state.copyWith(
      phoneError: () => null,
      validationPassed: true,
    ));
  }

  void _onErrorCleared(
    LoginFormErrorCleared event,
    Emitter<LoginFormState> emit,
  ) {
    emit(state.copyWith(phoneError: () => null));
  }
}
