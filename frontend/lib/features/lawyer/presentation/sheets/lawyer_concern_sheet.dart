import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/law_report_issue_field_group.dart';
import 'package:clair/features/auth/presentation/widgets/report_categories_localized.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/spring_button.dart';

Future<void> showLawyerConcernSheet(BuildContext context, LawyerEntity lawyer) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => LawyerConcernSheet(lawyer: lawyer),
  );
}

class LawyerConcernSheet extends ConsumerStatefulWidget {
  const LawyerConcernSheet({super.key, required this.lawyer});
  final LawyerEntity lawyer;

  @override
  ConsumerState<LawyerConcernSheet> createState() =>
      _LawyerConcernSheetState();
}

class _LawyerConcernSheetState extends ConsumerState<LawyerConcernSheet> {
  final GlobalKey<LawReportIssueFieldGroupState> _fieldsKey =
      GlobalKey<LawReportIssueFieldGroupState>();
  bool _submitting = false;

  LawyerEntity get lawyer => widget.lawyer;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: cl.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, -4))
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.lawyerConcernTitle,
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: cl.textDark)),
                      const SizedBox(height: 2),
                      Text(l10n.lawyerConcernAbout(lawyer.name),
                          style: GoogleFonts.nunito(
                              fontSize: 12.5, color: cl.textMid)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: cl.textMid),
                ),
              ]),
              const SizedBox(height: 18),
              LawReportIssueFieldGroup(
                key: _fieldsKey,
                categories: userReportCategoriesFor(l10n),
                messageExcerpt: null,
                showIntro: true,
              ),
              const SizedBox(height: 22),
              SpringButton(
                onTap: _submitting
                    ? null
                    : () async {
                        final st = _fieldsKey.currentState;
                        if (st == null || !st.validateReport()) return;

                        setState(() => _submitting = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final repo = ref.read(chatRepositoryProvider);
                          await repo.reportUser(
                            reportedLawyerProfileId: lawyer.id,
                            category: st.category,
                            explanation: st.explanationText.trim(),
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Report submitted successfully.',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: cl.textDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _submitting = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit report: $e',
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                      color: _submitting
                          ? cl.accent.withValues(alpha: 0.6)
                          : cl.accent,
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white))
                        : Text(l10n.reportSubmitButton,
                            style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
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
