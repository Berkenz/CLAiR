import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/library/presentation/conversation_preview_line.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

final conversationPreviewProvider = FutureProvider.autoDispose
    .family<ConversationPreviewLine, String>((ref, conversationId) async {
  final repository = ref.read(historyRepositoryProvider);
  final messages = await repository.getConversationMessages(conversationId);
  return ConversationPreviewLine.fromMessages(messages);
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _segment = 0;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      ref.read(historyProvider.notifier).clearSearch();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(historyProvider.notifier).searchConversations(trimmed);
    });
  }

  List<ConversationEntity> _conversationsForSearch(
    HistoryState historyState,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return historyState.conversations;
    if (historyState.activeSearchQuery != searchQuery) return const [];
    return historyState.searchResults ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
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

    final searchQuery = _searchController.text.trim();

    final allHistoryChats = historyState.conversations
      .toList()
      ..sort((a, b) => (b.updatedAt ?? b.createdAt)
        .compareTo(a.updatedAt ?? a.createdAt));

    final savedChats = historyState.conversations
        .where((c) => c.isPinned)
        .toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt));

    final searchMatches = _conversationsForSearch(historyState, searchQuery)
      .toList()
      ..sort((a, b) => (b.updatedAt ?? b.createdAt)
          .compareTo(a.updatedAt ?? a.createdAt));

    final filteredHistoryChats =
        searchQuery.isEmpty ? allHistoryChats : searchMatches;

    final filteredSavedChats = searchQuery.isEmpty
        ? savedChats
        : searchMatches.where((c) => c.isPinned).toList();

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
                    l10n.libScreenTitle,
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
                  l10n,
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
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark),
                      decoration: InputDecoration(
                        hintText: l10n.libSearchChatsHint,
                        hintStyle: GoogleFonts.nunito(fontSize: 13, color: cl.textLight),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: cl.textLight),
                        suffixIcon: searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  ref.read(historyProvider.notifier).clearSearch();
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
                            child: _buildHistoryContent(historyState, filteredHistoryChats, searchQuery, l10n),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('saved'),
                            child: _buildSavedContent(
                              historyState,
                              filteredSavedChats,
                              searchQuery,
                              l10n,
                            ),
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

  Widget _buildSegmentControl(
      int historyCount, int savedCount, AppLocalizations l10n) {
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
            _segmentTab(l10n.libTabHistory, historyCount, 0, Icons.history_rounded),
            _segmentTab(l10n.libTabSaved, savedCount, 1, Icons.bookmark_rounded),
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
    AppLocalizations l10n,
  ) {
    final cl = context.c;
    if (state.isLoading && state.conversations.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }
    if (searchQuery.isNotEmpty &&
        state.isSearchLoading &&
        state.searchResults == null) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }
    if (chats.isEmpty) {
      return searchQuery.isNotEmpty
          ? _buildSearchEmpty('history', l10n)
          : _buildHistoryEmpty(l10n);
    }

    return RefreshIndicator(
      color: cl.accent,
      onRefresh: () => ref.read(historyProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _historyCard(chats[i], l10n),
      ),
    );
  }

  Widget _historyCard(ConversationEntity conversation, AppLocalizations l10n) {
    final cl = context.c;
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final previewAsync = ref.watch(conversationPreviewProvider(conversation.id));
    final fallbackStr =
        conversationListFallbackPreview(conversation.lastMessage, l10n);
    final lastMessagePreview = previewAsync.when(
      data: (line) => formatConversationPreviewLine(line, l10n),
      loading: () => fallbackStr,
      error: (_, __) => fallbackStr,
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
                        conversation.isPinned ? l10n.convUnsave : l10n.convSave,
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
                        l10n.convRename,
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
                        l10n.convShareToLawyer,
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
                        l10n.convDownload,
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
                        l10n.convDelete,
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

  Widget _buildHistoryEmpty(AppLocalizations l10n) {
    final cl = context.c;
    final isGuest = ref.watch(currentUserProvider)?.isAnonymous == true;
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
            isGuest ? l10n.histGuestEmptyTitle : l10n.histEmptyTitle,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isGuest ? l10n.histGuestEmptySubtitle : l10n.histEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
          ),
        ],
      ),
    );
  }

  // ─── Saved content ─────────────────────────────────────────────────

  Widget _buildSavedContent(
    HistoryState state,
    List<ConversationEntity> saved,
    String searchQuery,
    AppLocalizations l10n,
  ) {
    final cl = context.c;
    if (searchQuery.isNotEmpty &&
        state.isSearchLoading &&
        state.searchResults == null) {
      return Center(
        child: CircularProgressIndicator(color: cl.accent),
      );
    }
    if (saved.isEmpty) {
      return searchQuery.isNotEmpty
          ? _buildSearchEmpty('saved', l10n)
          : _buildSavedEmpty(l10n);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: saved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _savedCard(saved[i], l10n),
    );
  }

  Widget _savedCard(ConversationEntity conversation, AppLocalizations l10n) {
    final cl = context.c;
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final previewAsync = ref.watch(conversationPreviewProvider(conversation.id));
    final fallbackStr =
        conversationListFallbackPreview(conversation.lastMessage, l10n);
    final lastMessagePreview = previewAsync.when(
      data: (line) => formatConversationPreviewLine(line, l10n),
      loading: () => fallbackStr,
      error: (_, __) => fallbackStr,
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
                        l10n.convUnsave,
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
                        l10n.convRename,
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
                        l10n.convShareToLawyer,
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
                        l10n.convDownload,
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
                        l10n.convDelete,
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

  Widget _buildSavedEmpty(AppLocalizations l10n) {
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
            l10n.libSavedEmptyTitle,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cl.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.libSavedEmptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmpty(String segment, AppLocalizations l10n) {
    final cl = context.c;
    final title = segment == 'saved'
        ? l10n.libSearchNoSaved
        : l10n.libSearchNoHistory;
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
            l10n.libSearchTryDifferent,
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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.histGeneratingPdf),
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
          content: Text(l10n.histDownloadFailed(friendlyErrorMessage(e))),
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
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(dl.histRenameDialogTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: GoogleFonts.nunito(),
          decoration: InputDecoration(
            hintText: dl.histRenameHint,
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
            child: Text(dl.commonCancel,
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
            child: Text(dl.histRenameButton,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: cl.accent)),
          ),
        ],
      );
      },
    );
  }

  void _confirmDelete(ConversationEntity conversation) {
    final cl = context.c;
    showDialog(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(dl.histDeleteTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text(
          dl.histDeleteBody,
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dl.commonCancel,
                style: GoogleFonts.nunito(color: cl.textMid)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(historyProvider.notifier)
                  .deleteConversation(conversation.id);
              if (!context.mounted) return;
              if (ok &&
                  ref.read(chatProvider).conversationId == conversation.id) {
                ref.read(chatProvider.notifier).reset();
              }
            },
            child: Text(dl.commonDelete,
                style: GoogleFonts.nunito(color: Colors.red.shade700)),
          ),
        ],
      );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date.toLocal());
  }
}
