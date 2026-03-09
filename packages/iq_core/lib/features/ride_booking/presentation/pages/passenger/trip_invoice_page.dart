import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/iq_image.dart';
import '../../../../../core/widgets/iq_primary_button.dart';
import '../../../../../core/widgets/iq_text.dart';
import '../../../../wallet/presentation/pages/payment_web_view_page.dart';
import '../../../data/datasources/trip_stream_data_source.dart';
import '../../../data/models/active_trip_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../widgets/trip_fare_breakdown.dart';
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

  /// Real-time payment confirmation from Firebase.
  late bool _isPaid = widget.invoice.isPaid;
  StreamSubscription<ActiveTripModel?>? _paymentSub;

  @override
  void initState() {
    super.initState();
    // For passengers with cash/wallet trips that aren't yet paid,
    // listen to Firebase for real-time payment confirmation from driver.
    if (!widget.isDriver && !_isPaid) {
      _paymentSub = sl<TripStreamDataSource>()
          .watchTrip(widget.requestId)
          .listen((trip) {
        if (trip != null && trip.isPaid && mounted) {
          setState(() => _isPaid = true);
          _paymentSub?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    super.dispose();
  }

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
    // When driver views: show passenger info. When passenger views: show driver info.
    final otherName = widget.isDriver
        ? (widget.invoice.userName ?? '')
        : (widget.invoice.driverName ?? '');
    final otherPhoto = widget.isDriver
        ? widget.invoice.userImage
        : widget.invoice.driverImage;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TripRatingPage(
          requestId: widget.requestId,
          otherPersonName: otherName,
          otherPersonPhoto: otherPhoto,
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

    // Passenger: block navigation until driver confirms payment
    if (!_isPaid) {
      if (widget.invoice.paymentMethod == 0) {
        // Online payment flow
        _handleOnlinePayment();
        return;
      }
      // Cash/wallet: show waiting message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.waitingDriverPaymentConfirm),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    _navigateToRating();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardBorder = isDark ? AppColors.darkDivider : AppColors.grayBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.white;

    // When driver views: show passenger info. When passenger views: show driver info.
    final otherPersonName = widget.isDriver
        ? (widget.invoice.userName ?? '')
        : (widget.invoice.driverName ?? '');
    final otherPersonImage = widget.isDriver
        ? widget.invoice.userImage
        : widget.invoice.driverImage;
    final otherPersonRating = widget.isDriver
        ? (widget.invoice.userRating ?? '0.0')
        : (widget.invoice.driverRating ?? '0.0');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLG,
        vertical: AppDimens.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back + Title ──
          Row(
            children: [
              GestureDetector(
                onTap: () => _onActionPressed(),
                child: Icon(Icons.arrow_back, size: 24.w, color: onSurface),
              ),
              const Spacer(),
              IqText(
                AppStrings.tripSummary,
                style: AppTypography.heading2.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SizedBox(width: 24.w), // balance
            ],
          ),
          SizedBox(height: 24.h),

          // ── Driver Card (bordered) ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              // border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    ClipOval(
                      child: SizedBox(
                        width: 64.w,
                        height: 64.w,
                        child: otherPersonImage != null &&
                                otherPersonImage.isNotEmpty
                            ? IqImage(
                                otherPersonImage,
                                fit: BoxFit.cover,
                                width: 64.w,
                                height: 64.w,
                              )
                            : Container(
                                color: AppColors.grayLightBg,
                                child: Icon(Icons.person,
                                    size: 36.w, color: AppColors.grayLight),
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Name + rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: IqText(
                                  otherPersonName,
                                  style: AppTypography.heading3.copyWith(
                                    color: onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.star_rounded,
                                  size: 16.w, color: AppColors.starFilled),
                              SizedBox(width: 2.w),
                              IqText(
                                otherPersonRating,
                                style: AppTypography.numberSmall.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                dir: TextDirection.ltr,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Vehicle info row
                          Row(
                            children: [
                              if (widget.invoice.vehicleMake != null) ...[
                                IqText(
                                  widget.invoice.vehicleMake!,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                              ],
                              if (widget.invoice.vehicleNumber != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkInputBg
                                        : AppColors.grayLightBg,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: IqText(
                                    widget.invoice.vehicleNumber!,
                                    style: AppTypography.numberSmall.copyWith(
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.sp,
                                    ),
                                    dir: TextDirection.ltr,
                                  ),
                                ),
                              if (widget.invoice.vehicleColor != null) ...[
                                SizedBox(width: 6.w),
                                IqText(
                                  'Color:',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Container(
                                  width: 14.w,
                                  height: 14.w,
                                  decoration: BoxDecoration(
                                    color: _parseColor(
                                        widget.invoice.vehicleColor!),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.grayBorder,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Type badge + request number
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IqText(
                              widget.invoice.isDelivery
                                  ? AppStrings.packageDelivery
                                  : AppStrings.taxi,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              widget.invoice.isDelivery
                                  ? Icons.local_shipping_rounded
                                  : Icons.local_taxi_rounded,
                              size: 16.w,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        IqText(
                          AppStrings.orderNumber,
                          style: AppTypography.caption.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IqText(
                          widget.invoice.requestNumber,
                          style: AppTypography.numberSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          dir: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Trip Info Section Header ──
          IqText(
            AppStrings.tripInfo,
            style: AppTypography.heading3.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),

          // ── Trip Info Card (bordered yellow-ish) ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Duration + Distance (hide if both are zero — typical for delivery)
                if (widget.invoice.duration > 0 || widget.invoice.distance > 0)
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 18.w, color: AppColors.textMuted),
                            SizedBox(width: 6.w),
                            IqText(
                              '${AppStrings.duration} : ',
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IqText(
                              '${widget.invoice.duration.toStringAsFixed(0)} ${AppStrings.minute}',
                              style: AppTypography.labelMedium.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24.h,
                        color: cardBorder,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten_rounded,
                                size: 18.w, color: AppColors.textMuted),
                            SizedBox(width: 6.w),
                            IqText(
                              '${AppStrings.distance} : ',
                              style: AppTypography.bodySmall.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IqText(
                              '${widget.invoice.distance.toStringAsFixed(2)} ${AppStrings.km}',
                              style: AppTypography.labelMedium.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (widget.invoice.duration > 0 || widget.invoice.distance > 0)
                  SizedBox(height: 10.h),
                // Ride type
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.invoice.isDelivery
                          ? Icons.local_shipping_rounded
                          : Icons.local_taxi_rounded,
                      size: 18.w,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    IqText(
                      '${AppStrings.tripType} : ',
                      style: AppTypography.bodySmall.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IqText(
                      widget.invoice.isDelivery
                          ? AppStrings.packageDelivery
                          : (widget.invoice.rideType ?? AppStrings.regular),
                      style: AppTypography.labelMedium.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Addresses Section Header ──
          IqText(
            AppStrings.tripAddresses,
            style: AppTypography.heading3.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),

          // ── Pickup Address ──
          _InvoiceAddressCard(
            address: widget.invoice.pickAddress,
            iconColor: AppColors.markerGreen,
          ),
          SizedBox(height: 8.h),

          // ── Drop Address ──
          _InvoiceAddressCard(
            address: widget.invoice.dropAddress,
            iconColor: AppColors.markerRed,
          ),
          SizedBox(height: 20.h),

          // ── Fare Details Section Header ──
          IqText(
            AppStrings.fareDetails,
            style: AppTypography.heading3.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),

          // ── Fare Breakdown ──
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
          SizedBox(height: 24.h),

          // ── Payment method with change option ──
          Center(
            child: Row(
              children: [
                Icon(
                  _paymentIcon(widget.invoice.paymentMethod),
                  size: 28.w,
                  color: AppColors.success,
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IqText(
                      widget.invoice.paymentMethodName,
                      style: AppTypography.heading3.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    IqText(
                      AppStrings.changePaymentMethod,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // ── Action Button ──
          if (!widget.isDriver && !_isPaid && widget.invoice.paymentMethod != 0)
            // Waiting for driver to confirm payment
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IqText(
                    AppStrings.waitingDriverPaymentConfirm,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          IqPrimaryButton(
            text: widget.isDriver
                ? AppStrings.paymentReceived
                : (!_isPaid && widget.invoice.paymentMethod == 0)
                    ? AppStrings.payNow
                    : AppStrings.rateTrip,
            isLoading: _processingPayment,
            onPressed: _processingPayment
                ? null
                : (!widget.isDriver && !_isPaid && widget.invoice.paymentMethod != 0)
                    ? null
                    : _onActionPressed,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

// ── Bordered address card for invoice ──
class _InvoiceAddressCard extends StatelessWidget {
  const _InvoiceAddressCard({
    required this.address,
    required this.iconColor,
  });

  final String address;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 20.w, color: iconColor),
          SizedBox(width: 10.w),
          Expanded(
            child: IqText(
              address,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.white : AppColors.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Color parser for vehicle color names.
Color _parseColor(String colorName) {
  final lower = colorName.toLowerCase();
  const map = <String, Color>{
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'black': Colors.black,
    'white': Colors.white,
    'silver': Colors.grey,
    'gray': Colors.grey,
    'grey': Colors.grey,
    'yellow': Colors.amber,
    'orange': Colors.orange,
    'brown': Colors.brown,
    'gold': Color(0xFFFFD700),
    'أحمر': Colors.red,
    'أزرق': Colors.blue,
    'أخضر': Colors.green,
    'أسود': Colors.black,
    'أبيض': Colors.white,
    'فضي': Colors.grey,
    'رمادي': Colors.grey,
    'أصفر': Colors.amber,
    'برتقالي': Colors.orange,
    'بني': Colors.brown,
  };
  return map[lower] ?? Colors.grey;
}

/// Payment icon based on method code.
IconData _paymentIcon(int method) {
  switch (method) {
    case 0:
      return Icons.credit_card;
    case 2:
      return Icons.account_balance_wallet_outlined;
    default:
      return Icons.payments_outlined;
  }
}
