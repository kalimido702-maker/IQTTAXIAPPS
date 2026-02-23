import 'package:equatable/equatable.dart';
import '../../data/models/home_data_model.dart';
import '../../data/models/ride_module_model.dart';

/// Loading status for home data
enum HomeStatus { initial, loading, loaded, error }

/// State for PassengerHomePage UI
class PassengerHomeState extends Equatable {
  final HomeStatus status;
  final HomeDataModel? homeData;
  final int activeCategory;
  final String? errorMessage;
  final List<RideModuleModel> rideModules;

  const PassengerHomeState({
    this.status = HomeStatus.initial,
    this.homeData,
    this.activeCategory = 0,
    this.errorMessage,
    this.rideModules = const [],
  });

  PassengerHomeState copyWith({
    HomeStatus? status,
    HomeDataModel? homeData,
    int? activeCategory,
    String? errorMessage,
    List<RideModuleModel>? rideModules,
  }) {
    return PassengerHomeState(
      status: status ?? this.status,
      homeData: homeData ?? this.homeData,
      activeCategory: activeCategory ?? this.activeCategory,
      errorMessage: errorMessage ?? this.errorMessage,
      rideModules: rideModules ?? this.rideModules,
    );
  }

  @override
  List<Object?> get props =>
      [status, homeData, activeCategory, errorMessage, rideModules];
}
