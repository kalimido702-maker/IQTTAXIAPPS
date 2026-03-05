import 'package:equatable/equatable.dart';

import '../../data/models/goods_type_model.dart';
import '../../data/models/parcel_request_model.dart';
import '../../../ride_booking/data/models/vehicle_type_model.dart';

enum PackageDeliveryStatus {
  /// Initial state — user sees the address page.
  initial,

  /// User confirmed addresses — now selecting send or receive mode.
  selectingMode,

  /// User picked send/receive — now entering recipient info.
  enteringRecipient,

  /// Loading ETA / goods types.
  loadingBooking,

  /// Showing booking confirmation (vehicle, goods, payment).
  bookingReady,

  /// Selecting goods type from the full-screen radio list.
  selectingGoodsType,

  /// Validating promo code via ETA re-fetch.
  validatingPromo,

  /// Creating the delivery request.
  creatingRequest,

  /// Promo code validated successfully — prices updated.
  promoApplied,

  /// Request created — requestId is available.
  requestCreated,

  /// An error occurred.
  error,
}

class PackageDeliveryState extends Equatable {
  const PackageDeliveryState({
    this.status = PackageDeliveryStatus.initial,
    this.parcelRequest = const ParcelRequestModel(),
    this.vehicleTypes = const [],
    this.selectedVehicleIndex = 0,
    this.goodsTypes = const [],
    this.requestId,
    this.errorMessage,
  });

  final PackageDeliveryStatus status;

  /// Accumulating request data across screens.
  final ParcelRequestModel parcelRequest;

  /// Available vehicle types from ETA.
  final List<VehicleTypeModel> vehicleTypes;
  final int selectedVehicleIndex;

  /// Available goods types from the API.
  final List<GoodsTypeModel> goodsTypes;

  /// Set after successful request creation.
  final String? requestId;

  final String? errorMessage;

  /// Convenience getter for the currently selected vehicle.
  VehicleTypeModel? get selectedVehicle =>
      vehicleTypes.isNotEmpty && selectedVehicleIndex < vehicleTypes.length
          ? vehicleTypes[selectedVehicleIndex]
          : null;

  PackageDeliveryState copyWith({
    PackageDeliveryStatus? status,
    ParcelRequestModel? parcelRequest,
    List<VehicleTypeModel>? vehicleTypes,
    int? selectedVehicleIndex,
    List<GoodsTypeModel>? goodsTypes,
    String? requestId,
    String? errorMessage,
  }) {
    return PackageDeliveryState(
      status: status ?? this.status,
      parcelRequest: parcelRequest ?? this.parcelRequest,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      selectedVehicleIndex: selectedVehicleIndex ?? this.selectedVehicleIndex,
      goodsTypes: goodsTypes ?? this.goodsTypes,
      requestId: requestId ?? this.requestId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        parcelRequest,
        vehicleTypes,
        selectedVehicleIndex,
        goodsTypes,
        requestId,
        errorMessage,
      ];
}
