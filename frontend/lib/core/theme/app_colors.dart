import 'package:flutter/material.dart';

/// Static fallback palette — used by app_theme.dart for default construction.
class AppColors {
  AppColors._();

  static const Color bg       = Color(0xFFF4F5F7);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color accent   = Color(0xFF8B6A7A);
  static const Color accentDark = Color(0xFF5E3A4E);
  static const Color accentLight = Color(0xFFD4C1CA);

  static const Color textDark  = Color(0xFF1A1A2E);
  static const Color textMid   = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border    = Color(0xFFE5E7EB);
  static const Color fieldBg   = Color(0xFFF3F4F6);
  static const Color cardShadow = Color(0x0D1A1A2E);

  static const Color primary    = accent;
  static const Color secondary  = accentDark;
  static const Color background = bg;
  static const Color textPrimary   = textDark;
  static const Color textSecondary = textMid;

  // Backward-compatible
  static const Color obsidian = textDark, steel = accentDark, midnight = textDark;
  static const Color gold = accent, scarlet = accent, mahogany = accent;
  static const Color mauveShadow = accentDark, dustyMauve = accent;
  static const Color petal = accentLight, mocha = accentDark, coffee = textDark;
  static const Color mist = bg, iron = textMid, slate = textMid;
  static const Color cream = bg, concrete = bg, bone = border;
  static const Color darkBrown = textDark, crimson = accent, tan = border, offWhite = bg;
}

/// Theme-aware color set. Access via `context.c` extension.
class AppColorTheme extends ThemeExtension<AppColorTheme> {
  final Color bg;
  final Color surface;
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Color textDark;
  final Color textMid;
  final Color textLight;
  final Color border;
  final Color fieldBg;
  final Color cardShadow;

  const AppColorTheme({
    required this.bg,
    required this.surface,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.textDark,
    required this.textMid,
    required this.textLight,
    required this.border,
    required this.fieldBg,
    required this.cardShadow,
  });

  // Legacy aliases
  Color get darkBrown => textDark;
  Color get crimson   => accent;
  Color get tan       => border;
  Color get offWhite  => bg;

  static AppColorTheme light({required Color accent}) {
    final hsl = HSLColor.fromColor(accent);
    return AppColorTheme(
      bg: const Color(0xFFF4F5F7),
      surface: Colors.white,
      accent: accent,
      accentDark: hsl.withLightness((hsl.lightness - 0.15).clamp(0.1, 0.9)).toColor(),
      accentLight: hsl.withLightness(0.85).withSaturation(0.3).toColor(),
      textDark: const Color(0xFF1A1A2E),
      textMid: const Color(0xFF6B7280),
      textLight: const Color(0xFF9CA3AF),
      border: const Color(0xFFE5E7EB),
      fieldBg: const Color(0xFFF3F4F6),
      cardShadow: const Color(0x0D1A1A2E),
    );
  }

  static AppColorTheme dark({required Color accent}) {
    final hsl = HSLColor.fromColor(accent);
    return AppColorTheme(
      bg: const Color(0xFF121218),
      surface: const Color(0xFF1E1E2E),
      accent: accent,
      accentDark: hsl.withLightness(0.7).toColor(),
      accentLight: hsl.withLightness(0.25).withSaturation(0.3).toColor(),
      textDark: const Color(0xFFE5E7EB),
      textMid: const Color(0xFF9CA3AF),
      textLight: const Color(0xFF6B7280),
      border: const Color(0xFF2D2D3F),
      fieldBg: const Color(0xFF252535),
      cardShadow: const Color(0x33000000),
    );
  }

  @override
  AppColorTheme copyWith({
    Color? bg,
    Color? surface,
    Color? accent,
    Color? accentDark,
    Color? accentLight,
    Color? textDark,
    Color? textMid,
    Color? textLight,
    Color? border,
    Color? fieldBg,
    Color? cardShadow,
  }) =>
      AppColorTheme(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        accent: accent ?? this.accent,
        accentDark: accentDark ?? this.accentDark,
        accentLight: accentLight ?? this.accentLight,
        textDark: textDark ?? this.textDark,
        textMid: textMid ?? this.textMid,
        textLight: textLight ?? this.textLight,
        border: border ?? this.border,
        fieldBg: fieldBg ?? this.fieldBg,
        cardShadow: cardShadow ?? this.cardShadow,
      );

  @override
  AppColorTheme lerp(AppColorTheme? other, double t) {
    if (other is! AppColorTheme) return this;
    return AppColorTheme(
      bg: Color.lerp(this.bg, other.bg, t)!,
      surface: Color.lerp(this.surface, other.surface, t)!,
      accent: Color.lerp(this.accent, other.accent, t)!,
      accentDark: Color.lerp(this.accentDark, other.accentDark, t)!,
      accentLight: Color.lerp(this.accentLight, other.accentLight, t)!,
      textDark: Color.lerp(this.textDark, other.textDark, t)!,
      textMid: Color.lerp(this.textMid, other.textMid, t)!,
      textLight: Color.lerp(this.textLight, other.textLight, t)!,
      border: Color.lerp(this.border, other.border, t)!,
      fieldBg: Color.lerp(this.fieldBg, other.fieldBg, t)!,
      cardShadow: Color.lerp(this.cardShadow, other.cardShadow, t)!,
    );
  }
}

/// Quick access to the theme-aware color set from any widget.
extension AppColorsX on BuildContext {
  AppColorTheme get c => Theme.of(this).extension<AppColorTheme>()!;
}
