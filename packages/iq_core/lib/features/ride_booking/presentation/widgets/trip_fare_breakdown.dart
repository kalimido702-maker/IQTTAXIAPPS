import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';

/// Fare breakdown table shown in invoice screens.
class TripFareBreakdown extends StatelessWidget {
  const TripFareBreakdown({
    super.key,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    this.waitingCharge = 0,
    this.taxes = 0,
    this.promoDiscount = 0,
    this.tips = 0,
    required this.totalFare,
    this.currency = 'IQD',
    this.currencySymbol,
  });

  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double waitingCharge;
  final double taxes;
  final double promoDiscount;
  final double tips;
  final double totalFare;
  final String currency;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol ?? AppStrings.currencyIQD;
    return Column(
      children: [
        _FareRow(label: AppStrings.baseFare, amount: baseFare, symbol: sym),
        if (distanceFare > 0)
          _FareRow(label: AppStrings.distanceFare, amount: distanceFare, symbol: sym),
        if (timeFare > 0)
          _FareRow(label: AppStrings.timeFare, amount: timeFare, symbol: sym),
        if (waitingCharge > 0)
          _FareRow(label: AppStrings.waitingCharge, amount: waitingCharge, symbol: sym),
        if (taxes > 0)
          _FareRow(label: AppStrings.taxes, amount: taxes, symbol: sym),
        if (promoDiscount > 0)
          _FareRow(
            label: AppStrings.couponDiscount,
            amount: -promoDiscount,
            symbol: sym,
            isDiscount: true,
          ),
        if (tips > 0)
          _FareRow(label: AppStrings.tip, amount: tips, symbol: sym),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Divider(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkDivider
                : AppColors.grayBorder,
            height: 1,
          ),
        ),
        _FareRow(
          label: AppStrings.total,
          amount: totalFare,
          symbol: sym,
          isTotal: true,
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.amount,
    required this.symbol,
    this.isTotal = false,
    this.isDiscount = false,
  });

  final String label;
  final double amount;
  final String symbol;
  final bool isTotal;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textStyle = isTotal
        ? AppTypography.labelLarge.copyWith(color: onSurface)
        : AppTypography.bodyMedium.copyWith(color: AppColors.textSubtitle);
    final amountStyle = isTotal
        ? AppTypography.numberLarge.copyWith(color: AppColors.primary)
        : AppTypography.numberMedium.copyWith(
            color: isDiscount ? AppColors.success : onSurface,
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IqText(label, style: textStyle),
          IqText(
            '${amount.toStringAsFixed(0)} $symbol',
            style: amountStyle,
            dir: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
