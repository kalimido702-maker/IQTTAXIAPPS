import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
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
        backgroundColor: AppColors.white,
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

class _InvoiceContent extends StatelessWidget {
  const _InvoiceContent({
    required this.invoice,
    required this.requestId,
    required this.isDriver,
  });

  final InvoiceModel invoice;
  final String requestId;
  final bool isDriver;

  @override
  Widget build(BuildContext context) {
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
              'ملخص الرحلة',
              style: AppTypography.heading2.copyWith(color: AppColors.textDark),
            ),
          ),
          SizedBox(height: 24.h),

          // Driver/User info
          if (invoice.driverName != null)
            DriverInfoCard(
              name: invoice.driverName!,
              photoUrl: invoice.driverImage,
              rating: 0,
              carModel: null,
              showActions: false,
            ),
          SizedBox(height: 20.h),

          // Trip info row
          TripInfoRow(
            duration: '${invoice.duration} دقيقة',
            distance: '${invoice.distance.toStringAsFixed(2)} كم',
            rideType: 'عادي',
          ),
          SizedBox(height: 20.h),

          // Addresses
          TripAddressRow(
            pickAddress: invoice.pickAddress,
            dropAddress: invoice.dropAddress,
          ),
          SizedBox(height: 20.h),

          // Divider
          Divider(color: AppColors.grayBorder),
          SizedBox(height: 12.h),

          // Fare breakdown
          TripFareBreakdown(
            baseFare: invoice.baseFare,
            distanceFare: invoice.distanceFare,
            timeFare: invoice.timeFare,
            waitingCharge: invoice.waitingCharge,
            taxes: invoice.taxes,
            promoDiscount: invoice.promoDiscount,
            tips: invoice.tips,
            totalFare: invoice.totalFare,
            currency: invoice.currency,
            currencySymbol: invoice.currencySymbol,
          ),
          SizedBox(height: 20.h),

          // Payment method
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.grayLightBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 22.w,
                  color: AppColors.textDark,
                ),
                SizedBox(width: 10.w),
                IqText(
                  invoice.paymentMethodName,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Action button
          IqPrimaryButton(
            text: isDriver ? 'تم استلام الدفع' : 'اختر الدفع',
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (isDriver) {
                // Driver confirms payment → go to rating
                sl<BookingRepository>().confirmPayment(requestId: requestId);
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TripRatingPage(
                    requestId: requestId,
                    otherPersonName: invoice.driverName ?? '',
                    otherPersonPhoto: invoice.driverImage,
                    isDriver: isDriver,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
