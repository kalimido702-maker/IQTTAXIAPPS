import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../ride_booking/presentation/widgets/ride_bottom_sheets.dart';
import '../../data/models/parcel_request_model.dart';
import '../bloc/package_delivery_bloc.dart';
import '../bloc/package_delivery_event.dart';
import '../bloc/package_delivery_state.dart';
import 'select_goods_type_page.dart';

/// Screen 4 — Booking confirmation for package delivery.
///
/// Matches Figma node 7:4202.
class ParcelBookingPage extends StatelessWidget {
  const ParcelBookingPage({
    super.key,
    required this.onRequestCreated,
  });

  final void Function(String requestId) onRequestCreated;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
          listenWhen: (prev, curr) =>
              curr.status == PackageDeliveryStatus.requestCreated &&
              curr.requestId != null,
          listener: (_, state) => onRequestCreated(state.requestId!),
        ),
        BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
          listenWhen: (prev, curr) =>
              curr.status == PackageDeliveryStatus.error &&
              curr.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: IqText(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          },
        ),
        BlocListener<PackageDeliveryBloc, PackageDeliveryState>(
          listenWhen: (prev, curr) =>
              curr.status == PackageDeliveryStatus.promoApplied,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: IqText(AppStrings.promoApplied),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<PackageDeliveryBloc, PackageDeliveryState>(
        builder: (context, state) {
          // Dynamic title based on send/receive mode
          final title = state.parcelRequest.parcelType == ParcelType.receive
              ? AppStrings.receiveParcels
              : AppStrings.sendParcels;

          return Scaffold(
            appBar: IqAppBar(title: title),
            body: state.status == PackageDeliveryStatus.loadingBooking
                ? const Center(child: CircularProgressIndicator())
                : _BookingBody(state: state),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Main body
// ═══════════════════════════════════════════════════════════════════

class _BookingBody extends StatelessWidget {
  const _BookingBody({required this.state});
  final PackageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    final req = state.parcelRequest;
    final vehicle = state.selectedVehicle;
    final fare = vehicle?.total ?? req.requestEtaAmount ?? 0;
    final currency = vehicle?.currencySymbol ?? 'IQD';
    final formatter = NumberFormat('#,###');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Address pills ──
                _AddressPill(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFF34A853),
                  text: req.pickAddress.isNotEmpty
                      ? req.pickAddress
                      : AppStrings.pickupAddress,
                ),
                SizedBox(height: 10.h),
                _AddressPill(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFEA4335),
                  text: req.dropAddress.isNotEmpty
                      ? req.dropAddress
                      : AppStrings.deliveryAddress,
                ),

                SizedBox(height: 24.h),

                // ── Service type ──
                IqText(
                  AppStrings.serviceType,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                _ServiceTypeCard(),

                SizedBox(height: 20.h),

                // ── Promo code ──
                BlocBuilder<PackageDeliveryBloc, PackageDeliveryState>(
                  buildWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.parcelRequest.promoCode !=
                          curr.parcelRequest.promoCode,
                  builder: (context, promoState) {
                    return _PromoCodeRow(
                      promoCode: promoState.parcelRequest.promoCode,
                      isValidating: promoState.status ==
                          PackageDeliveryStatus.validatingPromo,
                    );
                  },
                ),

                SizedBox(height: 20.h),

                // ── Amount due ──
                _AmountDueRow(
                  currency: currency,
                  fare: fare,
                  formatter: formatter,
                ),

                SizedBox(height: 24.h),

                // ── Goods type ──
                IqText(
                  AppStrings.parcelType,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                _GoodsTypeSelector(
                  goodsTypeName: req.goodsTypeName,
                  onTap: () => _openGoodsTypePicker(context),
                ),

                SizedBox(height: 24.h),

                // ── Who pays ──
                IqText(
                  AppStrings.whoPays,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                _WhoPaysRadio(paidBy: req.paidBy),

                SizedBox(height: 24.h),

                // ── Payment method ──
                _PaymentMethodRow(
                  paymentOpt: req.paymentOpt,
                  allowedMethods:
                      state.selectedVehicle?.paymentTypes ?? const {},
                ),
              ],
            ),
          ),
        ),

        // ── Book now ──
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
            child: BlocBuilder<PackageDeliveryBloc, PackageDeliveryState>(
              builder: (context, s) {
                return IqPrimaryButton(
                  text: AppStrings.rideNow,
                  isLoading:
                      s.status == PackageDeliveryStatus.creatingRequest,
                  onPressed: () {
                    context
                        .read<PackageDeliveryBloc>()
                        .add(const PackageDeliveryCreateRequested());
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openGoodsTypePicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PackageDeliveryBloc>(),
          child: SelectGoodsTypePage(
            onConfirmed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Address pill — matches parcel_address_page style
// ═══════════════════════════════════════════════════════════════════

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.grayInactive.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22.w),
          SizedBox(width: 12.w),
          Expanded(
            child: IqText(
              text,
              style: AppTypography.bodyLarge,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Service type card — gray background with icon + text + arrow
// ═══════════════════════════════════════════════════════════════════

class _ServiceTypeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                size: 22.w,
                color: AppColors.black,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: IqText(
                  AppStrings.delegateDelivery,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: AppColors.grayLight,
              ),
            ],
          ),
        ),
        SizedBox(height: 15.h),
        Center(
          child: IqText(
            AppStrings.freeLoadingTime,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.gray3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Promo code — pill-shaped with arrow
// ═══════════════════════════════════════════════════════════════════

class _PromoCodeRow extends StatelessWidget {
  const _PromoCodeRow({this.promoCode, this.isValidating = false});
  final String? promoCode;
  final bool isValidating;

  @override
  Widget build(BuildContext context) {
    final hasPromo = promoCode != null && promoCode!.isNotEmpty;

    return InkWell(
      onTap: isValidating ? null : () => _showPromoDialog(context),
      borderRadius: BorderRadius.circular(1000.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: IqText(
                hasPromo ? promoCode! : AppStrings.promoCode,
                style: AppTypography.bodyLarge.copyWith(
                  color: hasPromo ? AppColors.success : AppColors.black,
                ),
              ),
            ),
            if (isValidating)
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                hasPromo ? Icons.close : Icons.arrow_forward_ios,
                size: 16.w,
                color: AppColors.grayLight,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPromoDialog(BuildContext context) async {
    final controller = TextEditingController(text: promoCode);
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: IqText(AppStrings.promoCode, style: AppTypography.heading3),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: AppStrings.enterPromoCode,
            hintStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.grayInactive,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: IqText(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(controller.text.trim()),
            child: IqText(
              AppStrings.apply,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      context.read<PackageDeliveryBloc>().add(
            PackageDeliveryPromoApplied(result.isEmpty ? null : result),
          );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Amount due — label on right, value on left
// ═══════════════════════════════════════════════════════════════════

class _AmountDueRow extends StatelessWidget {
  const _AmountDueRow({
    required this.currency,
    required this.fare,
    required this.formatter,
  });

  final String currency;
  final num fare;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IqText(
          AppStrings.amountDue,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IqText(
          '$currency ${formatter.format(fare)}',
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Goods type — yellow-bordered dropdown
// ═══════════════════════════════════════════════════════════════════

class _GoodsTypeSelector extends StatelessWidget {
  const _GoodsTypeSelector({
    required this.goodsTypeName,
    required this.onTap,
  });

  final String goodsTypeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = goodsTypeName.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: IqText(
                hasValue ? goodsTypeName : AppStrings.selectGoodsType,
                style: AppTypography.bodyLarge.copyWith(
                  color: hasValue ? AppColors.black : AppColors.grayLight,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22.w,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Who pays — checkbox-style radio buttons
// ═══════════════════════════════════════════════════════════════════

class _WhoPaysRadio extends StatelessWidget {
  const _WhoPaysRadio({required this.paidBy});
  final PaidBy paidBy;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaidByCheckbox(
          label: AppStrings.theSender,
          isSelected: paidBy == PaidBy.sender,
          onTap: () => context
              .read<PackageDeliveryBloc>()
              .add(const PackageDeliveryPaidByChanged(PaidBy.sender)),
        ),
        SizedBox(height: 10.h),
        _PaidByCheckbox(
          label: AppStrings.theReceiver,
          isSelected: paidBy == PaidBy.receiver,
          onTap: () => context
              .read<PackageDeliveryBloc>()
              .add(const PackageDeliveryPaidByChanged(PaidBy.receiver)),
        ),
      ],
    );
  }
}

class _PaidByCheckbox extends StatelessWidget {
  const _PaidByCheckbox({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grayLight,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: 16.w,
                    color: AppColors.white,
                  )
                : null,
          ),
          SizedBox(width: 10.w),
          IqText(
            label,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Payment method — bordered card with icon, label, subtitle, arrow
// ═══════════════════════════════════════════════════════════════════

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.paymentOpt,
    required this.allowedMethods,
  });
  final int paymentOpt;
  final Map<String, bool> allowedMethods;

  String get _paymentLabel {
    switch (paymentOpt) {
      case 1:
        return AppStrings.cash;
      case 2:
        return AppStrings.walletPayment;
      case 0:
        return AppStrings.cardPayment;
      case 3:
        return AppStrings.onlinePayment;
      default:
        return AppStrings.cash;
    }
  }

  IconData get _paymentIcon {
    switch (paymentOpt) {
      case 1:
        return Icons.money;
      case 2:
        return Icons.account_balance_wallet_outlined;
      case 0:
        return Icons.credit_card;
      case 3:
        return Icons.language;
      default:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPaymentPicker(context),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.grayInactive.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(_paymentIcon, size: 24.w, color: AppColors.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IqText(
                    _paymentLabel,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  IqText(
                    AppStrings.changePaymentMethod,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grayLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.w,
              color: AppColors.grayLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentPicker(BuildContext context) async {
    final result = await showPaymentMethodSheet(
      context,
      currentPayment: paymentOpt,
      allowedMethods: allowedMethods,
    );
    if (result != null && context.mounted) {
      context
          .read<PackageDeliveryBloc>()
          .add(PackageDeliveryPaymentChanged(result));
    }
  }
}
