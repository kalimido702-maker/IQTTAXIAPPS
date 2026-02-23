import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

/// Production implementation of [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, UserEntity>> getProfile() async {
    return dataSource.getProfile();
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? email,
    String? gender,
  }) async {
    return dataSource.updateProfile(
      name: name,
      email: email,
      gender: gender,
    );
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(String filePath) async {
    final result = await dataSource.updateProfile(
      profilePicturePath: filePath,
    );
    return result.map((user) => user.avatarUrl ?? '');
  }
}
