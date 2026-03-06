import 'package:equatable/equatable.dart';

// ═════════════════════════════════════════════════════════════════════
//  Subscription Plan (from GET api/v1/driver/list_of_plans)
// ═════════════════════════════════════════════════════════════════════

class SubscriptionPlan extends Equatable {
  final List<int> ids;
  final String name;
  final String? description;
  final int duration;
  final String currencySymbol;
  final int amount;
  final List<String> vehicleTypeIds;
  final String? vehicleTypeName;

  const SubscriptionPlan({
    required this.ids,
    required this.name,
    this.description,
    required this.duration,
    required this.currencySymbol,
    required this.amount,
    this.vehicleTypeIds = const [],
    this.vehicleTypeName,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      ids: (json['id'] is List)
          ? List<int>.from((json['id'] as List).map((e) => (e as num).toInt()))
          : [if (json['id'] != null) (json['id'] as num).toInt()],
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      currencySymbol: (json['currency_symbol'] ?? 'IQD').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      vehicleTypeIds: json['vehicle_type_id'] is List
          ? List<String>.from(
              (json['vehicle_type_id'] as List).map((e) => e.toString()))
          : [],
      vehicleTypeName: json['vehicle_type_name']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [ids, name, description, duration, currencySymbol, amount];
}

// ═════════════════════════════════════════════════════════════════════
//  Active Subscription (from user details API)
// ═════════════════════════════════════════════════════════════════════

class ActiveSubscription extends Equatable {
  final String id;
  final int subscriptionId;
  final String subscriptionName;
  final String transactionId;
  final int paidAmount;
  final String expiredAt;
  final String startedAt;
  final int subscriptionType;

  const ActiveSubscription({
    required this.id,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.transactionId,
    required this.paidAmount,
    required this.expiredAt,
    required this.startedAt,
    required this.subscriptionType,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data')
        ? json['data'] as Map<String, dynamic>
        : json;
    return ActiveSubscription(
      id: (data['id'] ?? '').toString(),
      subscriptionId: (data['subscription_id'] as num?)?.toInt() ?? 0,
      subscriptionName: (data['subscription_name'] ?? '').toString(),
      transactionId: (data['transaction_id'] ?? '').toString(),
      paidAmount: (data['paid_amount'] as num?)?.toInt() ?? 0,
      expiredAt: (data['expired_at'] ?? '').toString(),
      startedAt: (data['started_at'] ?? '').toString(),
      subscriptionType: (data['subscription_type'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, subscriptionId, subscriptionName, expiredAt];
}

// ═════════════════════════════════════════════════════════════════════
//  Subscribe Response (from POST api/v1/driver/subscribe)
// ═════════════════════════════════════════════════════════════════════

class SubscribeResult extends Equatable {
  /// True → wallet payment succeeded directly.
  final bool isSubscribed;

  /// Non-null → card payment; redirect user to this URL.
  final String? paymentUrl;

  /// For free subscription:
  final int? freeDays;
  final int? remainingFreeDays;
  final String? expiredAt;

  /// Success message from server.
  final String? message;

  const SubscribeResult({
    this.isSubscribed = false,
    this.paymentUrl,
    this.freeDays,
    this.remainingFreeDays,
    this.expiredAt,
    this.message,
  });

  @override
  List<Object?> get props =>
      [isSubscribed, paymentUrl, freeDays, remainingFreeDays, expiredAt];
}
