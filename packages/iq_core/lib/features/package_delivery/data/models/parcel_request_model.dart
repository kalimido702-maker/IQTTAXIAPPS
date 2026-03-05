import 'package:equatable/equatable.dart';

/// Holds all the data collected across the parcel flow screens before
/// creating the delivery request via the API.
class ParcelRequestModel extends Equatable {
  const ParcelRequestModel({
    this.parcelType = ParcelType.send,
    this.pickLat = 0,
    this.pickLng = 0,
    this.dropLat = 0,
    this.dropLng = 0,
    this.pickAddress = '',
    this.dropAddress = '',
    this.recipientName = '',
    this.recipientMobile = '',
    this.instructions = '',
    this.receiveSelf = false,
    this.vehicleType = '',
    this.goodsTypeId,
    this.goodsTypeName = '',
    this.goodsQuantity,
    this.paidBy = PaidBy.sender,
    this.paymentOpt = 1,
    this.requestEtaAmount,
    this.polyline,
    this.promoCode,
  });

  /// Send or Receive mode.
  final ParcelType parcelType;

  // ─── Addresses ───
  final double pickLat;
  final double pickLng;
  final double dropLat;
  final double dropLng;
  final String pickAddress;
  final String dropAddress;

  // ─── Recipient / Sender details ───
  final String recipientName;
  final String recipientMobile;
  final String instructions;
  final bool receiveSelf;

  // ─── Vehicle & Goods ───
  final String vehicleType;
  final int? goodsTypeId;
  final String goodsTypeName;
  final String? goodsQuantity; // null = Loose / unspecified
  final PaidBy paidBy;

  // ─── Payment ───
  /// 1 = cash, 2 = wallet, 0 = card, 3 = online
  final int paymentOpt;
  final double? requestEtaAmount;
  final String? polyline;
  final String? promoCode;

  ParcelRequestModel copyWith({
    ParcelType? parcelType,
    double? pickLat,
    double? pickLng,
    double? dropLat,
    double? dropLng,
    String? pickAddress,
    String? dropAddress,
    String? recipientName,
    String? recipientMobile,
    String? instructions,
    bool? receiveSelf,
    String? vehicleType,
    int? goodsTypeId,
    String? goodsTypeName,
    String? goodsQuantity,
    PaidBy? paidBy,
    int? paymentOpt,
    double? requestEtaAmount,
    String? polyline,
    String? promoCode,
  }) {
    return ParcelRequestModel(
      parcelType: parcelType ?? this.parcelType,
      pickLat: pickLat ?? this.pickLat,
      pickLng: pickLng ?? this.pickLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      pickAddress: pickAddress ?? this.pickAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientMobile: recipientMobile ?? this.recipientMobile,
      instructions: instructions ?? this.instructions,
      receiveSelf: receiveSelf ?? this.receiveSelf,
      vehicleType: vehicleType ?? this.vehicleType,
      goodsTypeId: goodsTypeId ?? this.goodsTypeId,
      goodsTypeName: goodsTypeName ?? this.goodsTypeName,
      goodsQuantity: goodsQuantity ?? this.goodsQuantity,
      paidBy: paidBy ?? this.paidBy,
      paymentOpt: paymentOpt ?? this.paymentOpt,
      requestEtaAmount: requestEtaAmount ?? this.requestEtaAmount,
      polyline: polyline ?? this.polyline,
      promoCode: promoCode ?? this.promoCode,
    );
  }

  /// Build the API body for `api/v1/request/delivery/create`.
  Map<String, dynamic> toApiBody() {
    return {
      'is_parcel': 1,
      'parcel_type': parcelType == ParcelType.send ? 'Send Parcel' : 'Receive Parcel',
      'transport_type': 'delivery',
      'pick_lat': pickLat,
      'pick_lng': pickLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'pick_address': pickAddress,
      'drop_address': dropAddress,
      'vehicle_type': vehicleType,
      'payment_opt': paymentOpt,
      'paid_at': paidBy == PaidBy.sender ? 'Sender' : 'Receiver',
      if (recipientName.isNotEmpty) 'pickup_poc_name': recipientName,
      if (recipientMobile.isNotEmpty) 'pickup_poc_mobile': recipientMobile,
      if (instructions.isNotEmpty) 'pickup_poc_instruction': instructions,
      if (recipientName.isNotEmpty) 'drop_poc_name': recipientName,
      if (recipientMobile.isNotEmpty) 'drop_poc_mobile': recipientMobile,
      if (instructions.isNotEmpty) 'drop_poc_instruction': instructions,
      if (goodsTypeId != null) 'goods_type_id': goodsTypeId,
      if (goodsQuantity != null) 'goods_type_quantity': goodsQuantity,
      if (requestEtaAmount != null) 'request_eta_amount': requestEtaAmount,
      if (polyline != null) 'polyline': polyline,
      if (promoCode != null && promoCode!.isNotEmpty) 'promo_code': promoCode,
    };
  }

  @override
  List<Object?> get props => [
        parcelType,
        pickLat,
        pickLng,
        dropLat,
        dropLng,
        pickAddress,
        dropAddress,
        recipientName,
        recipientMobile,
        instructions,
        receiveSelf,
        vehicleType,
        goodsTypeId,
        goodsTypeName,
        goodsQuantity,
        paidBy,
        paymentOpt,
        requestEtaAmount,
        polyline,
        promoCode,
      ];
}

enum ParcelType { send, receive }

enum PaidBy { sender, receiver }
