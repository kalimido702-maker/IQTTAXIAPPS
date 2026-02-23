import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_otp_input.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/otp_form_bloc.dart';
import '../bloc/otp_form_event.dart';
import '../bloc/otp_form_state.dart';

/// OTP verification page — **100% StatelessWidget**.
///
/// Timer countdown + OTP text live in [OtpFormBloc].
/// Auth network calls live in [AuthBloc].
class OtpPage extends StatelessWidget {
  final String phone;
  final String role;
  final void Function(BuildContext context) onVerified;
  final void Function(BuildContext context, String phone)? onNeedsRegistration;

  const OtpPage({
    super.key,
    required this.phone,
    this.role = 'passenger',
    required this.onVerified,
    this.onNeedsRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OtpFormBloc(),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  onVerified(context);
                } else if (state is AuthNeedsRegistration) {
                  onNeedsRegistration?.call(context, state.phone);
                } else if (state is AuthError) {
                  if (state.message == 'needs_registration') {
                    onNeedsRegistration?.call(context, phone);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: IqText(state.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } else if (state is AuthOtpResent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: IqText('\u062A\u0645 \u0625\u0639\u0627\u062F\u0629 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0643\u0648\u062F'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.65),
                  radius: 1.8,
                  colors: [AppColors.splashGradientLight, AppColors.white],
                ),
              ),
              child: Column(
                children: [
                  IqAppBar(title: AppStrings.confirmCode),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        children: [
                          SizedBox(height: 16.h),
                          _buildWelcomeText(),
                          SizedBox(height: 40.h),
                          _buildOtpInput(),
                          SizedBox(height: 48.h),
                          _buildTimer(),
                          SizedBox(height: 30.h),
                          _buildResendSection(),
                          SizedBox(height: 40.h),
                          _buildConfirmButton(),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeText() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IqText(AppStrings.welcomeBack, style: AppTypography.heading3),
          SizedBox(height: 15.h),
          IqText(
            AppStrings.otpSubtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Builder(builder: (context) {
      return IqOtpInput(
        onCompleted: (otp) {
          context.read<OtpFormBloc>().add(OtpFormChanged(otp));
          context.read<AuthBloc>().add(
                AuthVerifyOtpEvent(phone: phone, otp: otp, role: role),
              );
        },
        onChanged: (otp) {
          context.read<OtpFormBloc>().add(OtpFormChanged(otp));
        },
      );
    });
  }

  Widget _buildTimer() {
    return BlocBuilder<OtpFormBloc, OtpFormState>(
      buildWhen: (prev, curr) =>
          prev.secondsRemaining != curr.secondsRemaining,
      builder: (context, formState) {
        return IqText(
          formState.formattedTime,
          style: AppTypography.numberLarge.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 24.sp,
          ),
          dir: TextDirection.ltr,
        );
      },
    );
  }

  Widget _buildResendSection() {
    return BlocBuilder<OtpFormBloc, OtpFormState>(
      buildWhen: (prev, curr) => prev.canResend != curr.canResend,
      builder: (context, formState) {
        return Column(
          children: [
            IqText(AppStrings.didntGetCode, style: AppTypography.bodyLarge),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: formState.canResend
                  ? () {
                      context
                          .read<AuthBloc>()
                          .add(AuthResendOtpEvent(phone: phone, role: role));
                      context
                          .read<OtpFormBloc>()
                          .add(const OtpFormTimerStarted());
                    }
                  : null,
              child: IqText(
                AppStrings.resendCode,
                style: AppTypography.bodyLarge.copyWith(
                  decoration: TextDecoration.underline,
                  color: formState.canResend
                      ? AppColors.black
                      : AppColors.grayLight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Builder(builder: (context) {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return IqPrimaryButton(
            text: AppStrings.confirm,
            onPressed: () {
              final otp = context.read<OtpFormBloc>().state.otp;
              if (otp.length >= 6) {
                context.read<AuthBloc>().add(
                      AuthVerifyOtpEvent(phone: phone, otp: otp, role: role),
                    );
              }
            },
            isLoading: authState is AuthLoading,
          );
        },
      );
    });
  }
}
