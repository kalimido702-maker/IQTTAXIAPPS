/// Lightweight locale accessor for [AppStrings].
///
/// Synced from [LocaleCubit] – call [setLocale] whenever the
/// cubit emits a new language code.
class LocaleService {
  LocaleService._();

  static String _lang = 'ar';

  static bool get isArabic => _lang == 'ar';
  static String get currentLang => _lang;

  static void setLocale(String languageCode) {
    _lang = languageCode;
  }
}
