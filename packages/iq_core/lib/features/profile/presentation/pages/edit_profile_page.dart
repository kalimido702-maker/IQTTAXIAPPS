import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_text.dart';
import '../bloc/profile_bloc.dart';

/// Edit Profile Page — form to update user info (Figma: تعديل البروفايل).
///
/// Fields: name, phone (read-only), email, gender.
/// Buttons: حفظ (save), إلغاء (cancel).
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  String? _selectedGender;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileBloc>().state.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: IqText(
                AppStrings.profileUpdated,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == ProfileStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: IqText(
                state.errorMessage ?? AppStrings.somethingWrong,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: IqAppBar(title: AppStrings.editProfile),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final user = state.user;
            final isUpdating = state.status == ProfileStatus.updating;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
                      // ─── Avatar with camera ───
                      _AvatarSection(
                        avatarUrl: user?.avatarUrl,
                        pickedImagePath: _pickedImagePath,
                        onPickImage: _pickImage,
                      ),
                      SizedBox(height: 20.h),

                      // ─── Name field ───
                      _LabeledField(
                        label: AppStrings.name,
                        child: _StyledTextField(
                          controller: _nameController,
                          hintText: AppStrings.name,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ─── Phone field (read-only) ───
                      _LabeledField(
                        label: AppStrings.phoneNumber,
                        child: _PhoneField(
                          phone: user?.phone ?? '',
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ─── Email field ───
                      _LabeledField(
                        label: AppStrings.email,
                        child: _StyledTextField(
                          controller: _emailController,
                          hintText: AppStrings.email,
                          keyboardType: TextInputType.emailAddress,
                          dir: TextDirection.ltr,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ─── Gender selector ───
                      _LabeledField(
                        label: AppStrings.selectGender,
                        child: _GenderSelector(
                          selectedGender: _selectedGender,
                          onChanged: (g) =>
                              setState(() => _selectedGender = g),
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // ─── Buttons: Cancel + Save ───
                      Row(
                        children: [
                          // Cancel button
                          _CancelButton(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                          ),
                          SizedBox(width: 12.w),
                          // Save button
                          Expanded(
                            child: _SaveButton(
                              isLoading: isUpdating,
                              onTap: _onSave,
                            ),
                          ),
                        ].reversed.toList(),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
                // Loading overlay
                if (isUpdating)
                  Positioned.fill(
                    child: Container(
                      color: AppColors.black.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _pickedImagePath = image.path);
    }
  }

  void _onSave() {
    HapticFeedback.lightImpact();
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender,
          profilePicturePath: _pickedImagePath,
        ));
  }
}

// ────────────────────────────────────────────────────────────────
// Private Widgets
// ────────────────────────────────────────────────────────────────

/// Avatar section with camera overlay.
class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    this.avatarUrl,
    this.pickedImagePath,
    required this.onPickImage,
  });

  final String? avatarUrl;
  final String? pickedImagePath;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Center(
        child: SizedBox(
          width: 173.w,
          height: 173.w,
          child: Stack(
            children: [
              // Avatar image
              CircleAvatar(
                radius: 86.5.w,
                backgroundColor:
                    AppColors.grayLight.withValues(alpha: 0.3),
                backgroundImage: _resolveImage(),
              ),
              // Camera overlay (bottom-right)
              Positioned(
                bottom: 4.w,
                right: 4.w,
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 18.w,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _resolveImage() {
    if (pickedImagePath != null) {
      return FileImage(File(pickedImagePath!));
    }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return NetworkImage(avatarUrl!);
    }
    return const AssetImage(AppAssets.profilePlaceholder);
  }
}

/// Label + child widget.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: IqText(
            label,
            style: AppTypography.labelLarge,
          ),
        ),
        SizedBox(height: 15.h),
        child,
      ],
    );
  }
}

/// Styled text field matching Figma (yellow border, 12r radius, 52h).
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    this.controller,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
    this.dir,
    this.textAlign,
    this.prefixIcon,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final TextDirection? dir;
  final TextAlign? textAlign;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final resolvedDir = dir ?? Directionality.of(context);
    final resolvedAlign = textAlign ??
        (resolvedDir == TextDirection.rtl
            ? TextAlign.right
            : TextAlign.left);

    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        textDirection: resolvedDir,
        textAlign: resolvedAlign,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.inputHintColor,
          ),
          prefixIcon: prefixIcon,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkInputBg
              : AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDivider
                  : AppColors.inputBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDivider
                  : AppColors.inputBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
              color: AppColors.inputFocusBorder,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone field with Iraq flag (read-only).
class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.inputBorder),
      ),
      child: Row(
        children: [
          // Iraq flag
          ClipRRect(
            borderRadius: BorderRadius.circular(2.r),
            child: Image.asset(
              AppAssets.iraqFlag,
              width: 30.w,
              height: 20.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8.w),
          // Country code + phone
          Expanded(
            child: IqText(
              '${AppStrings.countryCode} | $phone',
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTypography.fontFamilyLatin,
              ),
              dir: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gender selector with male/female options.
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    this.selectedGender,
    required this.onChanged,
  });

  final String? selectedGender;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Female
        _GenderOption(
          label: AppStrings.female,
          icon: Icons.female_rounded,
          isSelected: selectedGender == 'female',
          onTap: () => onChanged('female'),
        ),
        SizedBox(width: 20.w),
        // Male
        _GenderOption(
          label: AppStrings.male,
          icon: Icons.male_rounded,
          isSelected: selectedGender == 'male',
          onTap: () => onChanged('male'),
        ),
      ],
    );
  }
}

/// Single gender option chip.
class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grayInactive,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : isDark ? AppColors.darkCard : AppColors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.w,
              color: isSelected ? AppColors.primary700 : onSurface,
            ),
            SizedBox(width: 10.w),
            IqText(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: onSurface,
                height: 1,
              ),
            ),
            SizedBox(width: 8.w),
            // Checkbox
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.grayInactive,
                  width: 1.5,
                ),
                color: isSelected
                    ? AppColors.primary
                    : isDark ? AppColors.darkCard : AppColors.white,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14.w,
                      color: AppColors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cancel button (red outline).
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156.w,
        height: 55.h,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: AppColors.cancelRed),
        ),
        alignment: Alignment.center,
        child: IqText(
          AppStrings.cancel,
          style: AppTypography.heading3.copyWith(
            color: AppColors.cancelRed,
          ),
        ),
      ),
    );
  }
}

/// Save button (yellow filled).
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onTap,
    this.isLoading = false,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 55.h,
        decoration: BoxDecoration(
          color: AppColors.buttonYellow,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.black,
                ),
              )
            : IqText(
                AppStrings.save,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.black,
                ),
              ),
      ),
    );
  }
}
