import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection_container.dart';

/// Where the app should navigate after the splash screen.
enum AppStartupDestination {
  /// First launch — show onboarding.
  onboarding,

  /// Onboarding seen but not logged in — go to login.
  login,

  /// Logged in with a valid token — go straight to home.
  home,
}

/// Lightweight helper that determines the post-splash destination
/// and persists the "onboarding seen" flag.
///
/// Uses [SharedPreferences] registered via [sl].
class AppStartup {
  AppStartup._();

  static const _onboardingKey = 'onboarding_seen';
  static const _tokenKey = 'auth_token';

  /// Synchronous check — [SharedPreferences] is already loaded at DI init.
  static AppStartupDestination getDestination() {
    final prefs = sl<SharedPreferences>();
    final isLoggedIn = prefs.getString(_tokenKey) != null;
    final onboardingSeen = prefs.getBool(_onboardingKey) ?? false;

    if (isLoggedIn) return AppStartupDestination.home;
    if (onboardingSeen) return AppStartupDestination.login;
    return AppStartupDestination.onboarding;
  }

  /// Mark onboarding as completed so it never shows again.
  static Future<void> markOnboardingSeen() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(_onboardingKey, true);
  }
}
