import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/locale_state.dart';

/// Bottom sheet that shows Arabic & English language options.
///
/// Requires [LocaleCubit] in the widget tree.
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  /// Show this bottom sheet from any context that has [LocaleCubit].
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<LocaleCubit>(),
        child: const LanguageBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.gray1,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),

              // ── Title ──
              Text(
                'تغيير اللغة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 20.h),

              // ── Arabic ──
              _LanguageTile(
                flag: '🇮🇶',
                label: 'العربية',
                isSelected: state.isArabic,
                onTap: () {
                  context
                      .read<LocaleCubit>()
                      .setLocale(const Locale('ar'));
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: 12.h),

              // ── English ──
              _LanguageTile(
                flag: '🇬🇧',
                label: 'English',
                isSelected: !state.isArabic,
                onTap: () {
                  context
                      .read<LocaleCubit>()
                      .setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}

/// Single language option row.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grayBorder,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 24.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24.w,
              ),
          ],
        ),
      ),
    );
  }
}
