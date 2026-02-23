import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iq_core/iq_core.dart';

/// "أحل واكسب" (Solve & Win / Referral) page — 100% StatelessWidget + Cubit.
///
/// Shows the user's referral code with copy & share actions.
/// All actions go through [ReferralCubit]. Zero hardcoded strings/colors.
class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IqAppBar(title: AppStrings.solveAndWin),
      body: BlocConsumer<ReferralCubit, ReferralState>(
        listener: (context, state) {
          if (state is ReferralLoaded && state.codeCopied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: IqText(
                  AppStrings.codeCopied,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.white),
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is! ReferralLoaded) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              children: [
                SizedBox(height: 30.h),

                // ── Gift illustration ──
                IqImage(
                  AppAssets.gift,
                  width: 150.w,
                  height: 150.h,
                ),
                SizedBox(height: 30.h),

                // ── Title ──
                IqText(
                  AppStrings.inviteFriendAndEarn,
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15.h),

                // ── Subtitle ──
                IqText(
                  AppStrings.shareYourCode,
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5.h),

                // ── Referral code card ──
                ReferralCodeCard(
                  code: state.referralCode,
                  onCopy: () =>
                      context.read<ReferralCubit>().copyCode(),
                ),
                SizedBox(height: 30.h),

                // ── Invite button ──
                IqPrimaryButton(
                  text: AppStrings.inviteFriend,
                  onPressed: () =>
                      context.read<ReferralCubit>().shareCode(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
