import 'package:equatable/equatable.dart';

/// Vehicle type returned from the ETA API.
///
/// Contains pricing, capacity, and configuration for a ride type
/// (e.g., Smart, Plus, Elite, Family).
class VehicleTypeModel extends Equatable {
  const VehicleTypeModel({
    required this.zoneTypeId,
    required this.name,
    required this.icon,
    required this.shortDescription,
    required this.capacity,
    required this.isDefault,
    required this.basePrice,
    required this.total,
    required this.approximateFare,
    required this.minFare,
    required this.maxFare,
    required this.currency,
    required this.currencySymbol,
    required this.distance,
    required this.time,
    required this.dispatchType,
    required this.biddingLowPercentage,
    required this.biddingHighPercentage,
    required this.waitingCharge,
    required this.cancellationFee,
    required this.freeWaitingTimeBefore,
    required this.freeWaitingTimeAfter,
    required this.paymentTypes,
    required this.promoDiscount,
    required this.hasDiscount,
    this.promoId,
  });

  final int zoneTypeId;
  final String name;
  final String icon;
  final String shortDescription;
  final int capacity;
  final bool isDefault;
  final double basePrice;
  final double total;
  final double approximateFare;
  final double minFare;
  final double maxFare;
  final String currency;
  final String currencySymbol;
  final double distance;
  final double time;

  /// "normal" | "bidding" | "both"
  final String dispatchType;
  final double biddingLowPercentage;
  final double biddingHighPercentage;
  final double waitingCharge;
  final double cancellationFee;

  /// Free waiting minutes before trip starts.
  final int freeWaitingTimeBefore;

  /// Free waiting minutes after trip starts.
  final int freeWaitingTimeAfter;

  /// Payment options: cash, wallet, card, online_payment.
  final Map<String, bool> paymentTypes;

  final double promoDiscount;
  final bool hasDiscount;
  final String? promoId;

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    // Parse payment_type map safely
    final paymentRaw = json['payment_type'];
    final Map<String, bool> payments = {};
    if (paymentRaw is Map) {
      for (final entry in paymentRaw.entries) {
        payments[entry.key.toString()] = entry.value == true || entry.value == 1;
      }
    }

    return VehicleTypeModel(
      zoneTypeId: (json['zone_type_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      shortDescription: (json['short_description'] ?? '').toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      approximateFare: (json['approximate_fare'] as num?)?.toDouble() ?? 0.0,
      minFare: (json['min_fare'] as num?)?.toDouble() ?? 0.0,
      maxFare: (json['max_fare'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'IQD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'د.ع').toString(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      dispatchType: (json['dispatch_type'] ?? 'normal').toString(),
      biddingLowPercentage:
          (json['bidding_low_percentage'] as num?)?.toDouble() ?? 0.0,
      biddingHighPercentage:
          (json['bidding_high_percentage'] as num?)?.toDouble() ?? 0.0,
      waitingCharge: (json['waiting_charge'] as num?)?.toDouble() ?? 0.0,
      cancellationFee: (json['cancellation_fee'] as num?)?.toDouble() ?? 0.0,
      freeWaitingTimeBefore:
          (json['free_waiting_time_in_mins_before_trip_start'] as num?)
                  ?.toInt() ??
              5,
      freeWaitingTimeAfter:
          (json['free_waiting_time_in_mins_after_trip_start'] as num?)
                  ?.toInt() ??
              3,
      paymentTypes: payments,
      promoDiscount: (json['promo_discount'] as num?)?.toDouble() ?? 0.0,
      hasDiscount: json['has_discount'] == true,
      promoId: json['promo_id']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        zoneTypeId,
        name,
        total,
        approximateFare,
        dispatchType,
      ];
}
