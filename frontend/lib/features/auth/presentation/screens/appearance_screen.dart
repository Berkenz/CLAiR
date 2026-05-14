import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/theme/appearance_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _modeIcons = [
    Icons.light_mode_rounded,
    Icons.dark_mode_rounded,
    Icons.settings_suggest_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cl.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cl.cardShadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: cl.textDark, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.appearance,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Theme mode ────────────────────────────────────
                    Text(l10n.appearanceSectionTheme,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cl.textMid)),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.only(right: i < 2 ? 10 : 0),
                            child: GestureDetector(
                              onTap: () => notifier.setThemeMode(i),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                decoration: BoxDecoration(
                                  color: state.themeMode == i
                                      ? state.accent
                                          .withValues(alpha: 0.08)
                                      : cl.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                    color: state.themeMode == i
                                        ? state.accent
                                        : cl.border,
                                    width:
                                        state.themeMode == i ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cl.cardShadow,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _modeIcons[i],
                                      size: 24,
                                      color: state.themeMode == i
                                          ? state.accent
                                          : cl.textMid,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      [
                                        l10n.appearanceThemeLight,
                                        l10n.appearanceThemeDark,
                                        l10n.appearanceThemeSystem,
                                      ][i],
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight:
                                            state.themeMode == i
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color: state.themeMode == i
                                            ? state.accent
                                            : cl.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Accent color ──────────────────────────────────
                    const SizedBox(height: 32),
                    Text(l10n.appearanceAccentColor,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cl.textMid)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(accentOptions.length, (i) {
                        final (label, color) = accentOptions[i];
                        final sel = state.accentIdx == i;
                        return GestureDetector(
                          onTap: () => notifier.setAccentIdx(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? color.withValues(alpha: 0.1)
                                  : cl.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: sel ? color : cl.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel
                                        ? color
                                        : cl.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // ── Font size ─────────────────────────────────────
                    const SizedBox(height: 32),
                    Text(l10n.appearanceFontSize,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cl.textMid)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cl.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cl.border),
                        boxShadow: [
                          BoxShadow(
                            color: cl.cardShadow,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text('A',
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cl.textMid)),
                          Expanded(
                            child: Slider(
                              value: state.fontScale,
                              min: 0.8,
                              max: 1.4,
                              divisions: 3,
                              activeColor: state.accent,
                              inactiveColor: cl.border,
                              onChanged: (v) => notifier.setFontScale(v),
                            ),
                          ),
                          Text('A',
                              style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: cl.textDark)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _fontLabel(l10n, state.fontScale),
                        style: GoogleFonts.nunito(
                            fontSize: 12, color: cl.textLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Save button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: GestureDetector(
                onTap: () async {
                  await notifier.save();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.appearanceSavedSnackbar,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: state.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: state.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: state.accent.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      l10n.appearanceSaveButton,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fontLabel(AppLocalizations l, double scale) {
    if (scale <= 0.85) return l.appearanceFontSmall;
    if (scale <= 1.05) return l.appearanceFontDefault;
    if (scale <= 1.25) return l.appearanceFontLarge;
    return l.appearanceFontExtraLarge;
  }
}
