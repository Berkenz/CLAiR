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
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/chat/utils/chat_markdown_format.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/shared/widgets/clair_app_bar.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});
  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
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
      if (next == 4) {
        ref.read(historyProvider.notifier).loadConversations();
      }
    });

    final state = ref.watch(historyProvider);
    final cl = context.c;
    final saved = state.conversations
        .where((c) => c.isPinned)
        .toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt));

    return Column(children: [
      const ClairAppBar(),
      Expanded(child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [cl.surface, cl.bg]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Bookmarked Chats', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: cl.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cl.surface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cl.border),
                    boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 4, offset: const Offset(0, 1))]),
                child: Text('${saved.length} bookmarked', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: cl.textMid)),
              ),
            ]),
          ),
          Expanded(
            child: saved.isEmpty
                ? _empty(cl)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: saved.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(saved[i], cl),
                  ),
          ),
        ]),
      )),
    ]);
  }

  Widget _card(ConversationEntity conversation, AppColorTheme cl) {
    final chatDate = conversation.updatedAt ?? conversation.createdAt;
    final dateTimeStr = _formatDateTime(chatDate);
    final lastMessagePreview = conversation.lastMessage?.trim().isNotEmpty == true
      ? plainTextChatPreview(conversation.lastMessage!)
      : 'Tap to open conversation';

    return GestureDetector(
      onTap: () {
        ref.read(chatProvider.notifier).loadConversation(
          conversation.id,
          title: conversation.title,
          isPinned: conversation.isPinned,
        );
        ref.read(mainShellTabProvider.notifier).state = 1;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [BoxShadow(color: cl.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 4, height: 52,
              decoration: BoxDecoration(color: cl.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(conversation.title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: cl.textDark)),
            const SizedBox(height: 4),
            Text(lastMessagePreview, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(fontSize: 12, color: cl.textMid)),
            const SizedBox(height: 6),
            Text(dateTimeStr, style: GoogleFonts.nunito(fontSize: 11, color: cl.textLight)),
          ])),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: cl.textLight, size: 20),
            splashRadius: 20,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: cl.surface,
            elevation: 4,
            onSelected: (value) {
              switch (value) {
                case 'unsave':
                  ref.read(historyProvider.notifier).togglePin(conversation.id);
                  break;
                case 'share':
                  _shareToLawyer(conversation);
                  break;
                case 'download':
                  _downloadConversation(conversation);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'unsave',
                child: Row(children: [
                  Icon(Icons.bookmark_rounded, size: 18, color: cl.textDark),
                  const SizedBox(width: 12),
                  Text('Remove Bookmark', style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark)),
                ]),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(children: [
                  Icon(Icons.share_rounded, size: 18, color: cl.accent),
                  const SizedBox(width: 12),
                  Text('Share to Lawyer', style: GoogleFonts.nunito(fontSize: 13, color: cl.accent)),
                ]),
              ),
              PopupMenuItem(
                value: 'download',
                child: Row(children: [
                  Icon(Icons.download_rounded, size: 18, color: cl.textDark),
                  const SizedBox(width: 12),
                  Text('Download', style: GoogleFonts.nunito(fontSize: 13, color: cl.textDark)),
                ]),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }

  Widget _empty(AppColorTheme cl) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
          decoration: BoxDecoration(color: cl.fieldBg, shape: BoxShape.circle),
          child: Icon(Icons.bookmark_outline_rounded, size: 28, color: cl.textLight)),
      const SizedBox(height: 16),
      Text('No bookmarked chats', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: cl.textDark)),
      const SizedBox(height: 6),
      Text('Bookmark chats from History to access them here.', style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid)),
    ]));
  }

  void _shareToLawyer(ConversationEntity conversation) {
    // TODO: Implement share to lawyer feature
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share to Lawyer feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadConversation(ConversationEntity conversation) async {
    final cl = context.c;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Generating PDF...'),
        backgroundColor: cl.textDark,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: Text(friendlyErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}