import 'package:equatable/equatable.dart';

/// State for register form UI
class RegisterFormState extends Equatable {
  final String name;
  final String phone;
  final String? selectedGender;
  final bool agreedToTerms;
  final String? nameError;
  final String? phoneError;
  final String? genderError;

  /// true when all validation passes and terms agreed
  final bool isValid;

  const RegisterFormState({
    this.name = '',
    this.phone = '',
    this.selectedGender,
    this.agreedToTerms = false,
    this.nameError,
    this.phoneError,
    this.genderError,
    this.isValid = false,
  });

  RegisterFormState copyWith({
    String? name,
    String? phone,
    String? Function()? selectedGender,
    bool? agreedToTerms,
    String? Function()? nameError,
    String? Function()? phoneError,
    String? Function()? genderError,
    bool? isValid,
  }) {
    return RegisterFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      selectedGender:
          selectedGender != null ? selectedGender() : this.selectedGender,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      nameError: nameError != null ? nameError() : this.nameError,
      phoneError: phoneError != null ? phoneError() : this.phoneError,
      genderError: genderError != null ? genderError() : this.genderError,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [
        name,
        phone,
        selectedGender,
        agreedToTerms,
        nameError,
        phoneError,
        genderError,
        isValid,
      ];
}
