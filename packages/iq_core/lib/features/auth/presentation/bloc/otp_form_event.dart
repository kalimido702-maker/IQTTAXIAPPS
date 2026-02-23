import 'package:equatable/equatable.dart';

/// Events for OTP page UI state
abstract class OtpFormEvent extends Equatable {
  const OtpFormEvent();

  @override
  List<Object?> get props => [];
}

/// OTP text changed
class OtpFormChanged extends OtpFormEvent {
  final String otp;
  const OtpFormChanged(this.otp);

  @override
  List<Object?> get props => [otp];
}

/// Timer tick (called every second)
class OtpFormTimerTick extends OtpFormEvent {
  const OtpFormTimerTick();
}

/// Start / restart the countdown timer
class OtpFormTimerStarted extends OtpFormEvent {
  const OtpFormTimerStarted();
}

/// User tapped confirm
class OtpFormSubmitted extends OtpFormEvent {
  const OtpFormSubmitted();
}
