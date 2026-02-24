import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    this.currencySymbol = 'د.ع',
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
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FareRow(label: 'أجرة البداية', amount: baseFare, symbol: currencySymbol),
        if (distanceFare > 0)
          _FareRow(label: 'أجرة المسافة', amount: distanceFare, symbol: currencySymbol),
        if (timeFare > 0)
          _FareRow(label: 'أجرة الوقت', amount: timeFare, symbol: currencySymbol),
        if (waitingCharge > 0)
          _FareRow(label: 'رسوم الانتظار', amount: waitingCharge, symbol: currencySymbol),
        if (taxes > 0)
          _FareRow(label: 'الضرائب', amount: taxes, symbol: currencySymbol),
        if (promoDiscount > 0)
          _FareRow(
            label: 'خصم الكوبون',
            amount: -promoDiscount,
            symbol: currencySymbol,
            isDiscount: true,
          ),
        if (tips > 0)
          _FareRow(label: 'إكرامية', amount: tips, symbol: currencySymbol),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Divider(color: AppColors.grayBorder, height: 1),
        ),
        _FareRow(
          label: 'الإجمالي',
          amount: totalFare,
          symbol: currencySymbol,
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
    final textStyle = isTotal
        ? AppTypography.labelLarge.copyWith(color: AppColors.textDark)
        : AppTypography.bodyMedium.copyWith(color: AppColors.textSubtitle);
    final amountStyle = isTotal
        ? AppTypography.numberLarge.copyWith(color: AppColors.primary)
        : AppTypography.numberMedium.copyWith(
            color: isDiscount ? AppColors.success : AppColors.textDark,
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
