import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/wallet_bloc.dart';

/// Bottom sheet for transferring money — تحويل أموال
///
/// Shows user type dropdown, amount field, phone field,
/// cancel & transfer buttons.
class TransferBottomSheet extends StatefulWidget {
  const TransferBottomSheet({super.key});

  /// Show the transfer bottom sheet.
  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<WalletBloc>(),
        child: const TransferBottomSheet(),
      ),
    );
  }

  @override
  State<TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<TransferBottomSheet> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'driver'; // 'driver' or 'user'

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onTransferPressed() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.enterValidAmount),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.enterValidPhone),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<WalletBloc>().add(WalletTransferRequested(
          amount: amount,
          mobile: phone,
          role: _selectedRole,
          countryCode: '+964',
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            AppStrings.transferMoney,
            style: AppTypography.heading2,
          ),
          SizedBox(height: 15.h),

          // ── User Type ──
          IqText(
            AppStrings.userType,
            style: AppTypography.labelLarge.copyWith(
              color: onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Row(
              children: [
                // Role dropdown
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isDense: true,
                    style: AppTypography.labelLarge.copyWith(
                      color: onSurface,
                    ),
                    icon: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: 'driver',
                        child: IqText(
                          AppStrings.driver,
                          style: AppTypography.labelLarge.copyWith(
                            color: onSurface,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: IqText(
                          AppStrings.user,
                          style: AppTypography.labelLarge.copyWith(
                            color: onSurface,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
                ),
                const Spacer(),
                // Dropdown icon
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24.w,
                  color: onSurface,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Amount ──
          IqText(
            AppStrings.theAmount,
            style: AppTypography.labelLarge.copyWith(
              color: onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 52.h,
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 4.h),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: AppStrings.enterValueAboveZero,
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.grayLight,
                ),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
          ),
          SizedBox(height: 15.h),

          // ── Phone Number ──
          IqText(
            AppStrings.mobileNumber,
            style: AppTypography.labelLarge.copyWith(
              color: onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  // Iraq flag placeholder
                  Container(
                  width: 30.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(color: AppColors.iraqFlagRed),
                        ),
                        Expanded(
                          child: Container(color: AppColors.white),
                        ),
                        Expanded(
                          child: Container(color: AppColors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IqText(
                  '+964 |',
                  style: AppTypography.numberMedium.copyWith(
                    fontFamily: AppTypography.fontFamilyLatin,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    style: AppTypography.numberMedium.copyWith(
                      fontFamily: AppTypography.fontFamilyLatin,
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      errorBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '123 456 7899',
                      hintStyle: AppTypography.numberMedium.copyWith(
                        fontFamily: AppTypography.fontFamilyLatin,
                        fontSize: 16.sp,
                        color: AppColors.grayLight,
                      ),
                      isDense: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
          SizedBox(height: 34.h),

          // Action buttons
          Row(
            children: [
              // Cancel
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
              SizedBox(width: 14.w),
              // Transfer
              Expanded(
                child: SizedBox(
                  height: 55.h,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _onTransferPressed();
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
                      AppStrings.transferMoney,
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ),
            ].reversed.toList(),
          ),
        ],
      ),
    );
  }
}
