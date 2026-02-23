import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_state.dart';

/// Cubit that manages the app locale (Arabic / English).
///
/// Persists the user's choice to [SharedPreferences].
class LocaleCubit extends Cubit<LocaleState> {
  final SharedPreferences _prefs;

  static const String _key = 'app_locale';

  LocaleCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(const LocaleState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final stored = _prefs.getString(_key);
    if (stored != null) {
      emit(LocaleState(locale: Locale(stored)));
    }
  }

  /// Switch to [locale].
  void setLocale(Locale locale) {
    _prefs.setString(_key, locale.languageCode);
    emit(LocaleState(locale: locale));
  }

  /// Toggle between Arabic and English.
  void toggleLocale() {
    final newLocale =
        state.isArabic ? const Locale('en') : const Locale('ar');
    setLocale(newLocale);
  }
}
