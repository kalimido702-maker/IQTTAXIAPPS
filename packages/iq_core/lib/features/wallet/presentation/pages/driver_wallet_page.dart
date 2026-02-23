import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../domain/entities/wallet_entity.dart';
import '../bloc/wallet_bloc.dart';
import 'driver_add_balance_page.dart';
import 'driver_withdraw_page.dart';
import '../widgets/transfer_bottom_sheet.dart';

/// Driver Wallet Page — المحفظة
///
/// Displays black balance card, action buttons (add, transfer, withdraw),
/// and recent transactions list.
class DriverWalletPage extends StatelessWidget {
  const DriverWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: IqAppBar(title: AppStrings.wallet),
      body: BlocConsumer<WalletBloc, WalletState>(
        listenWhen: (prev, curr) =>
            prev.actionStatus != curr.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == WalletActionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage ?? AppStrings.depositSuccess),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.actionStatus == WalletActionStatus.failed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage ?? AppStrings.somethingWrong),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == WalletStatus.loading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }

          if (state.status == WalletStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IqText(
                    state.errorMessage ?? AppStrings.somethingWrong,
                    style: AppTypography.bodyLarge,
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => context
                        .read<WalletBloc>()
                        .add(const WalletLoadRequested()),
                    child: IqText(
                      AppStrings.retry,
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<WalletBloc>().add(const WalletRefreshRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),

                  // ── Balance Card ──
                  _BalanceCard(state: state),
                  SizedBox(height: 30.h),

                  // ── Action Buttons ──
                  _ActionButtons(state: state),
                  SizedBox(height: 30.h),

                  // ── Recent Transactions ──
                  _TransactionsSection(
                    state: state,
                    onLoadMore: () {
                      context
                          .read<WalletBloc>()
                          .add(const WalletLoadMoreRequested());
                    },
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Black Balance Card ───────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          IqText(
            AppStrings.walletBalance,
            style: AppTypography.heading3.copyWith(
              color: AppColors.white,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 15.h),
          IqText(
            state.formattedBalance,
            style: AppTypography.heading1.copyWith(
              color: AppColors.white,
              fontSize: 35.sp,
              fontFamily: AppTypography.fontFamilyLatin,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ───────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add balance — full width yellow
        SizedBox(
          width: double.infinity,
          height: 60.h,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: context.read<WalletBloc>(),
                    child: const DriverAddBalancePage(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonYellow,
              foregroundColor: AppColors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000.r),
              ),
            ),
            icon: Icon(Icons.add_circle_outline, size: 24.w),
            label: IqText(
              AppStrings.addBalance,
              style: AppTypography.button,
            ),
          ),
        ),
        SizedBox(height: 15.h),

        // Transfer + Withdraw row
        Row(
          children: [
            // Transfer
            Expanded(
              child: SizedBox(
                height: 60.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    TransferBottomSheet.show(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                  ),
                  icon: Icon(Icons.swap_horiz, size: 24.w,
                      color: AppColors.black),
                  label: IqText(
                    AppStrings.transfer,
                    style: AppTypography.button.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 15.w),
            // Withdraw
            Expanded(
              child: SizedBox(
                height: 60.h,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<WalletBloc>(),
                          child: const DriverWithdrawPage(),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                  ),
                  icon: Icon(Icons.north_east, size: 24.w,
                      color: AppColors.black),
                  label: IqText(
                    AppStrings.withdraw,
                    style: AppTypography.button.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Transactions Section ─────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({
    required this.state,
    required this.onLoadMore,
  });

  final WalletState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          AppStrings.recentTransactions,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textDark,
            fontSize: 18.sp,
          ),
        ),
        SizedBox(height: 16.h),

        if (state.transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: IqText(
                AppStrings.noPaymentHistory,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.gray2),
              ),
            ),
          )
        else
          ...state.transactions.map(
            (tx) => _DriverTransactionItem(
              transaction: tx,
              currencyCode: state.currencyCode,
            ),
          ),

        if (state.status == WalletStatus.loadingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class _DriverTransactionItem extends StatelessWidget {
  const _DriverTransactionItem({
    required this.transaction,
    required this.currencyCode,
  });

  final WalletTransactionEntity transaction;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amount = transaction.amount.toStringAsFixed(0);
    final formattedAmount = amount.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    final description = transaction.remarks.isNotEmpty
        ? transaction.remarks
        : (isCredit
            ? '${AppStrings.balanceAdded} $formattedAmount $currencyCode'
            : '${AppStrings.balanceWithdrawn} $formattedAmount $currencyCode');

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              // Arrow icon
              Icon(
                isCredit ? Icons.south_west : Icons.north_east,
                size: 24.w,
                color: isCredit
                    ? AppColors.transactionCredit
                    : AppColors.transactionDebit,
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IqText(
                      description,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textDark,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Date
                        IqText(
                          _formatDate(transaction.createdAt),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textAddress,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 40.w),
                        // Time with clock icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18.w,
                              color: AppColors.textAddress,
                            ),
                            SizedBox(width: 5.w),
                            IqText(
                              _formatTime(transaction.createdAt),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textAddress,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 0.5,
          color: AppColors.grayBorder,
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = AppStrings.arabicMonths;
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }
}
