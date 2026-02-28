import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

/// BLoC managing wallet state: balance, transactions, deposit, transfer.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository repository;

  WalletBloc({required this.repository}) : super(const WalletState()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletLoadMoreRequested>(_onLoadMoreRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletDepositRequested>(_onDepositRequested);
    on<WalletPaymentCompleted>(_onPaymentCompleted);
    on<WalletTransferRequested>(_onTransferRequested);
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.loading));

    final result = await repository.getWalletHistory(page: 1);

    result.fold(
      (failure) => emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: failure.message,
      )),
      (wallet) => emit(state.copyWith(
        status: WalletStatus.loaded,
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
        transactions: wallet.transactions,
        currentPage: wallet.currentPage,
        lastPage: wallet.lastPage,
        hasMore: wallet.hasMorePages,
      )),
    );
  }

  Future<void> _onLoadMoreRequested(
    WalletLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.status == WalletStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(status: WalletStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await repository.getWalletHistory(page: nextPage);

    result.fold(
      (failure) => emit(state.copyWith(status: WalletStatus.loaded)),
      (wallet) => emit(state.copyWith(
        status: WalletStatus.loaded,
        balance: wallet.balance,
        transactions: [...state.transactions, ...wallet.transactions],
        currentPage: wallet.currentPage,
        lastPage: wallet.lastPage,
        hasMore: wallet.hasMorePages,
      )),
    );
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    final result = await repository.getWalletHistory(page: 1);

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (wallet) => emit(state.copyWith(
        status: WalletStatus.loaded,
        balance: wallet.balance,
        currencyCode: wallet.currencyCode,
        transactions: wallet.transactions,
        currentPage: wallet.currentPage,
        lastPage: wallet.lastPage,
        hasMore: wallet.hasMorePages,
      )),
    );
  }

  Future<void> _onDepositRequested(
    WalletDepositRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(actionStatus: WalletActionStatus.processing));

    final result =
        await repository.createWalletPayment(amount: event.amount);

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: WalletActionStatus.failed,
        actionMessage: failure.message,
      )),
      (paymentUrl) {
        emit(state.copyWith(
          actionStatus: WalletActionStatus.paymentUrlReady,
          paymentUrl: paymentUrl,
        ));
      },
    );
  }

  void _onPaymentCompleted(
    WalletPaymentCompleted event,
    Emitter<WalletState> emit,
  ) {
    if (event.success) {
      emit(state.copyWith(
        actionStatus: WalletActionStatus.success,
        actionMessage: AppStrings.depositSuccess,
      ));
      // Refresh wallet to get updated balance
      add(const WalletRefreshRequested());
    } else {
      emit(state.copyWith(
        actionStatus: WalletActionStatus.failed,
        actionMessage: AppStrings.paymentFailed,
      ));
    }
  }

  Future<void> _onTransferRequested(
    WalletTransferRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(actionStatus: WalletActionStatus.processing));

    final result = await repository.transferMoney(
      amount: event.amount,
      mobile: event.mobile,
      role: event.role,
      countryCode: event.countryCode,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        actionStatus: WalletActionStatus.failed,
        actionMessage: failure.message,
      )),
      (message) {
        emit(state.copyWith(
          actionStatus: WalletActionStatus.success,
          actionMessage: message,
        ));
        // Refresh to get updated balance
        add(const WalletRefreshRequested());
      },
    );
  }
}
