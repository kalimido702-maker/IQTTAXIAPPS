import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';

/// Concrete implementation of [AuthRepository].
///
/// Delegates all work to [AuthDataSource] which can be
/// swapped between local-mock and real-API implementations.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  const AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String role = 'passenger',
  }) =>
      dataSource.sendOtp(phone: phone, role: role);

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String role = 'passenger',
  }) => dataSource.verifyOtp(phone: phone, otp: otp, role: role);

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    String? email,
    String? gender,
    required String role,
  }) => dataSource.register(
    name: name,
    phone: phone,
    email: email,
    gender: gender,
    role: role,
  );

  @override
  Future<Either<Failure, void>> logout() => dataSource.logout();

  @override
  Future<Either<Failure, bool>> isLoggedIn() => dataSource.isLoggedIn();

  @override
  Future<Either<Failure, UserEntity>> getCachedUser() =>
      dataSource.getCachedUser();
}
