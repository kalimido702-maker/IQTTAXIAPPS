import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Profile repository contract (Domain layer)
abstract class ProfileRepository {
  /// Get user profile
  Future<Either<Failure, UserEntity>> getProfile();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? email,
    String? gender,
  });

  /// Upload avatar image
  Future<Either<Failure, String>> uploadAvatar(String filePath);
}
