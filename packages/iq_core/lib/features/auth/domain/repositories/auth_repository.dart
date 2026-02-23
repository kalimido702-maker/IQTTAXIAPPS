import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Auth repository contract (Domain layer)
abstract class AuthRepository {
  /// Send OTP to phone number
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String role = 'passenger',
  });

  /// Verify OTP code
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String role = 'passenger',
  });

  /// Register new user
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    String? email,
    String? gender,
    required String role,
  });

  /// Logout
  Future<Either<Failure, void>> logout();

  /// Check if user is logged in
  Future<Either<Failure, bool>> isLoggedIn();

  /// Get cached user
  Future<Either<Failure, UserEntity>> getCachedUser();
}
