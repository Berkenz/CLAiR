import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/law_report_issue_field_group.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
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

  LawyerEntity get lawyer => widget.lawyer;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

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
                      Text('Report a concern',
                          style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: cl.textDark)),
                      const SizedBox(height: 2),
                      Text('About: ${lawyer.name}',
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
                messageExcerpt: null,
                showIntro: true,
              ),
              const SizedBox(height: 22),
              SpringButton(
                onTap: () async {
                  final st = _fieldsKey.currentState;
                  if (st == null || !st.validateReport()) return;

                  final payload = 'CLAiR — Lawyer concern\n'
                      'Lawyer: ${lawyer.name}\n'
                      'Profile ID: ${lawyer.id}\n\n'
                      'Category: ${st.category}\n\n'
                      '${st.explanationText.trim()}';

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);

                  await SharePlus.instance.share(
                    ShareParams(
                      text: payload,
                      subject: 'CLAiR lawyer concern — ${lawyer.name}',
                    ),
                  );

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Report shared via share sheet.',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600)),
                      backgroundColor: cl.textDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                      color: cl.accent,
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text('Submit report',
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
