import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../wallet/presentation/pages/payment_web_view_page.dart';
import '../../data/models/subscription_models.dart';
import '../bloc/subscription_bloc.dart';

/// Main subscription page — الإشتراك
///
/// Renders the correct screen based on [SubscriptionViewStatus]:
///   - loading → shimmer
///   - noSubscription → empty state + "اختر الخطة" CTA
///   - expired → expiry info + "اختر الخطة" CTA
///   - active / success → green check + subscription details
///   - planList → plan cards + payment options + "تنفيذ" button
///   - submitting → loading overlay
///   - error → inline error + retry
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  Future<void> _openPaymentWebView(
    BuildContext context,
    String paymentUrl,
  ) async {
    final bloc = context.read<SubscriptionBloc>();
    final result = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(paymentUrl: paymentUrl),
      ),
    );

    final success = result == PaymentResult.success;
    bloc.add(SubscriptionPaymentCompleted(success: success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const IqAppBar(title: 'الإشتراك'),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            prev.paymentUrl != curr.paymentUrl ||
            prev.errorMessage != curr.errorMessage ||
            prev.status != curr.status,
        listener: (context, state) {
          // Payment URL → open WebView.
          if (state.paymentUrl != null && state.paymentUrl!.isNotEmpty) {
            _openPaymentWebView(context, state.paymentUrl!);
          }
          // Error snackbar (low wallet, payment failed, etc.)
          if (state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            SubscriptionViewStatus.loading => _buildShimmer(),
            SubscriptionViewStatus.noSubscription =>
              _NoSubscriptionView(onChoosePlan: () {
                context
                    .read<SubscriptionBloc>()
                    .add(const SubscriptionChoosePlan());
              }),
            SubscriptionViewStatus.expired => _ExpiredView(
                subscription: state.activeSubscription,
                currencySymbol: state.currencySymbol,
                onChoosePlan: () {
                  context
                      .read<SubscriptionBloc>()
                      .add(const SubscriptionChoosePlan());
                },
              ),
            SubscriptionViewStatus.active => _SuccessView(
                subscription: state.activeSubscription,
              ),
            SubscriptionViewStatus.success => _SuccessView(
                subscription: state.activeSubscription,
                successMessage: state.successMessage,
                isNewSubscription: true,
              ),
            SubscriptionViewStatus.planList ||
            SubscriptionViewStatus.submitting =>
              _PlanListView(
                plans: state.plans,
                selectedPlanIndex: state.selectedPlanIndex,
                isFreeDayOn: state.isFreeDayOn,
                paymentOption: state.paymentOption,
                currencySymbol: state.currencySymbol,
                isSubmitting:
                    state.status == SubscriptionViewStatus.submitting,
              ),
            SubscriptionViewStatus.error => _ErrorView(
                message: state.errorMessage ?? 'حدث خطأ',
                onRetry: () {
                  context
                      .read<SubscriptionBloc>()
                      .add(const SubscriptionChoosePlan());
                },
              ),
          };
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 120.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            SizedBox(height: 30.h),
            Container(
              width: 100.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 100.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(width: 20.w),
                Container(
                  width: 100.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Container(
              width: 100.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 100.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(width: 20.w),
                Container(
                  width: 100.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1000.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _PlanListView — Plan selection (Figma: node 7:6174)
// ═════════════════════════════════════════════════════════════════════

class _PlanListView extends StatelessWidget {
  const _PlanListView({
    required this.plans,
    required this.selectedPlanIndex,
    required this.isFreeDayOn,
    required this.paymentOption,
    required this.currencySymbol,
    this.isSubmitting = false,
  });

  final List<SubscriptionPlan> plans;
  final int selectedPlanIndex;
  final bool isFreeDayOn;
  final int paymentOption;
  final String currencySymbol;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: 20.h),

              // ── Section: اختر اشتراكك ──
              IqText(
                'اختر اشتراكك',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 20.h),

              // Plan cards
              ...List.generate(plans.length, (i) {
                final plan = plans[i];
                final isSelected = i == selectedPlanIndex;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _PlanCard(
                    plan: plan,
                    isSelected: isSelected,
                    currencySymbol: currencySymbol,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<SubscriptionBloc>()
                          .add(SubscriptionPlanSelected(i));
                    },
                  ),
                );
              }),

              SizedBox(height: 30.h),

              // ── Section: اختر الخطة ──
              IqText(
                'اختر الخطة',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ChoiceChip(
                    label: 'مدفوع',
                    isSelected: !isFreeDayOn,
                    onTap: () => context
                        .read<SubscriptionBloc>()
                        .add(const SubscriptionFreeDayToggled(false)),
                  ),
                  SizedBox(width: 20.w),
                  _ChoiceChip(
                    label: 'مجاني',
                    isSelected: isFreeDayOn,
                    onTap: () => context
                        .read<SubscriptionBloc>()
                        .add(const SubscriptionFreeDayToggled(true)),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Hint text
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: IqText(
                        '• يمكنك تجربة الاشتراك المجاني لمدة 48 ساعة',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gray3,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // ── Section: طريقة الدفع ──
              IqText(
                'طريقة الدفع',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ChoiceChip(
                    label: 'بطاقة دفع',
                    isSelected: paymentOption == 0,
                    onTap: () => context.read<SubscriptionBloc>().add(
                          const SubscriptionPaymentMethodChanged(0),
                        ),
                  ),
                  SizedBox(width: 20.w),
                  _ChoiceChip(
                    label: 'محفظة',
                    isSelected: paymentOption == 2,
                    onTap: () => context.read<SubscriptionBloc>().add(
                          const SubscriptionPaymentMethodChanged(2),
                        ),
                  ),
                ],
              ),

              SizedBox(height: 50.h),

              // ── Confirm button ──
              SizedBox(
                width: double.infinity,
                height: 60.h,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          context
                              .read<SubscriptionBloc>()
                              .add(const SubscriptionConfirmed());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonYellow,
                    foregroundColor: AppColors.black,
                    disabledBackgroundColor:
                        AppColors.buttonYellow.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1000.r),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.black,
                          ),
                        )
                      : IqText(
                          'تنفيذ',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.black,
                            fontSize: 18.sp,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _PlanCard
// ═════════════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.currencySymbol,
    this.onTap,
  });

  final SubscriptionPlan plan;
  final bool isSelected;
  final String currencySymbol;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.black : const Color(0xFFDADADA),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IqText(
                    plan.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IqText(
                        '${plan.amount} $currencySymbol',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IqText(
                        'اشتراك اليوم :',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Radio circle
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.black,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.black,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _ChoiceChip — Checkbox-style choice chip (Figma design)
// ═════════════════════════════════════════════════════════════════════

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.black : const Color(0xFFDADADA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IqText(
              label,
              style: AppTypography.bodyMedium.copyWith(fontSize: 16.sp),
            ),
            SizedBox(width: 10.w),
            // Checkbox icon
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.grayBorder,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: 16.w,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _SuccessView — تم الاشتراك بنجاح (Figma: node 7:6469)
// ═════════════════════════════════════════════════════════════════════

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    this.subscription,
    this.successMessage,
    this.isNewSubscription = false,
  });

  final ActiveSubscription? subscription;
  final String? successMessage;
  final bool isNewSubscription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Green check circle
          Container(
            width: 200.w,
            height: 200.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF50D1AA).withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.check,
              size: 100.w,
              color: const Color(0xFF50D1AA),
            ),
          ),

          SizedBox(height: 50.h),

          IqText(
            'تم الاشتراك بنجاح',
            style: AppTypography.heading2.copyWith(
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),

          if (subscription != null) ...[
            _InfoRow(
              label: 'نوع الإشتراك :',
              value: subscription!.subscriptionName.isNotEmpty
                  ? subscription!.subscriptionName
                  : 'أسبوعي',
            ),
            SizedBox(height: 15.h),
            _InfoRow(
              label: 'السعر :',
              value: '${subscription!.paidAmount} IQD',
            ),
            SizedBox(height: 15.h),
            _InfoRow(
              label: 'تاريخ ووقت اللإنتهاء :',
              value:
                  'صالحة حتى ${subscription!.expiredAt.split(' ').first}',
            ),
          ],

          const Spacer(flex: 2),

          // "نعم" button
          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
                elevation: 0,
              ),
              child: IqText(
                'نعم',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.black,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _ExpiredView — انتهاء الاشتراك (Figma: node 7:6287)
// ═════════════════════════════════════════════════════════════════════

class _ExpiredView extends StatelessWidget {
  const _ExpiredView({
    this.subscription,
    required this.currencySymbol,
    required this.onChoosePlan,
  });

  final ActiveSubscription? subscription;
  final String currencySymbol;
  final VoidCallback onChoosePlan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Expired illustration — red/orange warning icon
          Container(
            width: 200.w,
            height: 200.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.block_rounded,
              size: 100.w,
              color: AppColors.error,
            ),
          ),

          SizedBox(height: 50.h),

          IqText(
            'انتهت صلاحية الاشتراك',
            style: AppTypography.heading2.copyWith(
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),

          if (subscription != null) ...[
            _InfoRow(
              label: 'نوع الإشتراك :',
              value: subscription!.subscriptionName.isNotEmpty
                  ? subscription!.subscriptionName
                  : 'أسبوعي',
            ),
            SizedBox(height: 15.h),
            _InfoRow(
              label: 'السعر :',
              value: '${subscription!.paidAmount} $currencySymbol',
            ),
            SizedBox(height: 15.h),
            _InfoRow(
              label: 'تاريخ ووقت اللإنتهاء :',
              value:
                  'كانت صالحة حتى ${subscription!.expiredAt.split(' ').first}',
            ),
          ],

          const Spacer(flex: 2),

          // "اختر الخطة" button
          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onChoosePlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
                elevation: 0,
              ),
              child: IqText(
                'اختر الخطة',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.black,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _NoSubscriptionView — لا يوجد اشتراك
// ═════════════════════════════════════════════════════════════════════

class _NoSubscriptionView extends StatelessWidget {
  const _NoSubscriptionView({required this.onChoosePlan});

  final VoidCallback onChoosePlan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          const Spacer(flex: 1),

          Icon(
            Icons.card_membership_rounded,
            size: 120.w,
            color: AppColors.grayLight,
          ),

          SizedBox(height: 40.h),

          IqText(
            'لا يوجد اشتراك',
            style: AppTypography.heading2.copyWith(
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 20.h),

          IqText(
            'ليس لديك اشتراك حالياً. اختر خطة للبدء في استقبال الطلبات.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray3,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            height: 60.h,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onChoosePlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonYellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
                elevation: 0,
              ),
              child: IqText(
                'اختر الخطة',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.black,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),

          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _ErrorView
// ═════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: AppColors.error),
            SizedBox(height: 16.h),
            IqText(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: onRetry,
              child: IqText(
                'إعادة المحاولة',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  _InfoRow — label : value row (RTL)
// ═════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: IqText(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        IqText(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.gray3,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
