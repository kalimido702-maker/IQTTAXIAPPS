import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case to send OTP to a phone number
class SendOtpUseCase extends UseCase<bool, SendOtpParams> {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendOtpParams params) {
    return repository.sendOtp(phone: params.phone, role: params.role);
  }
}

class SendOtpParams extends Equatable {
  final String phone;
  final String role;

  const SendOtpParams({required this.phone, this.role = 'passenger'});

  @override
  List<Object?> get props => [phone, role];
}
