import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';

/// Contract for auth data operations (remote + local cache).
abstract class AuthDataSource {
  /// Send OTP to [phone]. Returns `true` on success.
  ///
  /// For passengers calls `user/login`, for drivers calls `driver/register`.
  /// Both endpoints trigger server-side OTP delivery.
  Future<Either<Failure, bool>> sendOtp({
    required String phone,
    String role = 'passenger',
  });

  /// Verify OTP. Returns the authenticated [UserEntity] or signals
  /// that the user needs to register.
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String phone,
    required String otp,
    String role = 'passenger',
  });

  /// Register a new user / driver.
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phone,
    String? email,
    String? gender,
    required String role,
  });

  /// Logout — clears token & cached user.
  Future<Either<Failure, void>> logout();

  /// Check if a token exists in local storage.
  Future<Either<Failure, bool>> isLoggedIn();

  /// Return the locally cached user (if any).
  Future<Either<Failure, UserEntity>> getCachedUser();
}
