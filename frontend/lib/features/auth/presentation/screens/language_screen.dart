import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/locale/app_locale_provider.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/l10n/app_localizations.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(appLocaleProvider).languageCode;

    Future<void> pick(String code) async {
      await ref.read(appLocaleProvider.notifier).setLanguageCode(code);
      if (!context.mounted) return;
      final updated = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.languageUpdatedSnackbar,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: cl.textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.languageScreenTitle,
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
              const SizedBox(height: 20),
              Text(
                l10n.languageScreenSubtitle,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  height: 1.45,
                  color: cl.textMid,
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                child: Column(
                  children: [
                    _tile(
                      context,
                      label: l10n.languageEnglish,
                      selected: current == 'en',
                      onTap: () => pick('en'),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: cl.border),
                    _tile(
                      context,
                      label: l10n.languageFilipino,
                      selected: current == 'fil',
                      onTap: () => pick('fil'),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: cl.border),
                    _tile(
                      context,
                      label: l10n.languageCebuano,
                      selected: current == 'ceb',
                      onTap: () => pick('ceb'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cl = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cl.textDark,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: cl.accent, size: 22)
              else
                Icon(Icons.circle_outlined, color: cl.textLight, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
