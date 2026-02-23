import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/data/models/user_model.dart';

/// Abstract contract for profile data source.
abstract class ProfileDataSource {
  /// Fetch current user profile from API.
  Future<Either<Failure, UserModel>> getProfile();

  /// Update user profile (name, email, gender, profile_picture).
  /// Returns the updated user model.
  Future<Either<Failure, UserModel>> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? profilePicturePath,
  });
}
