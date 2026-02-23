import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ride_module_model.dart';
import '../../domain/repositories/home_repository.dart';
import 'passenger_home_event.dart';
import 'passenger_home_state.dart';

/// BLoC that manages PassengerHomePage state.
///
/// Fetches home data and ride modules from the API on
/// [PassengerHomeLoadRequested] and tracks the active service category index.
class PassengerHomeBloc
    extends Bloc<PassengerHomeEvent, PassengerHomeState> {
  final HomeRepository repository;

  PassengerHomeBloc({
    required this.repository,
    int initialCategory = 0,
  }) : super(PassengerHomeState(activeCategory: initialCategory)) {
    on<PassengerHomeLoadRequested>(_onLoadRequested);
    on<PassengerHomeCategoryChanged>(_onCategoryChanged);
  }

  Future<void> _onLoadRequested(
    PassengerHomeLoadRequested event,
    Emitter<PassengerHomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    final userResult = await repository.getUserDetails();
    final modulesResult = await repository.getRideModules();

    userResult.fold(
      (failure) => emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        final List<RideModuleModel> modules = modulesResult.fold(
          (_) => state.rideModules,
          (mods) => mods,
        );

        emit(state.copyWith(
          status: HomeStatus.loaded,
          homeData: data,
          rideModules: modules,
        ));
      },
    );
  }

  void _onCategoryChanged(
    PassengerHomeCategoryChanged event,
    Emitter<PassengerHomeState> emit,
  ) {
    emit(state.copyWith(activeCategory: event.index));
  }
}
