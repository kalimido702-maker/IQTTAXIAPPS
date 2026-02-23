import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

/// Cubit that manages the app theme mode (light / dark).
///
/// Persists the user's choice to [SharedPreferences].
class ThemeCubit extends Cubit<ThemeState> {
  final SharedPreferences _prefs;

  static const String _key = 'theme_mode';

  ThemeCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(const ThemeState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final stored = _prefs.getString(_key);
    if (stored == 'dark') {
      emit(const ThemeState(themeMode: ThemeMode.dark));
    } else {
      emit(const ThemeState(themeMode: ThemeMode.light));
    }
  }

  /// Toggle between light and dark mode.
  void toggleTheme() {
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setString(_key, newMode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeState(themeMode: newMode));
  }

  /// Explicitly set the theme mode.
  void setThemeMode(ThemeMode mode) {
    _prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeState(themeMode: mode));
  }
}
