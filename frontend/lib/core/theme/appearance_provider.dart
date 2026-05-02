import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'appearance_theme_mode';
const _kAccentIdx = 'appearance_accent_idx';
const _kFontScale = 'appearance_font_scale';

const accentOptions = [
  ('Mauve', Color(0xFF8B6A7A)),
  ('Indigo', Color(0xFF6366F1)),
  ('Teal', Color(0xFF0D9488)),
  ('Amber', Color(0xFFD97706)),
  ('Rose', Color(0xFFE11D48)),
];

class AppearanceState {
  final int themeMode;
  final int accentIdx;
  final double fontScale;

  const AppearanceState({
    this.themeMode = 0,
    this.accentIdx = 0,
    this.fontScale = 1.0,
  });

  ThemeMode get flutterThemeMode => switch (themeMode) {
        1 => ThemeMode.dark,
        2 => ThemeMode.system,
        _ => ThemeMode.light,
      };

  Color get accent =>
      accentOptions[accentIdx.clamp(0, accentOptions.length - 1)].$2;

  AppearanceState copyWith({
    int? themeMode,
    int? accentIdx,
    double? fontScale,
  }) =>
      AppearanceState(
        themeMode: themeMode ?? this.themeMode,
        accentIdx: accentIdx ?? this.accentIdx,
        fontScale: fontScale ?? this.fontScale,
      );
}

class AppearanceNotifier extends StateNotifier<AppearanceState> {
  AppearanceNotifier() : super(const AppearanceState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppearanceState(
      themeMode: prefs.getInt(_kThemeMode) ?? 0,
      accentIdx: prefs.getInt(_kAccentIdx) ?? 0,
      fontScale: prefs.getDouble(_kFontScale) ?? 1.0,
    );
  }

  void setThemeMode(int mode) => state = state.copyWith(themeMode: mode);
  void setAccentIdx(int idx) => state = state.copyWith(accentIdx: idx);
  void setFontScale(double scale) => state = state.copyWith(fontScale: scale);

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_kThemeMode, state.themeMode),
      prefs.setInt(_kAccentIdx, state.accentIdx),
      prefs.setDouble(_kFontScale, state.fontScale),
    ]);
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceNotifier, AppearanceState>((ref) {
  return AppearanceNotifier();
});
