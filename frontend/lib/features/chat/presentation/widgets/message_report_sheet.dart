import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/widgets/law_report_issue_field_group.dart';
import 'package:clair/features/auth/presentation/widgets/report_categories_localized.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';

void showMessageReportSheet(
  BuildContext context, {
  required ChatMessageEntity message,
  required int messageIndex,
}) {
  final excerpt =
      message.text.length > 800 ? '${message.text.substring(0, 800)}…' : message.text;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MessageReportSheet(
        excerpt: excerpt,
        messageIndex: messageIndex,
      );
    },
  );
}

class _MessageReportSheet extends ConsumerStatefulWidget {
  const _MessageReportSheet({
    required this.excerpt,
    required this.messageIndex,
  });

  final String excerpt;
  final int messageIndex;

  @override
  ConsumerState<_MessageReportSheet> createState() => _MessageReportSheetState();
}

class _MessageReportSheetState extends ConsumerState<_MessageReportSheet> {
  final GlobalKey<LawReportIssueFieldGroupState> _fieldsKey =
      GlobalKey<LawReportIssueFieldGroupState>();
  bool _submitting = false;

  Future<void> _submitReport(
    BuildContext context,
    WidgetRef ref,
    AppColorTheme cl,
  ) async {
    final st = _fieldsKey.currentState;
    if (st == null || !st.validateReport()) return;

    setState(() => _submitting = true);

    final chatState = ref.read(chatProvider);
    final messages = [...chatState.messages];

    if (widget.messageIndex >= 0 && widget.messageIndex < messages.length) {
      final m = messages[widget.messageIndex];
      messages[widget.messageIndex] = m.copyWith(feedback: 'dislike');
      ref.read(chatProvider.notifier).updateMessages(messages);
    }

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.reportConversation(
        category: st.category,
        explanation: st.explanationText,
        messages: chatState.messages,
        conversationId: chatState.conversationId,
        reportedMessageExcerpt: widget.excerpt,
      );
    } catch (_) {
      // Best-effort — snackbar still thanks the user.
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thanks — your report was sent.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cl.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cl.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reportReplySheetTitle,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cl.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.reportReplySheetSubtitle,
                          style: GoogleFonts.nunito(fontSize: 12, color: cl.textMid),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: cl.textMid),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LawReportIssueFieldGroup(
                      key: _fieldsKey,
                      categories: lawReportCategoriesFor(l10n),
                      messageExcerpt: widget.excerpt,
                      explanationHint: l10n.reportReplyExplainHint,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cl.textMid,
                              side: BorderSide(color: cl.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.commonCancel,
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cl.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submitting
                                ? null
                                : () => _submitReport(context, ref, cl),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.commonSubmit,
                                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
