import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../wallet/presentation/pages/payment_web_view_page.dart';
import '../../../data/datasources/trip_stream_data_source.dart';
import '../../../data/models/invoice_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../widgets/driver_info_card.dart';
import '../../widgets/trip_address_row.dart';
import '../../widgets/trip_fare_breakdown.dart';
import '../../widgets/trip_info_row.dart';
import 'trip_rating_page.dart';

/// Trip invoice / summary page (Figma 7:894).
/// Shows fare breakdown, driver info, payment method.
class TripInvoicePage extends StatefulWidget {
  const TripInvoicePage({
    super.key,
    required this.requestId,
    this.isDriver = false,
  });

  final String requestId;
  final bool isDriver;

  @override
  State<TripInvoicePage> createState() => _TripInvoicePageState();
}

class _TripInvoicePageState extends State<TripInvoicePage> {
  InvoiceModel? _invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final repo = sl<BookingRepository>();
    final result = await repo.getTripInvoice(requestId: widget.requestId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (invoice) => setState(() {
        _invoice = invoice;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _error != null
                  ? Center(
                      child: IqText(
                        _error!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    )
                  : _InvoiceContent(
                      invoice: _invoice!,
                      requestId: widget.requestId,
                      isDriver: widget.isDriver,
                    ),
        ),
      ),
    );
  }
}

class _InvoiceContent extends StatefulWidget {
  const _InvoiceContent({
    required this.invoice,
    required this.requestId,
    required this.isDriver,
  });

  final InvoiceModel invoice;
  final String requestId;
  final bool isDriver;

  @override
  State<_InvoiceContent> createState() => _InvoiceContentState();
}

class _InvoiceContentState extends State<_InvoiceContent> {
  bool _processingPayment = false;

  Future<void> _handleOnlinePayment() async {
    setState(() => _processingPayment = true);

    final repo = sl<BookingRepository>();
    final result = await repo.createRidePayment(
      requestId: widget.requestId,
      amount: widget.invoice.totalFare,
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (paymentUrl) async {
        setState(() => _processingPayment = false);

        final paymentResult = await Navigator.of(context).push<PaymentResult>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewPage(paymentUrl: paymentUrl),
          ),
        );

        if (!mounted) return;

        if (paymentResult == PaymentResult.success) {
          // Mark as paid in Firebase so both sides see the update
          sl<TripStreamDataSource>().updateTripNode(
            requestId: widget.requestId,
            data: {'is_paid': 1, 'is_user_paid': true},
          );
          // Confirm payment on backend then navigate to rating
          repo.confirmPayment(requestId: widget.requestId);
          _navigateToRating();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.paymentFailed),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  void _navigateToRating() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TripRatingPage(
          requestId: widget.requestId,
          otherPersonName: widget.invoice.driverName ?? '',
          otherPersonPhoto: widget.invoice.driverImage,
          isDriver: widget.isDriver,
        ),
      ),
    );
  }

  void _onActionPressed() {
    HapticFeedback.mediumImpact();

    if (widget.isDriver) {
      // Driver confirms payment → go to rating
      sl<BookingRepository>().confirmPayment(requestId: widget.requestId);
      _navigateToRating();
      return;
    }

    // Passenger: check if online payment is needed (code 0 = online/card)
    if (widget.invoice.paymentMethod == 0 && !widget.invoice.isPaid) {
      _handleOnlinePayment();
    } else {
      _navigateToRating();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLG,
        vertical: AppDimens.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Header
          Center(
            child: IqText(
              AppStrings.tripSummary,
              style: AppTypography.heading2.copyWith(color: onSurface),
            ),
          ),
          SizedBox(height: 24.h),

          // Driver/User info
          if (widget.invoice.driverName != null)
            DriverInfoCard(
              name: widget.invoice.driverName!,
              photoUrl: widget.invoice.driverImage,
              rating: 0,
              carModel: null,
              showActions: false,
            ),
          SizedBox(height: 20.h),

          // Trip info row
          TripInfoRow(
            duration: '${widget.invoice.duration} ${AppStrings.minute}',
            distance:
                '${widget.invoice.distance.toStringAsFixed(2)} ${AppStrings.km}',
            rideType: AppStrings.regular,
          ),
          SizedBox(height: 20.h),

          // Addresses
          TripAddressRow(
            pickAddress: widget.invoice.pickAddress,
            dropAddress: widget.invoice.dropAddress,
          ),
          SizedBox(height: 20.h),

          // Divider
          Divider(color: isDark ? AppColors.darkDivider : AppColors.grayBorder),
          SizedBox(height: 12.h),

          // Fare breakdown
          TripFareBreakdown(
            baseFare: widget.invoice.baseFare,
            distanceFare: widget.invoice.distanceFare,
            timeFare: widget.invoice.timeFare,
            waitingCharge: widget.invoice.waitingCharge,
            taxes: widget.invoice.taxes,
            promoDiscount: widget.invoice.promoDiscount,
            tips: widget.invoice.tips,
            totalFare: widget.invoice.totalFare,
            currency: widget.invoice.currency,
            currencySymbol: widget.invoice.currencySymbol,
          ),
          SizedBox(height: 20.h),

          // Payment method
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputBg : AppColors.grayLightBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 22.w,
                  color: onSurface,
                ),
                SizedBox(width: 10.w),
                IqText(
                  widget.invoice.paymentMethodName,
                  style: AppTypography.labelMedium.copyWith(
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Action button
          IqPrimaryButton(
            text: widget.isDriver
                ? AppStrings.paymentReceived
                : (widget.invoice.paymentMethod == 0 && !widget.invoice.isPaid)
                    ? AppStrings.payNow
                    : AppStrings.choosePay,
            isLoading: _processingPayment,
            onPressed: _processingPayment ? null : _onActionPressed,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
