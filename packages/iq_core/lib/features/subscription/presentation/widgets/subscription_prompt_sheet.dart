import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_strings.dart';
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
/// The prompt is shown when:
///   - `hasSubscription == true` (subscription feature is enabled)
///   - `isApproved == true` (driver is approved)
///   - driver does NOT have an active subscription
///   - `driverMode` is 'subscription' or 'both'
///
/// A driver is considered subscribed if `isSubscribed == true`,
/// OR if they have `subscriptionData` that hasn't expired yet.
bool shouldShowSubscriptionPrompt(HomeDataModel? homeData) {
  if (homeData == null) return false;
  final mode = homeData.driverMode;

  // Driver must be approved and in a subscription-based mode.
  if (homeData.isApproved != true) return false;
  if (mode != 'subscription' && mode != 'both') return false;

  // If subscription is expired → ALWAYS show the renewal prompt, even if
  // hasSubscription or isSubscribed flags appear stale from the backend.
  if (homeData.isSubscriptionExpired == true) return true;

  // Feature gate: subscription feature must be enabled for non-expired cases.
  if (homeData.hasSubscription != true) return false;

  // If API explicitly says subscribed and not expired → don't show.
  if (homeData.isSubscribed == true) return false;

  // If active subscription data exists → treat as subscribed.
  if (homeData.subscriptionData != null) return false;

  return true;
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
                AppStrings.subscriptionRequiredPrompt,
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
                    AppStrings.choosePlan,
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
                  AppStrings.or,
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
                    AppStrings.continueWithoutPlans,
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
                  AppStrings.commissionModeHint,
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
