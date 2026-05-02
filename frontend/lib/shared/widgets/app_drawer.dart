import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final historyState = ref.watch(historyProvider);
    
    // Load conversations if not already loaded
    if (historyState.conversations.isEmpty && !historyState.isLoading) {
      Future.microtask(() {
        ref.read(historyProvider.notifier).loadConversations();
      });
    }

    final allChats = historyState.conversations;
    final filteredChats = allChats.take(4).toList();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.76,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: cl.textDark.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(4, 0))],
        ),
        child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              SizedBox(width: 24, height: 24,
                  child: Image.asset('assets/images/CLAiR-icon.png', fit: BoxFit.contain, color: cl.accent, colorBlendMode: BlendMode.srcIn)),
              const SizedBox(width: 8),
              Text('CLAiR', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: cl.textDark)),
            ]),
          ),

          Divider(color: cl.border, indent: 20, endIndent: 20, height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'RECENT',
              style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: cl.textLight),
            ),
          ),

          if (filteredChats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'No recent chats',
                style: GoogleFonts.nunito(fontSize: 13, color: cl.textLight),
              ),
            )
          else
            ...filteredChats.toList().asMap().entries.map((e) {
              final conv = e.value;
              final timeLabel = _formatRecentTime(conv.updatedAt ?? conv.createdAt);
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(chatProvider.notifier).loadConversation(
                    conv.id,
                    title: conv.title,
                    isPinned: conv.isPinned,
                  );
                  ref.read(mainShellTabProvider.notifier).state = 1;
                },
                child: _recentChat(context, conv.isPinned ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded, conv.title, timeLabel),
              );
            }),

          const SizedBox(height: 8),
          Divider(color: cl.border, indent: 20, endIndent: 20, height: 1),

          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _label(context, 'Navigate'),
              _item(context, Icons.home_outlined, 'Home', true, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 0;
              }),
              _item(context, Icons.chat_bubble_outline, 'New Chat', false, () {
                Navigator.pop(context);
                ref.read(chatProvider.notifier).reset();
                ref.read(mainShellTabProvider.notifier).state = 1;
              }),
              _item(context, Icons.library_books_rounded, 'Chat Library', false, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 2;
              }),
              _item(context, Icons.balance_rounded, 'Find a Lawyer', false, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 3;
              }),
              _item(context, Icons.notifications_none_rounded, 'Notifications', false, () { Navigator.pop(context); context.push('/notifications'); }),
              const SizedBox(height: 12),
              _label(context, 'Account'),
              _item(context, Icons.person_outline_rounded, 'Profile', false, () { Navigator.pop(context); context.push('/profile'); }),
            ],
          )),
          Divider(color: cl.border, indent: 20, endIndent: 20, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: _item(context, Icons.logout_rounded, 'Sign Out', false, () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
              ref.read(currentUserProvider.notifier).state = null;
              ref.read(chatProvider.notifier).reset();
              if (context.mounted) context.go('/login');
            }, isDestructive: true),
          ),
        ])),
      ),
    );
  }

  String _formatRecentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }

  Widget _recentChat(BuildContext context, IconData icon, String title, String time) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cl.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 14, color: cl.accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cl.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: cl.textLight,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(BuildContext context, String s) {
    final cl = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 6),
      child: Text(s.toUpperCase(), style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: cl.textLight)),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap, {bool isDestructive = false}) {
    final cl = context.c;
    final color = isDestructive ? const Color(0xFFDC4C4C) : (active ? cl.accent : cl.textMid);
    return Material(
      color: active ? cl.accent.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? cl.textDark : color)),
          ]),
        ),
      ),
    );
  }
}
