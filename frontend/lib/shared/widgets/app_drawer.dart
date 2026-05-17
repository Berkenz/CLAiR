import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/chat/utils/guest_chat_reset.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/l10n/app_localizations.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final historyState = ref.watch(historyProvider);
    
    // Load recent chats once; avoid re-fetch (sets isLoading) on every drawer open.
    if (!historyState.hasLoaded && !historyState.isLoading) {
      Future.microtask(() {
        ref.read(historyProvider.notifier).loadConversations(silent: true);
      });
    }

    final allChats = historyState.conversations;
    final filteredChats = allChats
        .where((c) => !c.isPinned)
        .toList()
      ..sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
    final recentChats = filteredChats.take(4).toList();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.76,
      backgroundColor: cl.surface,
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
              l10n.drawerRecent,
              style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: cl.textLight),
            ),
          ),

          if (recentChats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                l10n.drawerNoRecentChats,
                style: GoogleFonts.nunito(fontSize: 13, color: cl.textLight),
              ),
            )
          else
            ...recentChats.asMap().entries.map((e) {
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
                child: _recentChat(context, Icons.chat_bubble_outline_rounded, conv.title, timeLabel),
              );
            }),

          const SizedBox(height: 8),
          Divider(color: cl.border, indent: 20, endIndent: 20, height: 1),

          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _label(context, l10n.drawerNavigate),
              _item(context, Icons.home_outlined, l10n.drawerHome, true, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 0;
              }),
              _item(context, Icons.chat_bubble_outline, l10n.drawerNewChat, false, () async {
                Navigator.pop(context);
                if (!await resetChatWithGuestGuard(context: context, ref: ref) ||
                    !context.mounted) {
                  return;
                }
                ref.read(mainShellTabProvider.notifier).state = 1;
              }),
              _item(context, Icons.library_books_rounded, l10n.drawerChatLibrary, false, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 2;
              }),
              _item(context, Icons.balance_rounded, l10n.drawerFindLawyer, false, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 3;
              }),
              _item(context, Icons.event_note_outlined, l10n.drawerAppointments, false, () {
                Navigator.pop(context);
                ref.read(mainShellTabProvider.notifier).state = 4;
              }),
              _itemWithBadge(
                context,
                Icons.notifications_none_rounded,
                l10n.drawerNotifications,
                badge: ref.watch(notificationInboxProvider).unreadCount,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/notifications');
                },
              ),
              const SizedBox(height: 12),
              _label(context, l10n.drawerAccount),
              _item(context, Icons.person_outline_rounded, l10n.drawerProfile, false, () { Navigator.pop(context); context.push('/profile'); }),
            ],
          )),
          Divider(color: cl.border, indent: 20, endIndent: 20, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: _item(context, Icons.logout_rounded, l10n.drawerSignOut, false, () async {
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

  Widget _itemWithBadge(
    BuildContext context,
    IconData icon,
    String label, {
    required int badge,
    required VoidCallback onTap,
  }) {
    final cl = context.c;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 19, color: cl.textMid),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cl.surface, width: 1.2),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cl.textMid,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
