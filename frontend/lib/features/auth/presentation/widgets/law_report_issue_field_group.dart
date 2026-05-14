import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/report_categories_localized.dart';
import 'package:clair/l10n/app_localizations.dart';

/// Shared reporting fields — category radio cards + required explanation textarea.
class LawReportIssueFieldGroup extends StatefulWidget {
  const LawReportIssueFieldGroup({
    super.key,
    this.messageExcerpt,
    this.explanationHint,
    this.showIntro = true,
    required this.categories,
  });

  final String? messageExcerpt;
  final String? explanationHint;
  final bool showIntro;
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
  void didUpdateWidget(LawReportIssueFieldGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.categories.any((c) => c.id == _category.id)) {
      _category = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _explain.dispose();
    super.dispose();
  }

  /// Stable English category label used in payloads (unchanged across locales).
  String get category => _category.id;

  String get explanationText => _explain.text.trim();

  bool validateReport() => _formKey.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.messageExcerpt != null &&
              widget.messageExcerpt!.trim().isNotEmpty) ...[
            _sectionLabel(cl, l10n.reportFieldContentReported),
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
          if (widget.showIntro) ...[
            _sectionLabel(cl, l10n.reportFieldChooseQuestionLegal),
            const SizedBox(height: 4),
            Text(
              l10n.reportFieldChooseCategoryLegalIntro,
              style: GoogleFonts.nunito(
                  fontSize: 12, color: cl.textMid, height: 1.35),
            ),
            const SizedBox(height: 12),
          ] else ...[
            _sectionLabel(cl, l10n.reportFieldIssueCategory),
            const SizedBox(height: 10),
          ],
          ...widget.categories.map((cat) {
            final sel = _category.id == cat.id;
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
          _sectionLabel(cl, l10n.reportFieldYourExplanation),
          const SizedBox(height: 4),
          Text(
            l10n.reportFieldExplanationBlurb,
            style: GoogleFonts.nunito(
                fontSize: 12, color: cl.textMid, height: 1.35),
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
              hintText:
                  widget.explanationHint ?? l10n.reportHintBriefConcern,
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
                return l10n.reportValidationExplanationShort;
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
