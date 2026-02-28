import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/favourite_location_repository.dart';
import 'favourite_location_event.dart';
import 'favourite_location_state.dart';
import '../../../home/data/models/home_data_model.dart';

/// BLoC for the Favourite Location feature.
///
/// Fetches data from the dedicated list API endpoint and handles
/// add / delete operations.
class FavouriteLocationBloc
    extends Bloc<FavouriteLocationEvent, FavouriteLocationState> {
  final FavouriteLocationRepository _repository;

  FavouriteLocationBloc({required FavouriteLocationRepository repository})
      : _repository = repository,
        super(const FavouriteLocationInitial()) {
    on<FavouriteLocationLoadRequested>(_onLoad);
    on<FavouriteLocationInitialized>(_onInitialized);
    on<FavouriteLocationDeleteRequested>(_onDelete);
    on<FavouriteLocationAddRequested>(_onAdd);
  }

  // ──────────────────── LOAD FROM API ────────────────────────

  Future<void> _onLoad(
    FavouriteLocationLoadRequested event,
    Emitter<FavouriteLocationState> emit,
  ) async {
    emit(const FavouriteLocationLoading());

    final result = await _repository.listFavouriteLocations();

    result.fold(
      (failure) => emit(FavouriteLocationError(failure.message)),
      (locations) {
        final home = <FavouriteLocationModel>[];
        final work = <FavouriteLocationModel>[];
        final other = <FavouriteLocationModel>[];

        for (final loc in locations) {
          final name = loc.addressName.toLowerCase().trim();
          if (name == 'home') {
            home.add(loc);
          } else if (name == 'work') {
            work.add(loc);
          } else {
            other.add(loc);
          }
        }

        emit(FavouriteLocationLoaded(
          homeLocations: home,
          workLocations: work,
          otherLocations: other,
        ));
      },
    );
  }

  // ────────────────── INIT WITH LOCAL DATA ───────────────────

  void _onInitialized(
    FavouriteLocationInitialized event,
    Emitter<FavouriteLocationState> emit,
  ) {
    emit(FavouriteLocationLoaded(
      homeLocations: event.homeLocations,
      workLocations: event.workLocations,
      otherLocations: event.otherLocations,
    ));
  }

  // ───────────────────── DELETE ──────────────────────────────

  Future<void> _onDelete(
    FavouriteLocationDeleteRequested event,
    Emitter<FavouriteLocationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FavouriteLocationLoaded) return;

    final result = await _repository.deleteFavouriteLocation(event.id);

    result.fold(
      (failure) => emit(FavouriteLocationError(failure.message)),
      (_) {
        emit(currentState.copyWith(
          homeLocations:
              currentState.homeLocations.where((l) => l.id != event.id).toList(),
          workLocations:
              currentState.workLocations.where((l) => l.id != event.id).toList(),
          otherLocations: currentState.otherLocations
              .where((l) => l.id != event.id)
              .toList(),
        ));
      },
    );
  }

  // ────────────────────────── ADD ────────────────────────────

  Future<void> _onAdd(
    FavouriteLocationAddRequested event,
    Emitter<FavouriteLocationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FavouriteLocationLoaded) return;

    final result = await _repository.addFavouriteLocation(
      lat: event.lat,
      lng: event.lng,
      address: event.address,
      addressName: event.addressName,
    );

    result.fold(
      (failure) {
        emit(FavouriteLocationError(failure.message));
        // Restore the list so user doesn't lose data.
        emit(currentState);
      },
      (_) {
        // Reload the full list from the API to get accurate data.
        add(const FavouriteLocationLoadRequested());
      },
    );
  }
}
