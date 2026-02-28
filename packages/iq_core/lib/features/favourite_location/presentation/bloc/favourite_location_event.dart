import 'package:equatable/equatable.dart';

import '../../../home/data/models/home_data_model.dart';

/// Events for [FavouriteLocationBloc].
abstract class FavouriteLocationEvent extends Equatable {
  const FavouriteLocationEvent();

  @override
  List<Object?> get props => [];
}

/// Load favourite locations from the backend API.
class FavouriteLocationLoadRequested extends FavouriteLocationEvent {
  const FavouriteLocationLoadRequested();
}

/// Initialize the BLoC with existing data from [HomeDataModel].
class FavouriteLocationInitialized extends FavouriteLocationEvent {
  final List<FavouriteLocationModel> homeLocations;
  final List<FavouriteLocationModel> workLocations;
  final List<FavouriteLocationModel> otherLocations;

  const FavouriteLocationInitialized({
    required this.homeLocations,
    required this.workLocations,
    required this.otherLocations,
  });

  @override
  List<Object?> get props => [homeLocations, workLocations, otherLocations];
}

/// Delete a favourite location.
class FavouriteLocationDeleteRequested extends FavouriteLocationEvent {
  final int id;

  const FavouriteLocationDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Add a new favourite location.
class FavouriteLocationAddRequested extends FavouriteLocationEvent {
  final double lat;
  final double lng;
  final String address;
  final String addressName;

  const FavouriteLocationAddRequested({
    required this.lat,
    required this.lng,
    required this.address,
    required this.addressName,
  });

  @override
  List<Object?> get props => [lat, lng, address, addressName];
}
