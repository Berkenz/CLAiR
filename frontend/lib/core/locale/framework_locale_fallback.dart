import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Locales our ARBs support but Flutter's Material/Cupertino catalogs do not.
/// We still use [Locale('ceb')] for [AppLocalizations]; framework strings fall back to English.
Locale frameworkLocaleFallback(Locale locale) {
  switch (locale.languageCode) {
    case 'ceb':
      return const Locale('en');
    default:
      return locale;
  }
}

/// Loads [MaterialLocalizations] using [frameworkLocaleFallback] so `ceb` does not crash.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate
          .load(frameworkLocaleFallback(locale));

  @override
  bool shouldReload(covariant FallbackMaterialLocalizationsDelegate old) =>
      false;
}

/// Loads [CupertinoLocalizations] using [frameworkLocaleFallback] so `ceb` does not crash.
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate
          .load(frameworkLocaleFallback(locale));

  @override
  bool shouldReload(covariant FallbackCupertinoLocalizationsDelegate old) =>
      false;
}
