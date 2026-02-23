import 'package:equatable/equatable.dart';

/// Auth BLoC Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Send OTP to phone number
class AuthSendOtpEvent extends AuthEvent {
  final String phone;
  final String role;

  const AuthSendOtpEvent({required this.phone, this.role = 'passenger'});

  @override
  List<Object?> get props => [phone, role];
}

/// Verify OTP code
class AuthVerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  final String role;

  const AuthVerifyOtpEvent({
    required this.phone,
    required this.otp,
    this.role = 'passenger',
  });

  @override
  List<Object?> get props => [phone, otp, role];
}

/// Resend OTP
class AuthResendOtpEvent extends AuthEvent {
  final String phone;
  final String role;

  const AuthResendOtpEvent({required this.phone, this.role = 'passenger'});

  @override
  List<Object?> get props => [phone, role];
}

/// Register new user
class AuthRegisterEvent extends AuthEvent {
  final String name;
  final String phone;
  final String? email;
  final String? gender;
  final String role;

  const AuthRegisterEvent({
    required this.name,
    required this.phone,
    this.email,
    this.gender,
    required this.role,
  });

  @override
  List<Object?> get props => [name, phone, email, gender, role];
}

/// Logout
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

/// Check auth status
class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

/// Force logout due to 401 Unauthorized
class AuthUnauthorizedEvent extends AuthEvent {
  const AuthUnauthorizedEvent();
}
