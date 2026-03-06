import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';
import 'ride_preference_model.dart';

/// Safely parse any JSON value (num, String, null) to double.
double _safeDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

/// Safely parse any JSON value (num, String, null) to int.
int _safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Vehicle type returned from the ETA API.
///
/// Contains pricing, capacity, and configuration for a ride type
/// (e.g., Smart, Plus, Elite, Family).
class VehicleTypeModel extends Equatable {
  const VehicleTypeModel({
    required this.zoneTypeId,
    required this.typeId,
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
    this.distanceInMeters = '',
    this.discountedTotal = 0,
    this.preferences = const [],
  });

  /// Zone-type UUID from the server (e.g. "a64d6e2b-3f6e-...").
  final String zoneTypeId;

  /// Vehicle type UUID — used as `vehicle_type` in create-request.
  final String typeId;
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

  /// Distance in metres as returned by the server (used in create-request).
  final String distanceInMeters;

  /// Discounted total (sent back in create-request when promo is applied).
  final double discountedTotal;

  /// Available ride preferences (e.g. Pet Friendly).
  final List<RidePreferenceModel> preferences;

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    // Parse payment_type — may be a Map or a comma-separated String
    final paymentRaw = json['payment_type'];
    final Map<String, bool> payments = {};
    if (paymentRaw is Map) {
      for (final entry in paymentRaw.entries) {
        payments[entry.key.toString()] =
            entry.value == true || entry.value == 1;
      }
    } else if (paymentRaw is String && paymentRaw.isNotEmpty) {
      for (final method in paymentRaw.split(',')) {
        payments[method.trim()] = true;
      }
    }

    return VehicleTypeModel(
      zoneTypeId: (json['zone_type_id'] ?? '').toString(),
      typeId: (json['type_id'] ?? json['zone_type_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      shortDescription: (json['short_description'] ?? '').toString(),
      capacity: _safeInt(json['capacity'], 4),
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      basePrice: _safeDouble(json['base_price']),
      total: _safeDouble(json['total']),
      approximateFare: _safeDouble(
          json['approximate_fare'] ?? json['approximate_value']),
      minFare: _safeDouble(json['min_fare'] ?? json['min_amount']),
      maxFare: _safeDouble(json['max_fare'] ?? json['max_amount']),
      currency: (json['currency'] ?? json['currency_name'] ?? 'IQD')
          .toString(),
      currencySymbol:
          (json['currency_symbol'] ?? json['currency'] ?? AppStrings.currencyIQD).toString(),
      distance: _safeDouble(json['distance']),
      time: _safeDouble(json['time']),
      dispatchType: (json['dispatch_type'] ?? 'normal').toString(),
      biddingLowPercentage: _safeDouble(json['bidding_low_percentage']),
      biddingHighPercentage: _safeDouble(json['bidding_high_percentage']),
      waitingCharge: _safeDouble(json['waiting_charge']),
      cancellationFee: _safeDouble(json['cancellation_fee']),
      freeWaitingTimeBefore:
          _safeInt(json['free_waiting_time_in_mins_before_trip_start'], 5),
      freeWaitingTimeAfter:
          _safeInt(json['free_waiting_time_in_mins_after_trip_start'], 3),
      paymentTypes: payments,
      promoDiscount: _safeDouble(json['promo_discount']),
      hasDiscount: json['has_discount'] == true,
      promoId: (json['promocode_id'] ?? json['promo_id'])?.toString(),
      distanceInMeters:
          (json['distance_in_meters'] ?? json['distance'] ?? '').toString(),
      discountedTotal: _safeDouble(
          json['discounted_totel'] ?? json['discounted_total']),
      preferences: ((json['preferences'] ?? json['preference']) as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(RidePreferenceModel.fromJson)
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        zoneTypeId,
        typeId,
        name,
        total,
        approximateFare,
        dispatchType,
      ];
}
