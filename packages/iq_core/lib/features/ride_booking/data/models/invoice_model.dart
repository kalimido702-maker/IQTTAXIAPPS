import 'package:equatable/equatable.dart';

/// Trip invoice / fare breakdown shown after trip completion.
class InvoiceModel extends Equatable {
  const InvoiceModel({
    required this.requestId,
    required this.requestNumber,
    this.driverName,
    this.driverImage,
    this.driverRating,
    this.vehicleMake,
    this.vehicleNumber,
    this.vehicleColor,
    this.rideType,
    required this.pickAddress,
    required this.dropAddress,
    required this.duration,
    required this.distance,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.waitingCharge,
    required this.taxes,
    required this.promoDiscount,
    required this.tips,
    required this.totalFare,
    required this.currency,
    required this.currencySymbol,
    required this.paymentMethod,
    this.additionalCharge = 0.0,
    this.cancellationFee = 0.0,
  });

  final String requestId;
  final String requestNumber;
  final String? driverName;
  final String? driverImage;
  final String? driverRating;
  final String? vehicleMake;
  final String? vehicleNumber;
  final String? vehicleColor;
  final String? rideType;
  final String pickAddress;
  final String dropAddress;
  final double duration;
  final double distance;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double waitingCharge;
  final double taxes;
  final double promoDiscount;
  final double tips;
  final double totalFare;
  final String currency;
  final String currencySymbol;
  final int paymentMethod;
  final double additionalCharge;
  final double cancellationFee;

  String get paymentMethodName {
    switch (paymentMethod) {
      case 0:
        return 'بطاقة';
      case 1:
        return 'نقدي';
      case 2:
        return 'محفظة';
      case 3:
        return 'دفع الكتروني';
      default:
        return 'نقدي';
    }
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final driver = data['driver_detail'] as Map<String, dynamic>? ?? {};

    return InvoiceModel(
      requestId: (data['id'] ?? data['request_id'] ?? '').toString(),
      requestNumber:
          (data['request_number'] ?? data['trip_number'] ?? '').toString(),
      driverName: (driver['name'] ?? data['driver_name'])?.toString(),
      driverImage:
          (driver['profile_picture'] ?? data['driver_image'])?.toString(),
      driverRating: (driver['rating'] ?? data['driver_rating'])?.toString(),
      vehicleMake: (data['vehicle_make'] ?? driver['car_make'])?.toString(),
      vehicleNumber:
          (data['vehicle_number'] ?? driver['car_number'])?.toString(),
      vehicleColor: (data['vehicle_color'] ?? driver['car_color'])?.toString(),
      rideType: data['ride_type']?.toString(),
      pickAddress: (data['pick_address'] ?? '').toString(),
      dropAddress: (data['drop_address'] ?? '').toString(),
      duration: (data['total_time'] as num?)?.toDouble() ?? 0.0,
      distance: (data['total_distance'] as num?)?.toDouble() ?? 0.0,
      baseFare: (data['base_price'] as num?)?.toDouble() ?? 0.0,
      distanceFare: (data['distance_price'] as num?)?.toDouble() ?? 0.0,
      timeFare: (data['time_price'] as num?)?.toDouble() ?? 0.0,
      waitingCharge: (data['waiting_charge'] as num?)?.toDouble() ?? 0.0,
      taxes: (data['service_tax'] as num?)?.toDouble() ?? 0.0,
      promoDiscount: (data['promo_discount'] as num?)?.toDouble() ?? 0.0,
      tips: (data['driver_tips'] as num?)?.toDouble() ?? 0.0,
      totalFare: (data['total_amount'] as num?)?.toDouble() ??
          (data['request_eta_amount'] as num?)?.toDouble() ??
          0.0,
      currency: (data['currency'] ?? 'IQD').toString(),
      currencySymbol: (data['currency_symbol'] ?? 'د.ع').toString(),
      paymentMethod: (data['payment_opt'] as num?)?.toInt() ?? 1,
      additionalCharge:
          (data['additional_charge'] as num?)?.toDouble() ?? 0.0,
      cancellationFee:
          (data['cancellation_fee'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [requestId, totalFare];
}
