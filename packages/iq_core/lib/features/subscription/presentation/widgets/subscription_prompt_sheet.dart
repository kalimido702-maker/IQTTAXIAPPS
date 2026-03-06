import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../../home/data/models/home_data_model.dart';
import '../../data/models/subscription_models.dart';
import '../bloc/subscription_bloc.dart';
import '../pages/subscription_page.dart';

/// Key used to persist the "skip subscription" preference.
const _kSubscriptionSkipKey = 'skipSubscription';

/// Check & clear subscription skip status from SharedPreferences.
Future<bool> getSubscriptionSkipStatus() async {
  final prefs = sl<SharedPreferences>();
  return prefs.getBool(_kSubscriptionSkipKey) ?? false;
}

/// Persist subscription skip status.
Future<void> setSubscriptionSkipStatus(bool value) async {
  final prefs = sl<SharedPreferences>();
  await prefs.setBool(_kSubscriptionSkipKey, value);
}

/// Clear subscription skip status (call on logout).
Future<void> clearSubscriptionSkipStatus() async {
  final prefs = sl<SharedPreferences>();
  await prefs.remove(_kSubscriptionSkipKey);
}

/// Determines whether the subscription prompt bottom sheet should be shown
/// for the given [homeData].
///
/// Mirrors the old app logic:
///   - `hasSubscription == true` (subscription feature is enabled)
///   - `isApproved == true` (driver is approved)
///   - `isSubscribed == false` (driver does NOT currently have an active sub)
///   - `driverMode` is 'subscription' or 'both'
bool shouldShowSubscriptionPrompt(HomeDataModel? homeData) {
  if (homeData == null) return false;
  final mode = homeData.driverMode;
  return homeData.hasSubscription == true &&
      homeData.isApproved == true &&
      homeData.isSubscribed == false &&
      (mode == 'subscription' || mode == 'both');
}

/// Shows the subscription prompt bottom sheet (non-dismissible).
///
/// Call this from the driver home page after verifying
/// [shouldShowSubscriptionPrompt] returns true and
/// [getSubscriptionSkipStatus] returns false.
///
/// Returns `true` if driver subscribed, `null` otherwise.
Future<dynamic> showSubscriptionPromptSheet(
  BuildContext context, {
  required HomeDataModel homeData,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: false,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _SubscriptionPromptSheet(homeData: homeData),
  );
}

/// The actual bottom sheet content — prompts the driver to subscribe.
///
/// Based on the old app's `ShowSubscriptionWidget`:
/// - Always shows a heading + "اختر الخطة" CTA
/// - If `driverMode == 'both'` → also shows "الاستمرار بدون خطط" option
class _SubscriptionPromptSheet extends StatelessWidget {
  const _SubscriptionPromptSheet({required this.homeData});

  final HomeDataModel homeData;

  @override
  Widget build(BuildContext context) {
    final isBothMode = homeData.driverMode == 'both';

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grayBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              SizedBox(height: 24.h),

              // Warning icon
              Icon(
                Icons.warning_amber_rounded,
                size: 48.w,
                color: AppColors.error,
              ),

              SizedBox(height: 16.h),

              // Heading text
              IqText(
                'يجب عليك الاشتراك في إحدى الخطط للبدء في استقبال الطلبات',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
              ),

              SizedBox(height: 28.h),

              // "اختر الخطة" button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _navigateToSubscription(context);
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
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),

              // "Continue without plans" — only when driverMode == 'both'
              if (isBothMode) ...[
                SizedBox(height: 16.h),

                IqText(
                  'أو',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 16.sp),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                GestureDetector(
                  onTap: () {
                    setSubscriptionSkipStatus(true);
                    Navigator.of(context).pop();
                  },
                  child: IqText(
                    'الاستمرار بدون خطط',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary700,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 8.h),

                IqText(
                  'يمكنك العمل بنظام العمولة بدون الحاجة إلى اشتراك',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray2,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    final activeSub = homeData.subscriptionData != null
        ? ActiveSubscription.fromJson(homeData.subscriptionData!)
        : null;

    Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => BlocProvider(
          create: (_) => sl<SubscriptionBloc>()
            ..add(SubscriptionLoadPlans(
              activeSubscription: activeSub,
              hasSubscription: homeData.hasSubscription,
              isExpired: homeData.isSubscriptionExpired,
              walletBalance: homeData.wallet.balance,
              currencySymbol: homeData.currencySymbol,
            )),
          child: const SubscriptionPage(),
        ),
      ),
    ).then((result) {
      if (!context.mounted) return;
      // If subscribed successfully → close the bottom sheet
      if (result == true || homeData.isSubscribed) {
        Navigator.of(context).pop(true);
      }
    });
  }
}
