import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

final conversationPreviewProvider =
    FutureProvider.autoDispose.family<String, String>((ref, conversationId) async {
  final repository = ref.read(historyRepositoryProvider);
  final messages = await repository.getConversationMessages(conversationId);
  if (messages.isEmpty) {
    return 'Start a new message';
  }

  final latest = messages.last;
  final author = latest.isUser ? 'You' : 'CLAiR';
  final text = latest.text.trim().isNotEmpty ? latest.text.trim() : '...';
  return '$author: $text';
});

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _segment = 0;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(
      () => ref.read(historyProvider.notifier).loadConversations(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final searchQuery = _searchController.text.trim().toLowerCase();

    final allHistoryChats = historyState.conversations
      .toList()
      ..sort((a, b) => (b.updatedAt ?? b.createdAt)
        .compareTo(a.updatedAt ?? a.createdAt));

    final savedChats = historyState.conversations
        .where((c) => c.isPinned)
        .toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt));

    final filteredHistoryChats = searchQuery.isEmpty
      ? allHistoryChats
      : allHistoryChats
        .where((c) => c.title.toLowerCase().contains(searchQuery))
        .toList();

    final filteredSavedChats = searchQuery.isEmpty
      ? savedChats
      : savedChats
        .where((c) => c.title.toLowerCase().contains(searchQuery))
        .toList();

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
                  filteredHistoryChats.length,
                  filteredSavedChats.length,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: cl.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        hintStyle: GoogleFonts.nunito(fontSize: 13, color: cl.textLight),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: cl.textLight),
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: Icon(Icons.close_rounded, size: 18, color: cl.textLight),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _segment == 0
                        ? KeyedSubtree(
                            key: const ValueKey('history'),
                            child: _buildHistoryContent(historyState, filteredHistoryChats, searchQuery),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('saved'),
                            child: _buildSavedContent(filteredSavedChats, searchQuery),
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

  Widget _buildHistoryContent(
    HistoryState state,
    List<ConversationEntity> chats,
    String searchQuery,
  ) {
    final cl = context.c;
    if (state.isLoading && state.conversations.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }
    if (chats.isEmpty) {
      return searchQuery.isNotEmpty
          ? _buildSearchEmpty('history')
          : _buildHistoryEmpty();
    }

    return RefreshIndicator(
      color: cl.accent,
      onRefresh: () => ref.read(historyProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _historyCard(chats[i]),
      ),
    );
  }

  Widget _historyCard(ConversationEntity conversation) {
    final cl = context.c;
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final previewAsync = ref.watch(conversationPreviewProvider(conversation.id));
    final fallbackPreview = conversation.lastMessage?.trim().isNotEmpty == true
        ? 'Recent: ${conversation.lastMessage!.trim()}'
        : 'Start a new message';
    final lastMessagePreview = previewAsync.when(
      data: (value) => value,
      loading: () => fallbackPreview,
      error: (_, __) => fallbackPreview,
    );

    return GestureDetector(
      onTap: () => _openConversation(conversation),
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
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9A020),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (conversation.isPinned) const SizedBox(width: 14),
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
                    lastMessagePreview,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: cl.textMid,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateTimeStr,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: cl.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: cl.textLight,
              ),
              splashRadius: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: cl.surface,
              elevation: 4,
              onSelected: (value) => _handleCardMenuAction(value, conversation),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(
                        conversation.isPinned
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 18,
                        color: const Color(0xFFE9A020),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        conversation.isPinned ? 'Unsave' : 'Save',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: cl.textDark),
                      const SizedBox(width: 12),
                      Text(
                        'Rename',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18, color: cl.accent),
                      const SizedBox(width: 12),
                      Text(
                        'Share to Lawyer',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.accent),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: cl.textDark),
                      const SizedBox(width: 12),
                      Text(
                        'Download',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildSavedContent(List<ConversationEntity> saved, String searchQuery) {
    if (saved.isEmpty) {
      return searchQuery.isNotEmpty
          ? _buildSearchEmpty('saved')
          : _buildSavedEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: saved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _savedCard(saved[i]),
    );
  }

  Widget _savedCard(ConversationEntity conversation) {
    final cl = context.c;
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final previewAsync = ref.watch(conversationPreviewProvider(conversation.id));
    final fallbackPreview = conversation.lastMessage?.trim().isNotEmpty == true
        ? 'Recent: ${conversation.lastMessage!.trim()}'
        : 'Start a new message';
    final lastMessagePreview = previewAsync.when(
      data: (value) => value,
      loading: () => fallbackPreview,
      error: (_, __) => fallbackPreview,
    );

    return GestureDetector(
      onTap: () => _openConversation(conversation),
      child: Container(
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
                  Text(conversation.title,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cl.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(lastMessagePreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          GoogleFonts.nunito(fontSize: 12, color: cl.textMid)),
                  const SizedBox(height: 6),
                  Text(dateTimeStr,
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: cl.textLight)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: cl.textLight,
              ),
              splashRadius: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: cl.surface,
              elevation: 4,
              onSelected: (value) => _handleCardMenuAction(value, conversation),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded, size: 18, color: cl.textDark),
                      const SizedBox(width: 12),
                      Text(
                        'Unsave',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: cl.textDark),
                      const SizedBox(width: 12),
                      Text(
                        'Rename',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18, color: cl.accent),
                      const SizedBox(width: 12),
                      Text(
                        'Share to Lawyer',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.accent),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: cl.textDark),
                      const SizedBox(width: 12),
                      Text(
                        'Download',
                        style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildSearchEmpty(String segment) {
    final cl = context.c;
    final title = segment == 'saved' ? 'No saved chats found' : 'No chats found';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cl.fieldBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 28, color: cl.textLight),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword.',
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

  void _handleCardMenuAction(String value, ConversationEntity conversation) {
    switch (value) {
      case 'save':
        ref.read(historyProvider.notifier).togglePin(conversation.id);
        break;
      case 'rename':
        _showRenameDialog(conversation);
        break;
      case 'share':
        _shareToLawyer(conversation);
        break;
      case 'download':
        _downloadConversation(conversation);
        break;
      case 'delete':
        _confirmDelete(conversation);
        break;
    }
  }

  void _shareToLawyer(ConversationEntity conversation) {
    ref.read(lawyerSharingProvider.notifier).state = ConversationSharingData(
      title: conversation.title,
      conversationId: conversation.id,
    );
    // LibraryScreen is embedded in the main shell — just switch tabs.
    ref.read(mainShellTabProvider.notifier).state = 3;
  }

  Future<void> _downloadConversation(ConversationEntity conversation) async {
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating PDF...'),
        backgroundColor: cl.textDark,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      await ref.read(chatProvider.notifier).loadConversation(
            conversation.id,
            title: conversation.title,
            isPinned: conversation.isPinned,
          );

      final bytes = await ref.read(chatProvider.notifier).downloadPdf();
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final safeName =
          conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
      final file = File('${dir.path}/CLAiR_$safeName.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date.toLocal());
  }
}
