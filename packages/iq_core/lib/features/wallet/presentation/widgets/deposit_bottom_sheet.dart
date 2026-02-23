import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/wallet_bloc.dart';

/// Bottom sheet for depositing money — إيداع أموال
///
/// Shows amount input, quick-select chips, cancel & add buttons.
class DepositBottomSheet extends StatefulWidget {
  const DepositBottomSheet({super.key});

  /// Show the deposit bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<WalletBloc>(),
        child: const DepositBottomSheet(),
      ),
    );
  }

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  final _controller = TextEditingController(text: '100.00');
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
      _controller.text = _quickAmounts[index].toStringAsFixed(2);
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          IqText(
            AppStrings.depositMoney,
            style: AppTypography.heading2,
          ),
          SizedBox(height: 15.h),

          // Amount input
          Container(
            height: 55.h,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.chipBorder),
              borderRadius: BorderRadius.circular(50.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                IqText(
                  'IQD',
                  style: AppTypography.labelLarge.copyWith(
                    fontFamily: AppTypography.fontFamilyLatin,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonYellow,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.end,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.numberMedium.copyWith(
                      fontSize: 16.sp,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) {
                      if (_selectedChipIndex != null) {
                        setState(() => _selectedChipIndex = null);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),

          // Quick amount chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_quickAmounts.length, (index) {
              final isSelected = _selectedChipIndex == index;
              final amount = _quickAmounts[index];
              final formatted = amount >= 1000
                  ? 'IQD ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
                  : 'IQD $amount';

              return Padding(
                padding: EdgeInsets.only(
                    left: index < _quickAmounts.length - 1 ? 12.w : 0),
                child: GestureDetector(
                  onTap: () => _selectChip(index),
                  child: Container(
                    height: 33.h,
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.buttonYellow
                          : AppColors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.buttonYellow
                            : AppColors.chipBorder,
                      ),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    alignment: Alignment.center,
                    child: IqText(
                      formatted,
                      style: AppTypography.labelSmall.copyWith(
                        fontFamily: AppTypography.fontFamilyLatin,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                        fontSize: 14.sp,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 34.h),

          // Action buttons
          Row(
            children: [
              // Add amount button
              Expanded(
                child: SizedBox(
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _onAddPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonYellow,
                      foregroundColor: AppColors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    child: IqText(
                      AppStrings.addAmount,
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Cancel button
              SizedBox(
                width: 156.w,
                height: 55.h,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.cancelRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  child: IqText(
                    AppStrings.cancel,
                    style: AppTypography.button.copyWith(
                      color: AppColors.cancelRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
