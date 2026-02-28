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

/// Driver Add Balance Page — إضافة رصيد
///
/// Shows amount input, quick chips, cancel & add buttons.
class DriverAddBalancePage extends StatefulWidget {
  const DriverAddBalancePage({super.key});

  @override
  State<DriverAddBalancePage> createState() => _DriverAddBalancePageState();
}

class _DriverAddBalancePageState extends State<DriverAddBalancePage> {
  final _controller = TextEditingController(text: '0');
  int? _selectedChipIndex;

  static const _quickAmounts = [5000, 10000, 15000];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectChip(int index) {
    setState(() {
      _selectedChipIndex = index;
      _controller.text = _quickAmounts[index].toString();
    });
  }

  void _onAddPressed() {
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

    context.read<WalletBloc>().add(WalletDepositRequested(amount: amount));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const IqAppBar(title: AppStrings.addBalance),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // Label
            IqText(
              AppStrings.enterAmount,
              style: AppTypography.heading3.copyWith(
                color: onSurface,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 15.h),

            // Amount input
            Container(
              height: 75.h,
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) {
                    if (_selectedChipIndex != null) {
                      setState(() => _selectedChipIndex = null);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 15.h),

            // Quick amount chips
            Wrap(
              spacing: 5.w,
              children: List.generate(_quickAmounts.length, (index) {
                final isSelected = _selectedChipIndex == index;
                final amount = _quickAmounts[index];
                final formatted = 'IQD ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

                return GestureDetector(
                  onTap: () => _selectChip(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.buttonYellow
                          : isDark ? AppColors.darkCard : AppColors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.buttonYellow
                            : isDark ? AppColors.darkDivider : AppColors.black,
                      ),
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    child: IqText(
                      formatted,
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 16.sp,
                        color: isSelected
                            ? AppColors.black
                            : onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Action buttons
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
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                    ),
                    child: IqText(
                      AppStrings.cancel,
                      style: AppTypography.button
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Add balance
                Expanded(
                  child: SizedBox(
                    height: 60.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _onAddPressed();
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
                        AppStrings.addTheBalance,
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
      ),
    );
  }
}
