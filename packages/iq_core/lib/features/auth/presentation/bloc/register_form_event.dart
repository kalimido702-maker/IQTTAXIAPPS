import 'package:equatable/equatable.dart';

/// Events for the register form UI state
abstract class RegisterFormEvent extends Equatable {
  const RegisterFormEvent();

  @override
  List<Object?> get props => [];
}

/// Name changed
class RegisterFormNameChanged extends RegisterFormEvent {
  final String name;
  const RegisterFormNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

/// Phone changed
class RegisterFormPhoneChanged extends RegisterFormEvent {
  final String phone;
  const RegisterFormPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

/// Gender selected
class RegisterFormGenderSelected extends RegisterFormEvent {
  final String gender;
  const RegisterFormGenderSelected(this.gender);

  @override
  List<Object?> get props => [gender];
}

/// Terms checkbox toggled
class RegisterFormTermsToggled extends RegisterFormEvent {
  const RegisterFormTermsToggled();
}

/// Submit pressed
class RegisterFormSubmitted extends RegisterFormEvent {
  const RegisterFormSubmitted();
}
