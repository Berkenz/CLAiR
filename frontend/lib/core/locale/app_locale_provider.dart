import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageCode = 'app_language_code';

const supportedLanguageCodes = {'en', 'fil', 'ceb'};

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLanguageCode) ?? 'en';
    state = _localeFromCode(raw);
  }

  static Locale _localeFromCode(String code) {
    final c = code.toLowerCase();
    if (supportedLanguageCodes.contains(c)) {
      return Locale(c);
    }
    return const Locale('en');
  }

  Future<void> setLanguageCode(String code) async {
    final locale = _localeFromCode(code);
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, locale.languageCode);
  }
}

final appLocaleProvider =
    StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  return AppLocaleNotifier();
});
