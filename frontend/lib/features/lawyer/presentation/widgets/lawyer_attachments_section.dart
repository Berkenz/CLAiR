import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';

/// Attachment section for lawyer booking forms.
///
/// Lets the user attach:
///  • current CLAiR conversation (toggle) – shows title + date
///  • a past conversation chosen from History ("Change / From history" button)
///  • local files (multi-pick)
///
/// [onSummaryGenerated] is called with auto-generated text when the user
/// taps "Summarize with AI" so the parent can fill a description field.
///
/// Pass [initialConversationId] / [initialConversationTitle] to pre-attach
/// a conversation when the sheet opens (e.g. in "Share to Lawyer" mode).
class LawyerAttachmentsSection extends ConsumerStatefulWidget {
  const LawyerAttachmentsSection({
    super.key,
    required this.attachConversation,
    required this.onAttachConversationChanged,
    required this.pickedFiles,
    required this.onPickedFilesChanged,
    this.onSummaryGenerated,
    this.initialConversationId,
    this.initialConversationTitle,
    this.onAttachedConversationSelectionChanged,
  });

  final bool attachConversation;
  final ValueChanged<bool> onAttachConversationChanged;
  final List<PlatformFile> pickedFiles;
  final ValueChanged<List<PlatformFile>> onPickedFilesChanged;

  /// Called with a summary string so the parent can pre-fill a description.
  final ValueChanged<String>? onSummaryGenerated;

  /// Pre-select a history conversation on first render (null = current chat).
  final String? initialConversationId;
  final String? initialConversationTitle;

  /// Fired when the explicit attach target changes; [id] null means use live chat.
  final void Function(String? id, String? title)?
      onAttachedConversationSelectionChanged;

  @override
  ConsumerState<LawyerAttachmentsSection> createState() =>
      _LawyerAttachmentsSectionState();
}

class _LawyerAttachmentsSectionState
    extends ConsumerState<LawyerAttachmentsSection> {
  /// Non-null when the user chose a past conversation. null = current chat.
  String? _selectedConvId;
  String? _selectedConvTitle;
  bool _summarising = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialConversationId != null ||
        widget.initialConversationTitle != null) {
      _selectedConvId = widget.initialConversationId;
      _selectedConvTitle = widget.initialConversationTitle;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyAttachedSelection();
    });
  }

  @override
  void didUpdateWidget(LawyerAttachmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final initialChanged =
        widget.initialConversationId != oldWidget.initialConversationId ||
            widget.initialConversationTitle != oldWidget.initialConversationTitle;
    if (initialChanged &&
        (widget.initialConversationId != null ||
            widget.initialConversationTitle != null)) {
      _selectedConvId = widget.initialConversationId;
      _selectedConvTitle = widget.initialConversationTitle;
      _scheduleNotifyAttachedSelection();
    }
    if (widget.attachConversation != oldWidget.attachConversation) {
      _scheduleNotifyAttachedSelection();
    }
  }

  /// Must not call [onAttachedConversationSelectionChanged] synchronously from
  /// [didUpdateWidget] — the parent often updates attach state in the same build.
  void _scheduleNotifyAttachedSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifyAttachedSelection();
    });
  }

  void _notifyAttachedSelection() {
    widget.onAttachedConversationSelectionChanged?.call(
      _selectedConvId,
      _selectedConvTitle,
    );
  }

  // ── File helpers ───────────────────────────────────────────────────────────

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return;
    final merged = [...widget.pickedFiles];
    for (final f in res.files) {
      if (f.name.isEmpty) continue;
      if (!merged.any((x) => x.name == f.name && x.size == f.size)) {
        merged.add(f);
      }
    }
    widget.onPickedFilesChanged(merged);
  }

  void _removeFile(int i) {
    widget.onPickedFilesChanged([...widget.pickedFiles]..removeAt(i));
  }

  // ── History picker ─────────────────────────────────────────────────────────

  void _showHistoryPicker(BuildContext ctx) {
    ref.read(historyProvider.notifier).loadConversations();
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryPickerSheet(
        onSelected: (id, title) {
          setState(() {
            _selectedConvId = id;
            _selectedConvTitle = title;
          });
          _notifyAttachedSelection();
          if (!widget.attachConversation) {
            widget.onAttachConversationChanged(true);
          }
        },
      ),
    );
  }

  // ── Summarise ──────────────────────────────────────────────────────────────

  Future<void> _summarise() async {
    setState(() => _summarising = true);
    try {
      List<ChatMessageEntity> messages;
      String title;

      if (_selectedConvId != null) {
        final repo = ref.read(historyRepositoryProvider);
        messages = await repo.getConversationMessages(_selectedConvId!);
        title = _selectedConvTitle ?? 'Conversation';
      } else {
        final chat = ref.read(chatProvider);
        messages = chat.messages;
        title = _selectedConvTitle ??
            chat.conversationTitle ??
            'Current chat';
      }

      widget.onSummaryGenerated?.call(_buildSummary(messages, title));
    } catch (_) {
      // silently fail — user can type manually
    } finally {
      if (mounted) setState(() => _summarising = false);
    }
  }

  String _buildSummary(List<ChatMessageEntity> msgs, String title) {
    // Skip the greeting message (first AI message).
    final userMsgs = msgs.where((m) => m.isUser).toList();
    final aiMsgs = msgs
        .where((m) => !m.isUser && m.text.trim().isNotEmpty)
        .skip(1) // skip greeting
        .toList();

    final buf = StringBuffer();

    // ── Header ──
    buf.writeln('I am seeking legal consultation regarding the following '
        'matter that I discussed with CLAiR (AI Legal Assistant).');
    buf.writeln();
    buf.writeln('Conversation title: "$title"');
    buf.writeln();

    // ── My questions ──
    if (userMsgs.isNotEmpty) {
      buf.writeln('QUESTIONS / CONCERNS I RAISED:');
      for (final m in userMsgs.take(5)) {
        final t = m.text.trim();
        buf.writeln(
            '• ${t.length > 220 ? '${t.substring(0, 220)}…' : t}');
      }
      buf.writeln();
    }

    // ── AI responses ──
    if (aiMsgs.isNotEmpty) {
      buf.writeln('WHAT CLAiR ADVISED:');
      // Summarise the first two substantive AI replies.
      for (final m in aiMsgs.take(2)) {
        final t = m.text.trim();
        // Strip markdown headers (##) for a cleaner legal summary.
        final clean = t.replaceAll(RegExp(r'^#{1,3} ', multiLine: true), '');
        buf.writeln(
            clean.length > 600 ? '${clean.substring(0, 600)}…' : clean);
        buf.writeln();
      }
    }

    // ── Request line ──
    buf.write('I would like professional legal advice and guidance '
        'on the above matter from a qualified lawyer.');

    return buf.toString().trimRight();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final chatState = ref.watch(chatProvider);
    final hasCurrentChat = chatState.messages.any((m) => m.isUser);

    // The effective conversation title to display.
    final convTitle = _selectedConvTitle ??
        (hasCurrentChat ? (chatState.conversationTitle ?? 'Current conversation') : null);

    // A specific conversation has been chosen (pre-attach or history pick).
    final hasSelection = _selectedConvId != null ||
        _selectedConvTitle != null ||
        widget.initialConversationId != null ||
        widget.initialConversationTitle != null;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(children: [
          Icon(Icons.attach_file_rounded, size: 15, color: cl.accent),
          const SizedBox(width: 6),
          Text(
            'Attachments',
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cl.textDark),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Attach a CLAiR conversation so the lawyer has full context.',
          style: GoogleFonts.nunito(
              fontSize: 12, color: cl.textMid, height: 1.35),
        ),
        const SizedBox(height: 14),

        // ── Conversation card ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: widget.attachConversation
                ? cl.accent.withValues(alpha: 0.04)
                : cl.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.attachConversation
                  ? cl.accent.withValues(alpha: 0.4)
                  : cl.border,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  // If no conversation available yet, open history picker first.
                  if (!hasCurrentChat && !hasSelection) {
                    _showHistoryPicker(context);
                  } else {
                    widget.onAttachConversationChanged(!widget.attachConversation);
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: widget.attachConversation,
                          onChanged: (v) {
                            if (!hasCurrentChat && !hasSelection) {
                              _showHistoryPicker(context);
                            } else {
                              widget.onAttachConversationChanged(v ?? false);
                            }
                          },
                          activeColor: cl.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attach CLAiR conversation',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cl.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (convTitle != null)
                              Text(
                                convTitle,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cl.accent,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                hasSelection
                                    ? 'Selected from history'
                                    : 'Tap to pick a conversation from your history',
                                style: GoogleFonts.nunito(
                                    fontSize: 11.5,
                                    color: cl.textMid,
                                    height: 1.35),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Always visible "From history" / "Change" button
                      GestureDetector(
                        onTap: () => _showHistoryPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cl.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cl.border),
                          ),
                          child: Text(
                            hasSelection ? 'Change' : 'From history',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cl.textMid,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Summarize with AI" — visible when conversation is checked and one is available
              if (widget.attachConversation &&
                  (hasCurrentChat || hasSelection) &&
                  widget.onSummaryGenerated != null) ...[
                Divider(height: 1, color: cl.border),
                InkWell(
                  onTap: _summarising ? null : _summarise,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_summarising)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cl.accent),
                          )
                        else
                          Icon(Icons.auto_awesome_rounded,
                              size: 15, color: cl.accent),
                        const SizedBox(width: 6),
                        Text(
                          _summarising
                              ? 'Generating summary…'
                              : 'Summarize with AI',
                          style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: cl.accent,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'fills description',
                          style: GoogleFonts.nunito(
                              fontSize: 10.5, color: cl.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── File attach button ───────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: _pickFiles,
          style: OutlinedButton.styleFrom(
            foregroundColor: cl.textMid,
            side: BorderSide(color: cl.border),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(Icons.upload_file_rounded, size: 17, color: cl.textMid),
          label: Text(
            'Attach file',
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),

        if (widget.pickedFiles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.pickedFiles.length, (i) {
              final f = widget.pickedFiles[i];
              return InputChip(
                label: Text(f.name,
                    style: GoogleFonts.nunito(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                avatar: Icon(Icons.insert_drive_file_rounded,
                    size: 14, color: cl.textMid),
                onDeleted: () => _removeFile(i),
                deleteIconColor: cl.textMid,
                backgroundColor: cl.surface,
                side: BorderSide(color: cl.border),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ── History picker sheet ──────────────────────────────────────────────────────

class _HistoryPickerSheet extends ConsumerWidget {
  const _HistoryPickerSheet({required this.onSelected});
  final void Function(String id, String title) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final histState = ref.watch(historyProvider);
    final convs = histState.conversations;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.65),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cl.cardShadow,
              blurRadius: 24,
              offset: const Offset(0, -4)),
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
                color: cl.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a conversation',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: cl.textMid),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cl.border),
          if (histState.isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: cl.accent),
            )
          else if (convs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No conversations found.',
                  style:
                      GoogleFonts.nunito(fontSize: 13, color: cl.textLight)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: convs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cl.border, indent: 56),
                itemBuilder: (ctx, i) {
                  final c = convs[i];
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(c.id, c.title);
                    },
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cl.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        c.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: cl.accent,
                      ),
                    ),
                    title: Text(c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cl.textDark)),
                    subtitle: c.lastMessage != null
                        ? Text(c.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 11.5, color: cl.textMid))
                        : null,
                    trailing: Icon(Icons.chevron_right_rounded,
                        size: 18, color: cl.textLight),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Utility ───────────────────────────────────────────────────────────────────

/// Appends conversation title and file references to the appointment description.
String appendAttachmentsToDescription(
  String userDescription,
  List<PlatformFile> files, {
  String? conversationTitle,
  int? conversationMessageCount,
}) {
  final buf = StringBuffer(userDescription.trim());

  if (conversationTitle != null) {
    buf.writeln();
    buf.writeln('---');
    buf.write('CLAiR conversation: "$conversationTitle"');
    if (conversationMessageCount != null) {
      buf.write(' ($conversationMessageCount messages)');
    }
    buf.writeln();
  }

  if (files.isNotEmpty) {
    buf.writeln();
    buf.writeln('---');
    buf.writeln('Attached files:');
    for (final f in files) { buf.writeln('• ${f.name}'); }
  }

  return buf.toString().trimRight();
}
