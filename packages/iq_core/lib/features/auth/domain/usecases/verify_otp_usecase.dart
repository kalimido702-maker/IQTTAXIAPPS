import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case to verify OTP code
class VerifyOtpUseCase extends UseCase<UserEntity, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyOtpParams params) {
    return repository.verifyOtp(
      phone: params.phone,
      otp: params.otp,
      role: params.role,
    );
  }
}

class VerifyOtpParams extends Equatable {
  final String phone;
  final String otp;
  final String role;

  const VerifyOtpParams({
    required this.phone,
    required this.otp,
    this.role = 'passenger',
  });

  @override
  List<Object?> get props => [phone, otp, role];
}
