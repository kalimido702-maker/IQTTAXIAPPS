import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/profile_bloc.dart';
import 'edit_profile_page.dart';

/// Profile page — shows user info in a card (Figma: بروفايل).
///
/// The card displays avatar, name, gender, ID, email and phone.
/// Tapping the edit icon navigates to [EditProfilePage].
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(title: AppStrings.profile),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == ProfileStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IqText(
                    state.errorMessage ?? AppStrings.somethingWrong,
                    style: AppTypography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => context
                        .read<ProfileBloc>()
                        .add(const ProfileLoadRequested()),
                    child: IqText(
                      AppStrings.retry,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final user = state.user;
          if (user == null) {
            return const SizedBox.shrink();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: _ProfileCard(
              name: user.name,
              gender: user.gender,
              userId: user.id,
              email: user.email,
              phone: user.phone,
              avatarUrl: user.avatarUrl,
              onEditTap: () => _navigateToEdit(context),
            ),
          );
        },
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: const EditProfilePage(),
        ),
      ),
    );
  }
}

/// Profile card matching Figma design.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    this.gender,
    required this.userId,
    this.email,
    required this.phone,
    this.avatarUrl,
    required this.onEditTap,
  });

  final String name;
  final String? gender;
  final String userId;
  final String? email;
  final String phone;
  final String? avatarUrl;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Top row: edit button + avatar + placeholder ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edit button (pen icon)
              GestureDetector(
                onTap: onEditTap,
                child: Container(
                  width: 31.w,
                  height: 31.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16.w,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              // Avatar
              CircleAvatar(
                radius: 47.5.w,
                backgroundColor: AppColors.grayLight.withValues(alpha: 0.3),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : AssetImage(AppAssets.profilePlaceholder)
                        as ImageProvider,
              ),
              const Spacer(),
              // Placeholder for symmetry (settings icon in figma, keeping empty)
              SizedBox(width: 31.w),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── Name ───
          IqText(
            name,
            style: AppTypography.heading3,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),

          // ─── Gender + ID ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gender
              if (gender != null && gender!.isNotEmpty) ...[
                Icon(
                  gender == 'male'
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  size: 18.w,
                  color: AppColors.textSubtitle,
                ),
                SizedBox(width: 3.w),
                IqText(
                  gender == 'male' ? AppStrings.male : AppStrings.female,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSubtitle,
                    height: 1,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              // ID
              IqText(
                '${AppStrings.idLabel} : $userId',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSubtitle,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),

          // ─── Email card ───
          if (email != null && email!.isNotEmpty)
            _InfoChip(
              text: email!,
            ),
          if (email != null && email!.isNotEmpty) SizedBox(height: 10.h),

          // ─── Phone card ───
          _InfoChip(
            text: phone,
            icon: Icons.phone_outlined,
          ),
        ],
      ),
    );
  }
}

/// Small card for email/phone display.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: IqText(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontFamily: AppTypography.fontFamilyLatin,
              ),
              textAlign: TextAlign.center,
              dir: TextDirection.ltr,
            ),
          ),
          if (icon != null) ...[
            SizedBox(width: 10.w),
            Icon(
              icon,
              size: 14.w,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}
