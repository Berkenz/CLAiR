import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';

/// A single report category option.
class LawReportCategory {
  const LawReportCategory({
    required this.label,
    required this.description,
    required this.icon,
  });
  final String label;
  final String description;
  final IconData icon;
}

/// Law-focused categories — used for chat message reports and lawyer concern reports.
const kLawReportCategories = <LawReportCategory>[
  LawReportCategory(
    label: 'Bad Legal Information',
    description: 'The response contains factually incorrect laws, cases, or statutes.',
    icon: Icons.gavel_rounded,
  ),
  LawReportCategory(
    label: 'Outdated Law or Regulation',
    description: 'The cited law has been amended, repealed, or superseded.',
    icon: Icons.history_edu_rounded,
  ),
  LawReportCategory(
    label: 'Misleading Interpretation',
    description: 'Legal reasoning is skewed, incomplete, or taken out of context.',
    icon: Icons.balance_rounded,
  ),
  LawReportCategory(
    label: 'Wrong Jurisdiction',
    description: 'Laws from a different country, state, or region were applied.',
    icon: Icons.public_rounded,
  ),
  LawReportCategory(
    label: 'Missing Legal Context',
    description: 'Key exceptions, conditions, or legal nuances were omitted.',
    icon: Icons.info_outline_rounded,
  ),
  LawReportCategory(
    label: 'Potentially Harmful Advice',
    description: 'Following this advice could cause legal harm or risk.',
    icon: Icons.warning_amber_rounded,
  ),
  LawReportCategory(
    label: 'Unclear or Confusing Response',
    description: 'The answer is too vague or difficult to apply in a legal context.',
    icon: Icons.help_outline_rounded,
  ),
  LawReportCategory(
    label: 'Other Legal Concern',
    description: 'A concern not described by any category above.',
    icon: Icons.more_horiz_rounded,
  ),
];

/// App-level categories for the Settings › Report screen.
const kAppReportCategories = <LawReportCategory>[
  LawReportCategory(
    label: 'App Bug',
    description: 'Something in the app is broken or behaving incorrectly.',
    icon: Icons.bug_report_outlined,
  ),
  LawReportCategory(
    label: 'Wrong AI Response',
    description: 'CLAiR gave an inaccurate, irrelevant, or harmful answer.',
    icon: Icons.psychology_outlined,
  ),
  LawReportCategory(
    label: 'Misleading Content',
    description: 'Information was deceptive or presented out of context.',
    icon: Icons.warning_amber_outlined,
  ),
  LawReportCategory(
    label: 'Privacy or Security Concern',
    description: 'An issue related to how your data is handled or stored.',
    icon: Icons.security_outlined,
  ),
  LawReportCategory(
    label: 'Feature Feedback',
    description: 'Suggestions for new features or improvements to the app.',
    icon: Icons.lightbulb_outline_rounded,
  ),
  LawReportCategory(
    label: 'Other',
    description: 'An issue not covered by any of the categories above.',
    icon: Icons.more_horiz_rounded,
  ),
];

/// Shared reporting fields — category radio cards + required explanation textarea.
class LawReportIssueFieldGroup extends StatefulWidget {
  const LawReportIssueFieldGroup({
    super.key,
    this.messageExcerpt,
    this.explanationHint = 'Briefly explain what is wrong or concerning…',
    this.showIntro = true,
    this.categories = kLawReportCategories,
  });

  final String? messageExcerpt;
  final String explanationHint;
  final bool showIntro;
  /// Override to show a different set of categories (e.g. [kAppReportCategories]).
  final List<LawReportCategory> categories;

  @override
  LawReportIssueFieldGroupState createState() => LawReportIssueFieldGroupState();
}

class LawReportIssueFieldGroupState extends State<LawReportIssueFieldGroup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _explain;

  late LawReportCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.categories.first;
    _explain = TextEditingController();
  }

  @override
  void dispose() {
    _explain.dispose();
    super.dispose();
  }

  String get category => _category.label;
  String get explanationText => _explain.text.trim();

  bool validateReport() => _formKey.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Excerpt preview ─────────────────────────────────────────────────
          if (widget.messageExcerpt != null &&
              widget.messageExcerpt!.trim().isNotEmpty) ...[
            _sectionLabel(cl, 'Content being reported'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cl.fieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cl.border),
              ),
              child: Text(
                widget.messageExcerpt!,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 13, height: 1.45, color: cl.textDark),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Category ────────────────────────────────────────────────────────
          if (widget.showIntro) ...[
            _sectionLabel(cl, 'What best describes this issue?'),
            const SizedBox(height: 4),
            Text(
              'Choose the category that closest matches the legal concern.',
              style:
                  GoogleFonts.nunito(fontSize: 12, color: cl.textMid, height: 1.35),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _sectionLabel(cl, 'Issue category'),
            const SizedBox(height: 10),
          ],

          ...widget.categories.map((cat) {
            final sel = _category == cat;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CategoryCard(
                cat: cat,
                selected: sel,
                onTap: () => setState(() => _category = cat),
              ),
            );
          }),

          const SizedBox(height: 24),

          // ── Explanation ──────────────────────────────────────────────────────
          _sectionLabel(cl, 'Your explanation'),
          const SizedBox(height: 4),
          Text(
            'A short explanation is required so our team can understand the issue.',
            style:
                GoogleFonts.nunito(fontSize: 12, color: cl.textMid, height: 1.35),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _explain,
            minLines: 5,
            maxLines: 9,
            maxLength: 2000,
            style: GoogleFonts.nunito(
                color: cl.textDark, fontSize: 14, height: 1.45),
            decoration: InputDecoration(
              hintText: widget.explanationHint,
              hintStyle:
                  GoogleFonts.nunito(color: cl.textLight, fontSize: 13),
              filled: true,
              fillColor: cl.surface,
              counterStyle:
                  GoogleFonts.nunito(fontSize: 11, color: cl.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cl.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cl.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cl.accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 12) {
                return 'Please add a short explanation (at least a sentence).';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColorTheme cl, String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cl.textMid,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  final LawReportCategory cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Material(
      color: selected ? cl.accent.withValues(alpha: 0.06) : cl.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cl.accent : cl.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? cl.accent.withValues(alpha: 0.12)
                      : cl.fieldBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  cat.icon,
                  size: 18,
                  color: selected ? cl.accent : cl.textMid,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.label,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: cl.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.description,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        height: 1.35,
                        color: cl.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? cl.accent : cl.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
