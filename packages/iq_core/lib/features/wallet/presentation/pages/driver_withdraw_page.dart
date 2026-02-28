import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/wallet_bloc.dart';

/// Driver Withdraw Page — سحب الرصيد
///
/// Shows balance card, amount input, empty state illustration,
/// and cancel & withdraw buttons.
class DriverWithdrawPage extends StatefulWidget {
  const DriverWithdrawPage({super.key});

  @override
  State<DriverWithdrawPage> createState() => _DriverWithdrawPageState();
}

class _DriverWithdrawPageState extends State<DriverWithdrawPage> {
  final _controller = TextEditingController(text: '0');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onWithdrawPressed() {
    final amount = double.tryParse(_controller.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.enterValidAmount),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final state = context.read<WalletBloc>().state;
    if (amount > state.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.insufficientBalance),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // For withdraw, we reuse the add money endpoint or a dedicated one
    // if available. For now we use deposit with negative indication.
    context.read<WalletBloc>().add(WalletDepositRequested(amount: amount));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const IqAppBar(title: AppStrings.withdrawBalance),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),

                // ── Balance Card ──
                Container(
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
                ),
                SizedBox(height: 30.h),

                // ── Amount Input ──
                IqText(
                  AppStrings.enterWithdrawAmount,
                  style: AppTypography.heading3.copyWith(
                    color: onSurface,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 15.h),

                Container(
                  height: 75.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textAlign: TextAlign.center,
                      style: AppTypography.numberLarge.copyWith(
                        fontFamily: AppTypography.fontFamilyLatin,
                        fontWeight: FontWeight.w500,
                        fontSize: 24.sp,
                        color: onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        suffixText: ' IQD',
                        suffixStyle: AppTypography.numberLarge.copyWith(
                          fontFamily: AppTypography.fontFamilyLatin,
                          fontWeight: FontWeight.w500,
                          fontSize: 24.sp,
                          color: onSurface,
                        ),
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8.h),

                // Update payment method link
                GestureDetector(
                  onTap: () {
                    // TODO: navigate to payment method settings
                  },
                  child: IqText(
                    AppStrings.updatePaymentMethod,
                    style: AppTypography.bodyLarge.copyWith(
                      color: onSurface,
                      fontSize: 16.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),

                // ── Empty State ──
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80.w,
                          color: AppColors.gray1,
                        ),
                        SizedBox(height: 10.h),
                        IqText(
                          '${AppStrings.noPaymentHistory}\n${AppStrings.startYourTrip}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Action Buttons ──
                Row(
                  children: [
                    // Cancel
                    SizedBox(
                      width: 130.w,
                      height: 60.h,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkCard : AppColors.black,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1000.r),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 40.w),
                        ),
                        child: IqText(
                          AppStrings.cancel,
                          style: AppTypography.button
                              .copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Withdraw
                    Expanded(
                      child: SizedBox(
                        height: 60.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _onWithdrawPressed();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonYellow,
                            foregroundColor: AppColors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(1000.r),
                            ),
                          ),
                          icon:
                              Icon(Icons.north_east, size: 24.w),
                          label: IqText(
                            AppStrings.requestWithdraw,
                            style: AppTypography.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
