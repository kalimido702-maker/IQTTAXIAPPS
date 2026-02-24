import 'package:equatable/equatable.dart';

import '../../../data/models/active_trip_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/vehicle_type_model.dart';

/// The overall status of the passenger trip flow.
enum PassengerTripStatus {
  /// No active trip — user is on home screen.
  initial,

  /// Loading ETA / vehicle types.
  loadingEta,

  /// Vehicle types loaded, user selecting ride.
  selectingRide,

  /// Creating the ride request with backend.
  creatingRequest,

  /// Request created, searching for driver.
  searchingDriver,

  /// Driver found, on the way / arrived / trip in progress.
  activeTrip,

  /// Trip completed — invoice shown.
  tripCompleted,

  /// User submitted rating — flow done.
  rated,

  /// Trip was cancelled.
  cancelled,

  /// Error occurred.
  error,
}

/// State for the passenger trip BLoC.
class PassengerTripState extends Equatable {
  const PassengerTripState({
    this.status = PassengerTripStatus.initial,
    this.vehicleTypes = const [],
    this.selectedVehicle,
    this.paymentOpt = 1,
    this.pickLat = 0,
    this.pickLng = 0,
    this.dropLat = 0,
    this.dropLng = 0,
    this.pickAddress = '',
    this.dropAddress = '',
    this.requestId,
    this.activeTripData,
    this.invoice,
    this.errorMessage,
    this.promoCode,
  });

  final PassengerTripStatus status;

  /// Available vehicle types from ETA.
  final List<VehicleTypeModel> vehicleTypes;

  /// User's selected vehicle type.
  final VehicleTypeModel? selectedVehicle;

  /// Payment option: 1=cash, 2=wallet, 0=card, 3=online.
  final int paymentOpt;

  /// Trip coordinates.
  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;
  final String pickAddress;
  final String dropAddress;

  /// Active trip request ID.
  final String? requestId;

  /// Real-time trip data from Firebase.
  final ActiveTripModel? activeTripData;

  /// Invoice / fare breakdown after trip completion.
  final InvoiceModel? invoice;

  /// Error message, if any.
  final String? errorMessage;

  /// Applied promo code.
  final String? promoCode;

  PassengerTripState copyWith({
    PassengerTripStatus? status,
    List<VehicleTypeModel>? vehicleTypes,
    VehicleTypeModel? selectedVehicle,
    int? paymentOpt,
    double? pickLat,
    double? pickLng,
    double? dropLat,
    double? dropLng,
    String? pickAddress,
    String? dropAddress,
    String? requestId,
    ActiveTripModel? activeTripData,
    InvoiceModel? invoice,
    String? errorMessage,
    String? promoCode,
  }) {
    return PassengerTripState(
      status: status ?? this.status,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      paymentOpt: paymentOpt ?? this.paymentOpt,
      pickLat: pickLat ?? this.pickLat,
      pickLng: pickLng ?? this.pickLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      pickAddress: pickAddress ?? this.pickAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      requestId: requestId ?? this.requestId,
      activeTripData: activeTripData ?? this.activeTripData,
      invoice: invoice ?? this.invoice,
      errorMessage: errorMessage,
      promoCode: promoCode ?? this.promoCode,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vehicleTypes,
        selectedVehicle,
        paymentOpt,
        requestId,
        activeTripData,
        invoice,
        errorMessage,
      ];
}
