part of 'profile_bloc.dart';

/// Events for the Profile feature.
sealed class ProfileEvent {
  const ProfileEvent();
}

/// Load the user profile from API.
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

/// Update the user profile.
class ProfileUpdateRequested extends ProfileEvent {
  final String? name;
  final String? email;
  final String? gender;
  final String? profilePicturePath;

  const ProfileUpdateRequested({
    this.name,
    this.email,
    this.gender,
    this.profilePicturePath,
  });
}

/// Upload a new avatar image.
class ProfileAvatarChanged extends ProfileEvent {
  final String filePath;

  const ProfileAvatarChanged({required this.filePath});
}
