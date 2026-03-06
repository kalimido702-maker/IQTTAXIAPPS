part of 'subscription_bloc.dart';

/// Possible page states.
enum SubscriptionViewStatus {
  /// Initial / loading plans.
  loading,

  /// No subscription — show "no subscription" screen.
  noSubscription,

  /// Subscription expired — show expired screen.
  expired,

  /// Subscription active — show success screen.
  active,

  /// Showing plan list for selection.
  planList,

  /// Submitting subscription.
  submitting,

  /// Subscription completed (just subscribed).
  success,

  /// Error.
  error,
}

class SubscriptionState extends Equatable {
  final SubscriptionViewStatus status;
  final List<SubscriptionPlan> plans;
  final int selectedPlanIndex;
  final bool isFreeDayOn;

  /// 0 = card, 2 = wallet.
  final int paymentOption;

  final ActiveSubscription? activeSubscription;
  final bool hasSubscription;
  final bool isExpired;
  final double walletBalance;
  final String currencySymbol;

  /// Non-null when card payment → redirect to WebView.
  final String? paymentUrl;

  final String? errorMessage;
  final String? successMessage;

  const SubscriptionState({
    this.status = SubscriptionViewStatus.loading,
    this.plans = const [],
    this.selectedPlanIndex = 0,
    this.isFreeDayOn = false,
    this.paymentOption = 2,
    this.activeSubscription,
    this.hasSubscription = false,
    this.isExpired = false,
    this.walletBalance = 0,
    this.currencySymbol = 'IQD',
    this.paymentUrl,
    this.errorMessage,
    this.successMessage,
  });

  SubscriptionState copyWith({
    SubscriptionViewStatus? status,
    List<SubscriptionPlan>? plans,
    int? selectedPlanIndex,
    bool? isFreeDayOn,
    int? paymentOption,
    ActiveSubscription? activeSubscription,
    bool? hasSubscription,
    bool? isExpired,
    double? walletBalance,
    String? currencySymbol,
    String? paymentUrl,
    String? errorMessage,
    String? successMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlanIndex: selectedPlanIndex ?? this.selectedPlanIndex,
      isFreeDayOn: isFreeDayOn ?? this.isFreeDayOn,
      paymentOption: paymentOption ?? this.paymentOption,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      hasSubscription: hasSubscription ?? this.hasSubscription,
      isExpired: isExpired ?? this.isExpired,
      walletBalance: walletBalance ?? this.walletBalance,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      paymentUrl: paymentUrl,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        plans,
        selectedPlanIndex,
        isFreeDayOn,
        paymentOption,
        activeSubscription,
        hasSubscription,
        isExpired,
        walletBalance,
        currencySymbol,
        paymentUrl,
        errorMessage,
        successMessage,
      ];
}
