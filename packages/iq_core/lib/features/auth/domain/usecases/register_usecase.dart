import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case to register a new user
class RegisterUseCase extends UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.register(
      name: params.name,
      phone: params.phone,
      email: params.email,
      gender: params.gender,
      role: params.role,
    );
  }
}

class RegisterParams extends Equatable {
  final String name;
  final String phone;
  final String? email;
  final String? gender;
  final String role;

  const RegisterParams({
    required this.name,
    required this.phone,
    this.email,
    this.gender,
    required this.role,
  });

  @override
  List<Object?> get props => [name, phone, email, gender, role];
}
