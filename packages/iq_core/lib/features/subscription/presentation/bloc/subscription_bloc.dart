import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/subscription_models.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository})
      : super(const SubscriptionState()) {
    on<SubscriptionLoadPlans>(_onLoadPlans);
    on<SubscriptionPlanSelected>(_onPlanSelected);
    on<SubscriptionFreeDayToggled>(_onFreeDayToggled);
    on<SubscriptionPaymentMethodChanged>(_onPaymentMethodChanged);
    on<SubscriptionConfirmed>(_onConfirmed);
    on<SubscriptionPaymentCompleted>(_onPaymentCompleted);
    on<SubscriptionChoosePlan>(_onChoosePlan);
  }

  Future<void> _onLoadPlans(
    SubscriptionLoadPlans event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(
      status: SubscriptionViewStatus.loading,
      activeSubscription: event.activeSubscription,
      hasSubscription: event.hasSubscription,
      isExpired: event.isExpired,
      walletBalance: event.walletBalance,
      currencySymbol: event.currencySymbol,
    ));

    // Fetch plans from API
    final result = await repository.getPlans();

    result.fold(
      (failure) {
        // Even on failure, determine the initial view based on subscription state.
        emit(state.copyWith(
          status: _determineInitialView(event),
          errorMessage: failure.message,
        ));
      },
      (plans) {
        emit(state.copyWith(
          plans: plans,
          status: _determineInitialView(event),
        ));
      },
    );
  }

  SubscriptionViewStatus _determineInitialView(SubscriptionLoadPlans event) {
    // Active and not expired → success screen
    if (event.hasSubscription &&
        !event.isExpired &&
        event.activeSubscription != null) {
      return SubscriptionViewStatus.active;
    }
    // Expired → expired screen
    if (event.isExpired) {
      return SubscriptionViewStatus.expired;
    }
    // No subscription at all → no-subscription screen
    if (event.activeSubscription == null) {
      return SubscriptionViewStatus.noSubscription;
    }
    // Fallback
    return SubscriptionViewStatus.noSubscription;
  }

  void _onPlanSelected(
    SubscriptionPlanSelected event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(selectedPlanIndex: event.index));
  }

  void _onFreeDayToggled(
    SubscriptionFreeDayToggled event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(isFreeDayOn: event.isFreeDayOn));
  }

  void _onPaymentMethodChanged(
    SubscriptionPaymentMethodChanged event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(paymentOption: event.paymentOption));
  }

  Future<void> _onConfirmed(
    SubscriptionConfirmed event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state.plans.isEmpty) return;

    final plan = state.plans[state.selectedPlanIndex];
    final isFreeDay = state.isFreeDayOn;
    final paymentOpt = state.paymentOption;

    // Wallet payment + NOT free day → check balance
    if (paymentOpt == 2 && !isFreeDay) {
      if (plan.amount > state.walletBalance) {
        emit(state.copyWith(
          errorMessage: 'رصيد المحفظة غير كافي للاشتراك',
        ));
        // Re-emit planList to clear the error on next build
        emit(state.copyWith(status: SubscriptionViewStatus.planList));
        return;
      }
    }

    emit(state.copyWith(status: SubscriptionViewStatus.submitting));

    final result = await repository.subscribe(
      paymentOpt: paymentOpt,
      day: isFreeDay ? 0 : 1,
      planIds: plan.ids,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: SubscriptionViewStatus.error,
          errorMessage: failure.message,
        ));
      },
      (SubscribeResult subscribeResult) {
        final url = subscribeResult.paymentUrl;
        final msg = subscribeResult.message;
        if (url != null && url.isNotEmpty) {
          // Card payment → redirect to WebView
          emit(state.copyWith(
            status: SubscriptionViewStatus.planList,
            paymentUrl: url,
          ));
        } else if (subscribeResult.isSubscribed) {
          // Wallet or free → success
          emit(state.copyWith(
            status: SubscriptionViewStatus.success,
            successMessage: msg ?? 'تم الاشتراك بنجاح',
          ));
        } else {
          // Free subscription with expiry info
          emit(state.copyWith(
            status: SubscriptionViewStatus.success,
            successMessage: msg ?? 'تم الاشتراك بنجاح',
          ));
        }
      },
    );
  }

  Future<void> _onPaymentCompleted(
    SubscriptionPaymentCompleted event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (event.success) {
      // Payment succeeded → reload plans to verify subscription status.
      emit(state.copyWith(
        status: SubscriptionViewStatus.loading,
        paymentUrl: null,
      ));
      final result = await repository.getPlans();
      result.fold(
        (_) => emit(state.copyWith(
          status: SubscriptionViewStatus.success,
          successMessage: 'تم الاشتراك بنجاح',
        )),
        (plans) => emit(state.copyWith(
          status: SubscriptionViewStatus.success,
          plans: plans,
          successMessage: 'تم الاشتراك بنجاح',
        )),
      );
    } else {
      // Payment failed or cancelled → back to plan list.
      emit(state.copyWith(
        status: SubscriptionViewStatus.planList,
        paymentUrl: null,
        errorMessage: 'فشلت عملية الدفع، يرجى المحاولة مرة أخرى',
      ));
    }
  }

  void _onChoosePlan(
    SubscriptionChoosePlan event,
    Emitter<SubscriptionState> emit,
  ) {
    emit(state.copyWith(status: SubscriptionViewStatus.planList));
  }
}
