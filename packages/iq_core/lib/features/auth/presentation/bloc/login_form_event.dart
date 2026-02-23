import 'package:equatable/equatable.dart';

/// Events for the login form UI state
abstract class LoginFormEvent extends Equatable {
  const LoginFormEvent();

  @override
  List<Object?> get props => [];
}

/// Phone text changed
class LoginFormPhoneChanged extends LoginFormEvent {
  final String phone;
  const LoginFormPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

/// User tapped "Continue"
class LoginFormSubmitted extends LoginFormEvent {
  const LoginFormSubmitted();
}

/// Clear validation error
class LoginFormErrorCleared extends LoginFormEvent {
  const LoginFormErrorCleared();
}
