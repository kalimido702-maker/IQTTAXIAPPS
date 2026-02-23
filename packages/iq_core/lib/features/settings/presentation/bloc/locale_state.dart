import 'dart:ui';

import 'package:equatable/equatable.dart';

/// State for [LocaleCubit].
class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({this.locale = const Locale('ar')});

  bool get isArabic => locale.languageCode == 'ar';

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }

  @override
  List<Object> get props => [locale];
}
