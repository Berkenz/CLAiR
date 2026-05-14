import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:go_router/go_router.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_sharing_provider.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(historyProvider.notifier).loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == 2) {
        ref.read(historyProvider.notifier).loadConversations();
      }
    });

    final state = ref.watch(historyProvider);

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

    return Column(
      children: [
        const ClairAppBar(),
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  void _openConversation(ConversationEntity conversation) {
    ref.read(chatProvider.notifier).loadConversation(
          conversation.id,
          title: conversation.title,
          isPinned: conversation.isPinned,
        );
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _deleteConversation(String id) {
    ref.read(historyProvider.notifier).deleteConversation(id);
  }

  void _togglePin(String id) {
    ref.read(historyProvider.notifier).togglePin(id);
  }

  Widget _buildBody(HistoryState state) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading && state.conversations.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cl.darkBrown),
      );
    }

    if (state.conversations.isEmpty) {
      return _buildEmptyState(l10n);
    }

    final sorted = state.conversations.toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt));

    return RefreshIndicator(
      color: cl.darkBrown,
      onRefresh: () => ref.read(historyProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildConversationCard(sorted[index], l10n),
      ),
    );
  }

  Widget _buildConversationCard(ConversationEntity conversation, AppLocalizations l10n) {
    final cl = context.c;
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final lastMessagePreview = conversation.lastMessage?.trim().isNotEmpty == true
      ? conversation.lastMessage!.trim()
      : l10n.histTapToOpen;

    return GestureDetector(
      onTap: () => _openConversation(conversation),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 4, 16),
        decoration: BoxDecoration(
          color: cl.offWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cl.darkBrown.withOpacity(0.05),
              blurRadius: 12,
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
                  Icons.bookmark_rounded,
                  size: 16,
                  color: cl.darkBrown.withOpacity(0.5),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cl.darkBrown,
                      fontFamily: 'Satoshi',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessagePreview,
                    style: TextStyle(
                      fontSize: 12,
                      color: cl.darkBrown.withOpacity(0.45),
                      fontFamily: 'Satoshi',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateTimeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: cl.darkBrown.withOpacity(0.35),
                      fontFamily: 'Satoshi',
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
                color: cl.darkBrown.withOpacity(0.45),
                size: 20,
              ),
              splashRadius: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: cl.offWhite,
              elevation: 4,
              onSelected: (value) {
                switch (value) {
                  case 'pin':
                    _togglePin(conversation.id);
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
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        conversation.isPinned
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 18,
                        color: cl.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        conversation.isPinned ? l10n.convUnsave : l10n.convSave,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: cl.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: cl.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.convRename,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: cl.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: cl.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.convShareToLawyer,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: cl.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: cl.darkBrown,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.convDownload,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          color: cl.darkBrown,
                        ),
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
                        style: TextStyle(
                          fontFamily: 'Satoshi',
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

  void _showRenameDialog(ConversationEntity conversation) {
    final cl = context.c;
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          dl.histRenameDialogTitle,
          style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          style: const TextStyle(fontFamily: 'Satoshi'),
          decoration: InputDecoration(
            hintText: dl.histRenameHint,
            hintStyle: TextStyle(
              fontFamily: 'Satoshi',
              color: cl.darkBrown.withOpacity(0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cl.darkBrown, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dl.commonCancel,
                style: TextStyle(color: cl.darkBrown, fontFamily: 'Satoshi')),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                ref.read(historyProvider.notifier).renameConversation(
                      conversation.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: Text(dl.histRenameButton,
                style: TextStyle(
                    color: cl.darkBrown,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Satoshi')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          dl.histDeleteTitle,
          style: const TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w600),
        ),
        content: Text(
          dl.histDeleteBody,
          style: const TextStyle(fontFamily: 'Satoshi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(dl.commonCancel,
                style: TextStyle(color: cl.darkBrown)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteConversation(conversation.id);
            },
            child: Text(dl.commonDelete,
                style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      );
      },
    );
  }

  void _shareToLawyer(ConversationEntity conversation) {
    ref.read(lawyerSharingProvider.notifier).state = ConversationSharingData(
      title: conversation.title,
      conversationId: conversation.id,
    );
    // Switch to the Lawyers tab, then pop back to the main shell.
    ref.read(mainShellTabProvider.notifier).state = 3;
    context.pop();
  }

  Future<void> _downloadConversation(ConversationEntity conversation) async {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.histGeneratingPdf),
        backgroundColor: cl.darkBrown,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      // Load the conversation to get messages
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
      final safeName = conversation.title.replaceAll(RegExp(r'[^\w\s-]'), '_').trim();
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
          content: Text(l10n.histDownloadFailed(e.toString())),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final cl = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: cl.tan.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.histEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              color: cl.darkBrown.withOpacity(0.4),
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.histEmptySubtitle,
            style: TextStyle(
              fontSize: 13,
              color: cl.darkBrown.withOpacity(0.3),
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
