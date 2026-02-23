import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_form_event.dart';
import 'register_form_state.dart';

/// BLoC that manages register form validation + UI state.
///
/// Keeps RegisterPage as a pure [StatelessWidget].
class RegisterFormBloc extends Bloc<RegisterFormEvent, RegisterFormState> {
  RegisterFormBloc({String? initialPhone})
      : super(RegisterFormState(phone: initialPhone ?? '')) {
    on<RegisterFormNameChanged>(_onNameChanged);
    on<RegisterFormPhoneChanged>(_onPhoneChanged);
    on<RegisterFormGenderSelected>(_onGenderSelected);
    on<RegisterFormTermsToggled>(_onTermsToggled);
    on<RegisterFormSubmitted>(_onSubmitted);
  }

  void _onNameChanged(
    RegisterFormNameChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(
      name: event.name,
      nameError: () => null,
    ));
  }

  void _onPhoneChanged(
    RegisterFormPhoneChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(
      phone: event.phone,
      phoneError: () => null,
    ));
  }

  void _onGenderSelected(
    RegisterFormGenderSelected event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(
      selectedGender: () => event.gender,
      genderError: () => null,
    ));
  }

  void _onTermsToggled(
    RegisterFormTermsToggled event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(agreedToTerms: !state.agreedToTerms));
  }

  void _onSubmitted(
    RegisterFormSubmitted event,
    Emitter<RegisterFormState> emit,
  ) {
    String? nameErr;
    String? phoneErr;
    String? genderErr;

    if (state.name.trim().isEmpty) {
      nameErr = 'يرجى إدخال الإسم';
    }

    if (state.phone.trim().isEmpty) {
      phoneErr = 'يرجى إدخال رقم الجوال';
    } else if (state.phone.trim().length < 10) {
      phoneErr = 'رقم الجوال غير صحيح';
    }

    if (state.selectedGender == null) {
      genderErr = 'يرجى تحديد النوع';
    }

    final hasErrors = nameErr != null || phoneErr != null || genderErr != null;

    emit(state.copyWith(
      nameError: () => nameErr,
      phoneError: () => phoneErr,
      genderError: () => genderErr,
      isValid: !hasErrors && state.agreedToTerms,
    ));
  }
}
