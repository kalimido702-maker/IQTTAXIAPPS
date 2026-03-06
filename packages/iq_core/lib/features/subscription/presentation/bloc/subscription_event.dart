part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

/// Load available plans from API.
class SubscriptionLoadPlans extends SubscriptionEvent {
  /// Active subscription coming from user details (nullable).
  final ActiveSubscription? activeSubscription;

  /// Whether the driver currently has an active (non-expired) subscription.
  final bool hasSubscription;

  /// Whether the subscription is expired.
  final bool isExpired;

  /// Driver wallet balance (used to check if wallet has enough funds).
  final double walletBalance;

  /// Currency symbol (e.g. "IQD").
  final String currencySymbol;

  const SubscriptionLoadPlans({
    this.activeSubscription,
    this.hasSubscription = false,
    this.isExpired = false,
    this.walletBalance = 0,
    this.currencySymbol = 'IQD',
  });

  @override
  List<Object?> get props => [
        activeSubscription,
        hasSubscription,
        isExpired,
        walletBalance,
        currencySymbol,
      ];
}

/// User selected a plan.
class SubscriptionPlanSelected extends SubscriptionEvent {
  final int index;
  const SubscriptionPlanSelected(this.index);
  @override
  List<Object?> get props => [index];
}

/// Toggle free-day switch.
class SubscriptionFreeDayToggled extends SubscriptionEvent {
  final bool isFreeDayOn;
  const SubscriptionFreeDayToggled(this.isFreeDayOn);
  @override
  List<Object?> get props => [isFreeDayOn];
}

/// User selected a payment method.
class SubscriptionPaymentMethodChanged extends SubscriptionEvent {
  /// 0 = card, 2 = wallet
  final int paymentOption;
  const SubscriptionPaymentMethodChanged(this.paymentOption);
  @override
  List<Object?> get props => [paymentOption];
}

/// Confirm subscription (triggers API call).
class SubscriptionConfirmed extends SubscriptionEvent {
  const SubscriptionConfirmed();
}

/// Card payment completed — user returned from WebView.
class SubscriptionPaymentCompleted extends SubscriptionEvent {
  /// Whether the payment was successful.
  final bool success;
  const SubscriptionPaymentCompleted({required this.success});
  @override
  List<Object?> get props => [success];
}

/// User chose to pick a plan (from no-sub or expired screen).
class SubscriptionChoosePlan extends SubscriptionEvent {
  const SubscriptionChoosePlan();
}
