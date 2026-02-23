import 'package:equatable/equatable.dart';

/// State for the login form UI
class LoginFormState extends Equatable {
  final String phone;
  final String? phoneError;

  /// Flipped to `true` when form validation passes on submit.
  /// The listener uses this to fire [AuthSendOtpEvent].
  final bool validationPassed;

  const LoginFormState({
    this.phone = '',
    this.phoneError,
    this.validationPassed = false,
  });

  LoginFormState copyWith({
    String? phone,
    String? Function()? phoneError,
    bool? validationPassed,
  }) {
    return LoginFormState(
      phone: phone ?? this.phone,
      phoneError: phoneError != null ? phoneError() : this.phoneError,
      validationPassed: validationPassed ?? this.validationPassed,
    );
  }

  @override
  List<Object?> get props => [phone, phoneError, validationPassed];
}
