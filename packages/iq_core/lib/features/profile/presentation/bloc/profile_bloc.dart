import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/profile_data_source.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC for managing profile view/edit.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileDataSource dataSource;

  ProfileBloc({required this.dataSource}) : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileAvatarChanged>(_onAvatarChanged);
  }

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));

    final result = await dataSource.getProfile();

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        user: user,
      )),
    );
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await dataSource.updateProfile(
      name: event.name,
      email: event.email,
      gender: event.gender,
      profilePicturePath: event.profilePicturePath,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: ProfileStatus.updated,
        user: user,
      )),
    );
  }

  Future<void> _onAvatarChanged(
    ProfileAvatarChanged event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.updating));

    final result = await dataSource.updateProfile(
      profilePicturePath: event.filePath,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: ProfileStatus.updated,
        user: user,
      )),
    );
  }
}
