import 'package:equatable/equatable.dart';
import '../../../home/data/models/home_data_model.dart';

/// Loading status for driver home data
enum DriverHomeStatus { initial, loading, loaded, error }

/// State for DriverHomePage UI
class DriverHomeState extends Equatable {
  final DriverHomeStatus status;
  final HomeDataModel? homeData;
  final bool isOnline;
  final bool isToggling;
  final String? errorMessage;

  const DriverHomeState({
    this.status = DriverHomeStatus.initial,
    this.homeData,
    this.isOnline = false,
    this.isToggling = false,
    this.errorMessage,
  });

  DriverHomeState copyWith({
    DriverHomeStatus? status,
    HomeDataModel? homeData,
    bool? isOnline,
    bool? isToggling,
    String? errorMessage,
  }) {
    return DriverHomeState(
      status: status ?? this.status,
      homeData: homeData ?? this.homeData,
      isOnline: isOnline ?? this.isOnline,
      isToggling: isToggling ?? this.isToggling,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, homeData, isOnline, isToggling, errorMessage];
}
