import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/iq_app_bar.dart';
import '../../../../core/widgets/iq_outlined_button.dart';
import '../../../../core/widgets/iq_webview_page.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/theme_state.dart';
import '../widgets/settings_row.dart';

/// Settings page — 100% StatelessWidget + BLoC/Cubit.
///
/// Items: الوضع الداكن (toggle via ThemeCubit), التعليمات, سياسة الخصوصية.
/// Bottom: red outlined "تسجيل خروج" button.
///
/// Zero hardcoded colors/strings. All from AppColors/AppStrings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.onLogout,
  });

  /// Called when the user taps "تسجيل خروج".
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IqAppBar(title: AppStrings.settings),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // ── الوضع الداكن ──
            BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return SettingsRow(
                  label: AppStrings.darkMode,
                  trailing: Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: themeState.isDark,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().toggleTheme(),
                      activeThumbColor: AppColors.buttonYellow,
                      activeTrackColor:
                          AppColors.buttonYellow.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
            Divider(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDivider
                  : AppColors.grayBorder,
              height: 1.h,
            ),

            // ── التعليمات ──
            SettingsRow(
              label: AppStrings.instructionsPage,
              trailing: Icon(
                Icons.chevron_left,
                color: AppColors.gray2,
                size: 20.w,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IqWebViewPage(
                      title: AppStrings.instructionsPage,
                      url: 'https://taxi-new.elnoorphp.com/api/v1/common/mobile/terms',
                    ),
                  ),
                );
              },
            ),
            Divider(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkDivider
                  : AppColors.grayBorder,
              height: 1.h,
            ),

            // ── سياسة الخصوصية ──
            SettingsRow(
              label: AppStrings.privacyPolicy,
              trailing: Icon(
                Icons.chevron_left,
                color: AppColors.gray2,
                size: 20.w,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IqWebViewPage(
                      title: AppStrings.privacyPolicy,
                      url: 'https://taxi-new.elnoorphp.com/api/v1/common/mobile/privacy',
                    ),
                  ),
                );
              },
            ),

            // const Spacer(),
            SizedBox(height: 40.h),

            // ── تسجيل خروج ──
            IqOutlinedButton(
              text: AppStrings.logout,
              onPressed: onLogout,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
