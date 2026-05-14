import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/law_report_issue_field_group.dart';
import 'package:clair/features/auth/presentation/widgets/report_categories_localized.dart';
import 'package:clair/l10n/app_localizations.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final GlobalKey<LawReportIssueFieldGroupState> _fieldsKey =
      GlobalKey<LawReportIssueFieldGroupState>();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    if (_submitted) return _SuccessView(cl: cl, l10n: l10n);

    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.reportScreenTitle,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: cl.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cl.border),
                boxShadow: [
                  BoxShadow(
                      color: cl.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cl.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.flag_outlined,
                            color: cl.accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.reportScreenHeroTitle,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: cl.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.reportScreenHeroBody,
                    style: GoogleFonts.nunito(
                        fontSize: 13, height: 1.5, color: cl.textMid),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: cl.border),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: cl.textLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.reportScreenAnonymousNote,
                          style: GoogleFonts.nunito(
                              fontSize: 11.5, color: cl.textLight, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _StepLabel(number: '1', label: l10n.reportIssueCategoryStep, cl: cl),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              decoration: BoxDecoration(
                color: cl.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cl.border),
              ),
              child: LawReportIssueFieldGroup(
                key: _fieldsKey,
                showIntro: false,
                categories: appReportCategoriesFor(l10n),
                explanationHint: l10n.reportDescribeIssueHint,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cl.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cl.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 15, color: cl.textLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.reportPrivacyNoteBody,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: cl.textMid, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cl.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final st = _fieldsKey.currentState;
                  if (st == null || !st.validateReport()) return;
                  setState(() => _submitted = true);
                },
                child: Text(
                  l10n.reportSubmitButton,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.label,
    required this.cl,
  });
  final String number;
  final String label;
  final AppColorTheme cl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: cl.accent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cl.textDark,
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.cl, required this.l10n});
  final AppColorTheme cl;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cl.bg,
      appBar: AppBar(
        backgroundColor: cl.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cl.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.check_rounded, size: 36, color: cl.accent),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.reportSuccessTitle,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cl.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.reportSuccessBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 14, height: 1.5, color: cl.textMid),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cl.accent,
                    side: BorderSide(color: cl.accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.reportBackToSettings,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
