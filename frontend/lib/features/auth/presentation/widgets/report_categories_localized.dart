import 'package:flutter/material.dart';

import 'package:clair/l10n/app_localizations.dart';

/// Stable English IDs are stored with reports/shares; labels/descriptions follow UI locale.
class LawReportCategory {
  const LawReportCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
  final String id;
  final String label;
  final String description;
  final IconData icon;
}

List<LawReportCategory> lawReportCategoriesFor(AppLocalizations l) => [
      LawReportCategory(
        id: 'Bad Legal Information',
        label: l.reportLawBadLegalLabel,
        description: l.reportLawBadLegalDesc,
        icon: Icons.gavel_rounded,
      ),
      LawReportCategory(
        id: 'Outdated Law or Regulation',
        label: l.reportLawOutdatedLabel,
        description: l.reportLawOutdatedDesc,
        icon: Icons.history_edu_rounded,
      ),
      LawReportCategory(
        id: 'Misleading Interpretation',
        label: l.reportLawMisleadingLabel,
        description: l.reportLawMisleadingDesc,
        icon: Icons.balance_rounded,
      ),
      LawReportCategory(
        id: 'Wrong Jurisdiction',
        label: l.reportLawJurisdictionLabel,
        description: l.reportLawJurisdictionDesc,
        icon: Icons.public_rounded,
      ),
      LawReportCategory(
        id: 'Missing Legal Context',
        label: l.reportLawMissingContextLabel,
        description: l.reportLawMissingContextDesc,
        icon: Icons.info_outline_rounded,
      ),
      LawReportCategory(
        id: 'Potentially Harmful Advice',
        label: l.reportLawHarmfulLabel,
        description: l.reportLawHarmfulDesc,
        icon: Icons.warning_amber_rounded,
      ),
      LawReportCategory(
        id: 'Unclear or Confusing Response',
        label: l.reportLawUnclearLabel,
        description: l.reportLawUnclearDesc,
        icon: Icons.help_outline_rounded,
      ),
      LawReportCategory(
        id: 'Other Legal Concern',
        label: l.reportLawOtherLabel,
        description: l.reportLawOtherDesc,
        icon: Icons.more_horiz_rounded,
      ),
    ];

List<LawReportCategory> appReportCategoriesFor(AppLocalizations l) => [
      LawReportCategory(
        id: 'App Bug',
        label: l.reportAppBugLabel,
        description: l.reportAppBugDesc,
        icon: Icons.bug_report_outlined,
      ),
      LawReportCategory(
        id: 'Wrong AI Response',
        label: l.reportAppWrongAiLabel,
        description: l.reportAppWrongAiDesc,
        icon: Icons.psychology_outlined,
      ),
      LawReportCategory(
        id: 'Misleading Content',
        label: l.reportAppMisleadingLabel,
        description: l.reportAppMisleadingDesc,
        icon: Icons.warning_amber_outlined,
      ),
      LawReportCategory(
        id: 'Privacy or Security Concern',
        label: l.reportAppPrivacyLabel,
        description: l.reportAppPrivacyDesc,
        icon: Icons.security_outlined,
      ),
      LawReportCategory(
        id: 'Feature Feedback',
        label: l.reportAppFeatureLabel,
        description: l.reportAppFeatureDesc,
        icon: Icons.lightbulb_outline_rounded,
      ),
      LawReportCategory(
        id: 'Other',
        label: l.reportAppOtherLabel,
        description: l.reportAppOtherDesc,
        icon: Icons.more_horiz_rounded,
      ),
    ];
