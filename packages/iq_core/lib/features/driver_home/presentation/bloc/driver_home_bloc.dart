import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/data/models/home_data_model.dart';
import '../../../home/domain/repositories/home_repository.dart';
import 'driver_home_event.dart';
import 'driver_home_state.dart';

/// BLoC that manages DriverHomePage state.
///
/// Fetches driver home data from the API on [DriverHomeLoadRequested]
/// and handles online/offline status toggling.
class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  final HomeRepository repository;

  DriverHomeBloc({
    required this.repository,
    bool initialOnline = false,
  }) : super(DriverHomeState(isOnline: initialOnline)) {
    on<DriverHomeLoadRequested>(_onLoadRequested);
    on<DriverHomeStatusToggled>(_onStatusToggled);
  }

  Future<void> _onLoadRequested(
    DriverHomeLoadRequested event,
    Emitter<DriverHomeState> emit,
  ) async {
    emit(state.copyWith(status: DriverHomeStatus.loading));

    final result = await repository.getUserDetails();

    result.fold(
      (failure) => emit(state.copyWith(
        status: DriverHomeStatus.error,
        errorMessage: failure.message,
      )),
      (HomeDataModel data) => emit(state.copyWith(
        status: DriverHomeStatus.loaded,
        homeData: data,
        isOnline: data.isAvailable ?? false,
      )),
    );
  }

  Future<void> _onStatusToggled(
    DriverHomeStatusToggled event,
    Emitter<DriverHomeState> emit,
  ) async {
    // Mark as toggling so UI can show loading indicator
    emit(state.copyWith(isToggling: true));

    final result = await repository.toggleDriverStatus(
      isOnline: !state.isOnline,
      lat: 0,
      lng: 0,
    );

    result.fold(
      (failure) {
        // Revert on failure — keep current state, clear loading
        emit(state.copyWith(isToggling: false));
      },
      (isActive) => emit(state.copyWith(
        isOnline: isActive,
        isToggling: false,
      )),
    );
  }
}
