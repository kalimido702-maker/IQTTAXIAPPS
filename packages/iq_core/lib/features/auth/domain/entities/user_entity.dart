import 'package:equatable/equatable.dart';

/// User entity - core domain model
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? gender;
  final String role; // 'passenger' or 'driver'
  final double? rating;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.gender,
    required this.role,
    this.rating,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        avatarUrl,
        gender,
        role,
        rating,
        isVerified,
      ];
}
