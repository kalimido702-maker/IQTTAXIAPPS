import 'package:equatable/equatable.dart';

/// State for OTP page UI
class OtpFormState extends Equatable {
  final String otp;
  final int secondsRemaining;
  final bool canResend;

  const OtpFormState({
    this.otp = '',
    this.secondsRemaining = 60,
    this.canResend = false,
  });

  String get formattedTime {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  OtpFormState copyWith({
    String? otp,
    int? secondsRemaining,
    bool? canResend,
  }) {
    return OtpFormState(
      otp: otp ?? this.otp,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      canResend: canResend ?? this.canResend,
    );
  }

  @override
  List<Object?> get props => [otp, secondsRemaining, canResend];
}
