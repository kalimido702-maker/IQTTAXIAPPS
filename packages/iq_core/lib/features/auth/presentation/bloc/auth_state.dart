import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Auth BLoC States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP sent successfully
class AuthOtpSent extends AuthState {
  final String phone;

  const AuthOtpSent({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// OTP verified & user authenticated
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User needs to register (new user)
class AuthNeedsRegistration extends AuthState {
  final String phone;

  const AuthNeedsRegistration({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// User logged out
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Auth error
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// OTP resent
class AuthOtpResent extends AuthState {
  final String phone;

  const AuthOtpResent({required this.phone});

  @override
  List<Object?> get props => [phone];
}
