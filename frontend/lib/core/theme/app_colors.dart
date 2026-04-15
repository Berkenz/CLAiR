import 'package:flutter/material.dart';

/// Modern minimal palette — clean whites, subtle gradients, dusty mauve accent.
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
