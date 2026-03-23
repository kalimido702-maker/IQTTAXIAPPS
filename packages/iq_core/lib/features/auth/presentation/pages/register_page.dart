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
import '../../../../core/widgets/iq_text_field.dart';
import '../../../../core/widgets/iq_webview_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../bloc/register_form_bloc.dart';
import '../bloc/register_form_event.dart';
import '../bloc/register_form_state.dart';

/// Register page — Passenger app only.
///
/// **100% StatelessWidget** — all form state in [RegisterFormBloc],
/// all network state in [AuthBloc].
class RegisterPage extends StatelessWidget {
  final String? phone;
  final void Function(BuildContext context) onRegistered;
  final void Function(BuildContext context) onLoginTap;
  final void Function(BuildContext context, String phone)? onOtpRequired;

  const RegisterPage({
    super.key,
    this.phone,
    required this.onRegistered,
    required this.onLoginTap,
    this.onOtpRequired,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterFormBloc(initialPhone: phone),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  onRegistered(context);
                } else if (state is AuthOtpSent) {
                  // Registration succeeded but needs OTP verification.
                  if (onOtpRequired != null) {
                    onOtpRequired!(context, state.phone);
                  }
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
            BlocListener<RegisterFormBloc, RegisterFormState>(
              listenWhen: (prev, curr) => !prev.isValid && curr.isValid,
              listener: (context, formState) {
                if (!formState.agreedToTerms) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: IqText(
                          '\u064A\u0631\u062C\u0649 \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                context.read<AuthBloc>().add(
                      AuthRegisterEvent(
                        name: formState.name.trim(),
                        phone: formState.phone.trim(),
                        gender: formState.selectedGender,
                        role: 'passenger',
                      ),
                    );
              },
            ),
          ],
          child: Scaffold(
            appBar: IqAppBar(title: AppStrings.register),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildWelcomeText(),
                  SizedBox(height: 40.h),
                  _buildNameInput(),
                  SizedBox(height: 20.h),
                  _buildPhoneInput(),
                  SizedBox(height: 20.h),
                  _buildGenderSelector(),
                  SizedBox(height: 20.h),
                  _buildTermsCheckbox(),
                  SizedBox(height: 40.h),
                  _buildRegisterButton(),
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

  // ── Welcome ──

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

  // ── Name input ──

  Widget _buildNameInput() {
    return BlocBuilder<RegisterFormBloc, RegisterFormState>(
      buildWhen: (prev, curr) => prev.nameError != curr.nameError,
      builder: (context, formState) {
        return IqTextField(
          label: AppStrings.name,
          hintText: '\u0639\u0628\u062F \u0627\u0644\u0631\u062D\u0645\u0646',
          errorText: formState.nameError,
          onChanged: (value) {
            context
                .read<RegisterFormBloc>()
                .add(RegisterFormNameChanged(value));
          },
        );
      },
    );
  }

  // ── Phone input ──

  Widget _buildPhoneInput() {
    return BlocBuilder<RegisterFormBloc, RegisterFormState>(
      buildWhen: (prev, curr) => prev.phoneError != curr.phoneError,
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
                    .read<RegisterFormBloc>()
                    .add(RegisterFormPhoneChanged(value));
              },
            ),
          ],
        );
      },
    );
  }

  // ── Gender selector ──

  Widget _buildGenderSelector() {
    return BlocBuilder<RegisterFormBloc, RegisterFormState>(
      buildWhen: (prev, curr) =>
          prev.selectedGender != curr.selectedGender ||
          prev.genderError != curr.genderError,
      builder: (context, formState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IqText(AppStrings.selectGender, style: AppTypography.labelLarge),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _GenderOption(
                  label: AppStrings.female,
                  icon: Icons.female,
                  isSelected: formState.selectedGender == 'female',
                  onTap: () => context
                      .read<RegisterFormBloc>()
                      .add(const RegisterFormGenderSelected('female')),
                ),
                SizedBox(width: 20.w),
                _GenderOption(
                  label: AppStrings.male,
                  icon: Icons.male,
                  isSelected: formState.selectedGender == 'male',
                  onTap: () => context
                      .read<RegisterFormBloc>()
                      .add(const RegisterFormGenderSelected('male')),
                ),
              ],
            ),
            if (formState.genderError != null) ...[
              SizedBox(height: 4.h),
              IqText(
                formState.genderError!,
                style:
                    AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── Terms checkbox ──

  Widget _buildTermsCheckbox() {
    return BlocBuilder<RegisterFormBloc, RegisterFormState>(
      buildWhen: (prev, curr) =>
          prev.agreedToTerms != curr.agreedToTerms,
      builder: (context, formState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () => _openTermsUrl(context),
              child: IqText(
                '\u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645',
                style: AppTypography.bodyLarge.copyWith(
                  decoration: TextDecoration.underline,
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Checkbox(
                value: formState.agreedToTerms,
                onChanged: (_) => context
                    .read<RegisterFormBloc>()
                    .add(const RegisterFormTermsToggled()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                side: const BorderSide(
                    color: AppColors.grayInactive, width: 1.5),
                activeColor: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  void _openTermsUrl(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IqWebViewPage(
          title: AppStrings.termsAndConditions,
          url: 'https://iqttaxi.com/api/v1/common/mobile/terms',
        ),
      ),
    );
  }

  // ── Register button ──

  Widget _buildRegisterButton() {
    return Builder(builder: (context) {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return IqPrimaryButton(
            text: '\u062A\u0633\u062C\u064A\u0644 \u0639\u0636\u0648\u064A\u0629',
            onPressed: () {
              context
                  .read<RegisterFormBloc>()
                  .add(const RegisterFormSubmitted());
            },
            isLoading: authState is AuthLoading,
          );
        },
      );
    });
  }

  // ── Footer link ──

  Widget _buildFooterLink(BuildContext context) {
    return GestureDetector(
      onTap: () => onLoginTap(context),
      child: IqText.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '\u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628 \u061F',
                style: AppTypography.bodyLarge),
            const TextSpan(text: ' '),
            TextSpan(
              text: AppStrings.login,
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

// ── Gender option chip ──

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grayInactive,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.w,
              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 10.w),
            IqText(
              label,
              style: AppTypography.bodyLarge,
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                side: const BorderSide(
                    color: AppColors.grayInactive, width: 1.5),
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
