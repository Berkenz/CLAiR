import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/shared/data/chat_history.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historyProvider.notifier).loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == 2) {
        ref.read(historyProvider.notifier).loadConversations();
      }
    });

    final historyState = ref.watch(historyProvider);

    ref.listen<HistoryState>(historyProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(historyProvider.notifier).clearError();
      }
    });

    final savedChats = sharedChatHistory.where((c) => c.saved).toList();

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cl.surface, cl.bg],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    'Library',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                    ),
                  ),
                ),
                _buildSegmentControl(
                  historyState.conversations.length,
                  savedChats.length,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _segment == 0
                        ? KeyedSubtree(
                            key: const ValueKey('history'),
                            child: _buildHistoryContent(historyState),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('saved'),
                            child: _buildSavedContent(savedChats),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Segment control ───────────────────────────────────────────────

  Widget _buildSegmentControl(int historyCount, int savedCount) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cl.fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _segmentTab('History', historyCount, 0, Icons.history_rounded),
            _segmentTab('Saved', savedCount, 1, Icons.bookmark_rounded),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab(String label, int count, int index, IconData icon) {
    final cl = context.c;
    final active = _segment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? cl.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: cl.cardShadow,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16,
                    color: active ? cl.accent : cl.textLight),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? cl.textDark : cl.textLight,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: active
                          ? cl.accent.withValues(alpha: 0.1)
                          : cl.textLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? cl.accent : cl.textLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── History content ───────────────────────────────────────────────

  Widget _buildHistoryContent(HistoryState state) {
    final cl = context.c;
    if (state.isLoading && state.conversations.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }
    if (state.conversations.isEmpty) return _buildHistoryEmpty();

    return RefreshIndicator(
      color: cl.accent,
      onRefresh: () => ref.read(historyProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: state.conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _historyCard(state.conversations[i]),
      ),
    );
  }

  Widget _historyCard(ConversationEntity conversation) {
    final cl = context.c;
    final dateStr =
        _formatDate(conversation.updatedAt ?? conversation.createdAt);

    return GestureDetector(
      onTap: () => _openConversation(conversation),
      onLongPress: () => _showCardOptions(conversation),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (conversation.isPinned)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 16,
                  color: cl.accent.withValues(alpha: 0.5),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cl.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last message: $dateStr',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: cl.textMid,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(historyProvider.notifier).togglePin(conversation.id),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  conversation.isPinned
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: conversation.isPinned
                      ? const Color(0xFFE9A020)
                      : cl.textLight,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showCardOptions(conversation),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_vert_rounded,
                    size: 20, color: cl.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardOptions(ConversationEntity conversation) {
    final cl = context.c;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cl.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cl.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: cl.border, height: 1),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cl.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: cl.accent),
              ),
              title: Text('Rename',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cl.textDark)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(conversation);
              },
            ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red.shade700),
              ),
              title: Text('Delete',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(conversation);
              },
            ),
            SizedBox(
                height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEmpty() {
    final cl = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: cl.fieldBg, shape: BoxShape.circle),
            child: Icon(Icons.history_rounded,
                size: 28, color: cl.textLight),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a chat and your conversations\nwill appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
          ),
        ],
      ),
    );
  }

  // ─── Saved content ─────────────────────────────────────────────────

  Widget _buildSavedContent(List<ChatEntry> saved) {
    if (saved.isEmpty) return _buildSavedEmpty();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: saved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _savedCard(saved[i]),
    );
  }

  Widget _savedCard(ChatEntry c) {
    final cl = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.border),
        boxShadow: [
          BoxShadow(
            color: cl.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE9A020),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cl.textDark)),
                const SizedBox(height: 4),
                Text(c.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        GoogleFonts.nunito(fontSize: 12, color: cl.textMid)),
                const SizedBox(height: 6),
                Text(c.date,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: cl.textLight)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => c.saved = false),
            child: const Icon(Icons.bookmark_rounded,
                size: 20, color: Color(0xFFE9A020)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedEmpty() {
    final cl = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: cl.fieldBg, shape: BoxShape.circle),
            child: Icon(Icons.bookmark_outline_rounded,
                size: 28, color: cl.textLight),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved chats',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bookmark chats to find\nthem easily later',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
          ),
        ],
      ),
    );
  }

  // ─── Shared actions ────────────────────────────────────────────────

  void _openConversation(ConversationEntity conversation) {
    ref.read(chatProvider.notifier).loadConversation(
          conversation.id,
          title: conversation.title,
          isPinned: conversation.isPinned,
        );
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _showRenameDialog(ConversationEntity conversation) {
    final cl = context.c;
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rename conversation',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: GoogleFonts.nunito(),
          decoration: InputDecoration(
            hintText: 'Enter new title',
            hintStyle: GoogleFonts.nunito(color: cl.textLight),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cl.accent, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: cl.textMid)),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                ref
                    .read(historyProvider.notifier)
                    .renameConversation(conversation.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text('Rename',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: cl.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ConversationEntity conversation) {
    final cl = context.c;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete conversation?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete this conversation and all its messages.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: cl.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(historyProvider.notifier)
                  .deleteConversation(conversation.id);
            },
            child: Text('Delete',
                style: GoogleFonts.nunito(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMMM d, y').format(date);
  }
}
