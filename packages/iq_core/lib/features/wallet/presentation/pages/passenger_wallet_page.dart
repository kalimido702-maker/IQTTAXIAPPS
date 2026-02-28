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
import '../widgets/deposit_bottom_sheet.dart';
import '../widgets/transfer_bottom_sheet.dart';

/// Passenger Wallet Page — رصيد المحفظة
///
/// Displays balance card, payment method, recent transactions,
/// and action buttons for deposit & transfer.
class PassengerWalletPage extends StatelessWidget {
  const PassengerWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // appBar: const IqAppBar(title: AppStrings.walletBalance),
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

          return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Yellow Header Area ──
                  _HeaderSection(state: state),
                  // SizedBox(height: 24.h),

                  // ── Recent Transactions (with pull-to-refresh) ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context
                            .read<WalletBloc>()
                            .add(const WalletRefreshRequested());
                      },
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 150.h,
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _TransactionsSection(state: state),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // ── Action Buttons ──
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: _ActionButtons(state: state),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
          );
        },
      ),
    );
  }
}

// ── Yellow Header with Stacked Cards ─────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    // The cards are 230.h tall. We want ~half inside yellow, half outside.
    final cardStackHeight = 230.h;
    final cardOverlap = cardStackHeight * 0.6;
    // Yellow header height = appBar area + spacing + half the cards
    final yellowHeight = kToolbarHeight + MediaQuery.of(context).padding.top + 10.h + cardOverlap;

    return SizedBox(
      height: yellowHeight + cardOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Yellow background ──
          ClipPath(
            clipper: _WalletHeaderClipper(),
            child: Container(
              width: double.infinity,
              height: yellowHeight,
              color: AppColors.primary,
              child: Column(
                children: [
                  IqAppBar(title: AppStrings.walletBalance),
                ],
              ),
            ),
          ),
          // ── Stacked Cards (half in yellow, half outside) ──
          Positioned(
            top: yellowHeight - (cardOverlap / 1.3),
            left: 0,
            right: 0,
            child: SizedBox(
              height: cardStackHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back card
                  Positioned(
                    top: 0,
                    child: Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardColor = isDark
                            ? AppColors.darkCard.withValues(alpha: 0.95)
                            : AppColors.white.withValues(alpha: 0.95);
                        final shadowColor = AppColors.black.withValues(alpha: 0.1);
                        return Container(
                          width: 279.w,
                          height: 210.h,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                offset: const Offset(0, -5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Middle card
                  Positioned(
                    top: 16.h,
                    child: Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardColor = isDark
                            ? AppColors.darkCard.withValues(alpha: 0.95)
                            : AppColors.white.withValues(alpha: 0.95);
                        final shadowColor = AppColors.black.withValues(alpha: 0.1);
                        return Container(
                          width: 311.w,
                          height: 193.h,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                offset: const Offset(0, -5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Front card
                  Positioned(
                    top: 32.h,
                    child: Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardColor = isDark
                            ? AppColors.darkCard.withValues(alpha: 0.95)
                            : AppColors.white.withValues(alpha: 0.95);
                        final shadowColor = AppColors.black.withValues(alpha: 0.1);
                        return Container(
                          width: 343.w,
                          height: 193.h,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                offset: const Offset(0, -5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Payment method row
                  Positioned(
                    top: 54.h,
                    child: SizedBox(
                      width: 300.w,
                      child: Row(
                        children: [
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: const BoxDecoration(
                              color: AppColors.buttonYellow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.attach_money_rounded,
                              size: 30.w,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(width: 17.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IqText(
                                  AppStrings.cashPayment,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontSize: 17.sp,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                IqText(
                                  AppStrings.primaryPaymentMethod,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 17.sp,
                                    color: AppColors.walletSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Balance
                  Positioned(
                    top: 135.h,
                    child: Column(
                      children: [
                        IqText(
                          AppStrings.currentBalance,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.walletSubtitle,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        IqText(
                          state.formattedBalance,
                          style: AppTypography.heading1.copyWith(
                            fontSize: 40.sp,
                            fontFamily: AppTypography.fontFamilyLatin,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clips the bottom of the header with a smooth concave arc
/// matching the Figma design.
class _WalletHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Draw straight top and sides, then a smooth curve at the bottom
    path.lineTo(0, size.height - size.height * 0.18);
    path.quadraticBezierTo(
      size.width / 2, // control point x (center)
      size.height + size.height * 0.05, // control point y (below bottom)
      size.width, // end x
      size.height - size.height * 0.18, // end y
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Transactions Section ─────────────────────────────────────

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          AppStrings.recentTransactions,
          style: AppTypography.labelLarge,
        ),
        SizedBox(height: 15.h),
        if (state.transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
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
            (tx) => _TransactionItem(transaction: tx, state: state),
          ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.transaction,
    required this.state,
  });

  final WalletTransactionEntity transaction;
  final WalletState state;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final amount = transaction.amount.toStringAsFixed(0);
    final formattedAmount =
        amount.replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Row(
        children: [
          // Icon
          Icon(
            Icons.add,
            size: 25.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 12.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IqText(
                  transaction.remarks.isNotEmpty
                      ? transaction.remarks
                      : (isCredit
                          ? AppStrings.depositMadeByYou
                          : AppStrings.balanceWithdrawn),
                  style: AppTypography.labelLarge.copyWith(fontSize: 16.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                IqText(
                  '${state.currencyCode} $formattedAmount',
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.primary,
                    fontFamily: AppTypography.fontFamilyLatin,
                  ),
                ),
                SizedBox(height: 4.h),
                IqText(
                  _formatDate(transaction.createdAt),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.grayDate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = AppStrings.arabicMonths;
    return '${dt.day} ${months[dt.month - 1]} , ${dt.year}';
  }
}

// ── Action Buttons ───────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Deposit button (yellow)
        Expanded(
          child: SizedBox(
            height: 60.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                DepositBottomSheet.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
              ),
              child: IqText(
                AppStrings.depositAmount,
                style: AppTypography.button,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // Transfer button (black)
        Expanded(
          child: SizedBox(
            height: 60.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                TransferBottomSheet.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : AppColors.black,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
              ),
              child: IqText(
                AppStrings.transferMoney,
                style: AppTypography.button.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
