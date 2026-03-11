import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_phone_input.dart';
import '../../../../core/widgets/iq_primary_button.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/login_form_bloc.dart';
import '../bloc/login_form_event.dart';
import '../bloc/login_form_state.dart';

/// Login page — shared between Passenger & Driver apps.
///
/// **100% StatelessWidget** — all mutable state lives in
/// [LoginFormBloc] (validation) and [AuthBloc] (network).
class LoginPage extends StatelessWidget {
  final Widget Function(BuildContext context) headerBuilder;
  final void Function(BuildContext context, String phone) onOtpSent;
  final void Function(BuildContext context, String phone)? onNeedsRegistration;
  final String footerText;
  final String footerLinkLabel;
  final void Function(BuildContext context) onFooterLinkTap;
  final String title;
  final String role;
  final bool isDriver;

  LoginPage({
    super.key,
    required this.headerBuilder,
    required this.onOtpSent,
    this.onNeedsRegistration,
    String? footerText,
    required this.footerLinkLabel,
    required this.onFooterLinkTap,
    String? title,
    this.role = 'passenger',
    this.isDriver = false,
  })  : footerText = footerText ?? AppStrings.noAccount,
        title = title ?? AppStrings.login;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginFormBloc(),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthOtpSent) {
                  onOtpSent(context, state.phone);
                } else if (state is AuthNeedsRegistration) {
                  onNeedsRegistration?.call(context, state.phone);
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: IqText(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            BlocListener<LoginFormBloc, LoginFormState>(
              listenWhen: (prev, curr) =>
                  !prev.validationPassed && curr.validationPassed,
              listener: (context, formState) {
                final phone = formState.phone.trim();
                context
                    .read<AuthBloc>()
                    .add(AuthSendOtpEvent(phone: phone, role: role));
              },
            ),
          ],
          child: Scaffold(
            appBar: IqAppBar(title: title),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  headerBuilder(context),
                  if (isDriver == false) SizedBox(height: 40.h),
                  if (isDriver == false) _buildWelcomeText(),
                  if (isDriver == false) SizedBox(height: 40.h),
                  _buildPhoneInput(),
                  SizedBox(height: 40.h),
                  _buildContinueButton(),
                  SizedBox(height: 40.h),
                  _buildFooterLink(context),
                  SizedBox(height: 24.h),
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
            AppStrings.loginSubtitle,
            style: AppTypography.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return BlocBuilder<LoginFormBloc, LoginFormState>(
      builder: (context, formState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IqText(AppStrings.phoneNumber, style: AppTypography.labelLarge),
            SizedBox(height: 15.h),
            IqPhoneInput(
              errorText: formState.phoneError,
              onChanged: (value) {
                context
                    .read<LoginFormBloc>()
                    .add(LoginFormPhoneChanged(value));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return Builder(builder: (context) {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return IqPrimaryButton(
            text: AppStrings.continueButton,
            onPressed: () {
              context
                  .read<LoginFormBloc>()
                  .add(const LoginFormSubmitted());
            },
            isLoading: authState is AuthLoading,
          );
        },
      );
    });
  }

  Widget _buildFooterLink(BuildContext context) {
    return GestureDetector(
      onTap: () => onFooterLinkTap(context),
      child: IqText.rich(
        TextSpan(
          children: [
            TextSpan(text: footerText, style: AppTypography.bodyLarge),
            const TextSpan(text: ' '),
            TextSpan(
              text: footerLinkLabel,
              style: AppTypography.labelLarge.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
