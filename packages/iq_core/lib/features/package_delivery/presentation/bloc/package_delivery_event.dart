import 'package:equatable/equatable.dart';

import '../../data/models/parcel_request_model.dart';

/// Events for [PackageDeliveryBloc].
sealed class PackageDeliveryEvent extends Equatable {
  const PackageDeliveryEvent();

  @override
  List<Object?> get props => [];
}

/// User chose Send or Receive from the landing page.
class PackageDeliveryModeSelected extends PackageDeliveryEvent {
  const PackageDeliveryModeSelected(this.parcelType);
  final ParcelType parcelType;

  @override
  List<Object?> get props => [parcelType];
}

/// User confirmed pickup + drop addresses.
class PackageDeliveryAddressesConfirmed extends PackageDeliveryEvent {
  const PackageDeliveryAddressesConfirmed({
    required this.pickLat,
    required this.pickLng,
    required this.dropLat,
    required this.dropLng,
    required this.pickAddress,
    required this.dropAddress,
  });

  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;
  final String pickAddress;
  final String dropAddress;

  @override
  List<Object?> get props =>
      [pickLat, pickLng, dropLat, dropLng, pickAddress, dropAddress];
}

/// User confirmed recipient details (name, mobile, instructions).
class PackageDeliveryRecipientConfirmed extends PackageDeliveryEvent {
  const PackageDeliveryRecipientConfirmed({
    required this.name,
    required this.mobile,
    this.instructions = '',
    this.receiveSelf = false,
  });

  final String name;
  final String mobile;
  final String instructions;
  final bool receiveSelf;

  @override
  List<Object?> get props => [name, mobile, instructions, receiveSelf];
}

/// Fetch goods types.
class PackageDeliveryGoodsTypesRequested extends PackageDeliveryEvent {
  const PackageDeliveryGoodsTypesRequested();
}

/// User selected a goods type + optional quantity.
class PackageDeliveryGoodsTypeSelected extends PackageDeliveryEvent {
  const PackageDeliveryGoodsTypeSelected({
    required this.goodsTypeId,
    required this.goodsTypeName,
    this.quantity,
  });

  final int goodsTypeId;
  final String goodsTypeName;
  final String? quantity;

  @override
  List<Object?> get props => [goodsTypeId, goodsTypeName, quantity];
}

/// User changed who pays: sender or receiver.
class PackageDeliveryPaidByChanged extends PackageDeliveryEvent {
  const PackageDeliveryPaidByChanged(this.paidBy);
  final PaidBy paidBy;

  @override
  List<Object?> get props => [paidBy];
}

/// User changed payment method.
class PackageDeliveryPaymentChanged extends PackageDeliveryEvent {
  const PackageDeliveryPaymentChanged(this.paymentOpt);
  final int paymentOpt;

  @override
  List<Object?> get props => [paymentOpt];
}

/// User selected a vehicle type from the ETA list.
class PackageDeliveryVehicleSelected extends PackageDeliveryEvent {
  const PackageDeliveryVehicleSelected(this.vehicleIndex);
  final int vehicleIndex;

  @override
  List<Object?> get props => [vehicleIndex];
}

/// User applied or removed a promo code.
class PackageDeliveryPromoApplied extends PackageDeliveryEvent {
  const PackageDeliveryPromoApplied(this.promoCode);
  final String? promoCode;

  @override
  List<Object?> get props => [promoCode];
}

/// User pressed "ركوب الآن" — create the delivery request.
class PackageDeliveryCreateRequested extends PackageDeliveryEvent {
  const PackageDeliveryCreateRequested();
}

/// Reset state to initial.
class PackageDeliveryReset extends PackageDeliveryEvent {
  const PackageDeliveryReset();
}
