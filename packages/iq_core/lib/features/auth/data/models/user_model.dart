import '../../domain/entities/user_entity.dart';

/// Data model for user — maps API JSON to [UserEntity].
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.avatarUrl,
    super.gender,
    required super.role,
    super.rating,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      name: (json['name'] ?? json['firstname'] ?? '').toString(),
      phone: (json['mobile'] ?? json['phone'] ?? '').toString(),
      email: json['email'] as String?,
      avatarUrl: json['profile_picture'] as String?,
      gender: json['gender'] as String?,
      role: (json['role'] ?? 'passenger').toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': phone,
      'email': email,
      'profile_picture': avatarUrl,
      'gender': gender,
      'role': role,
      'rating': rating,
      'is_verified': isVerified,
    };
  }
}
