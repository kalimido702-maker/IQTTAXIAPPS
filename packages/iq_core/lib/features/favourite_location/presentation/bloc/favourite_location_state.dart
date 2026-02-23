import 'package:equatable/equatable.dart';

import '../../../home/data/models/home_data_model.dart';

/// States for [FavouriteLocationBloc].
abstract class FavouriteLocationState extends Equatable {
  const FavouriteLocationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before data is provided.
class FavouriteLocationInitial extends FavouriteLocationState {
  const FavouriteLocationInitial();
}

/// Loading state while fetching from the API.
class FavouriteLocationLoading extends FavouriteLocationState {
  const FavouriteLocationLoading();
}

/// Locations loaded successfully.
class FavouriteLocationLoaded extends FavouriteLocationState {
  final List<FavouriteLocationModel> homeLocations;
  final List<FavouriteLocationModel> workLocations;
  final List<FavouriteLocationModel> otherLocations;

  const FavouriteLocationLoaded({
    required this.homeLocations,
    required this.workLocations,
    required this.otherLocations,
  });

  FavouriteLocationLoaded copyWith({
    List<FavouriteLocationModel>? homeLocations,
    List<FavouriteLocationModel>? workLocations,
    List<FavouriteLocationModel>? otherLocations,
  }) {
    return FavouriteLocationLoaded(
      homeLocations: homeLocations ?? this.homeLocations,
      workLocations: workLocations ?? this.workLocations,
      otherLocations: otherLocations ?? this.otherLocations,
    );
  }

  @override
  List<Object?> get props => [homeLocations, workLocations, otherLocations];
}

/// Error state.
class FavouriteLocationError extends FavouriteLocationState {
  final String message;

  const FavouriteLocationError(this.message);

  @override
  List<Object?> get props => [message];
}
