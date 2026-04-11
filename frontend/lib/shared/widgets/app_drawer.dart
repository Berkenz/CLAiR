import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/shared/data/chat_history.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const _relativeTimeLabels = ['2h ago', 'Yesterday', '3 days ago', 'Last week', '2 weeks ago'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentChats = sharedChatHistory.take(4).toList();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.76,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: AppColors.textDark.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(4, 0))],
        ),
        child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              SizedBox(width: 24, height: 24,
                  child: Image.asset('assets/images/CLAiR-icon.png', fit: BoxFit.contain, color: AppColors.accent, colorBlendMode: BlendMode.srcIn)),
              const SizedBox(width: 8),
              Text('CLAiR', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: AppColors.fieldBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, size: 18, color: AppColors.textLight),
                const SizedBox(width: 8),
                Text('Search chats...', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight)),
              ]),
            ),
          ),

          const Divider(color: AppColors.border, indent: 20, endIndent: 20, height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text('RECENT', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textLight)),
          ),

          if (recentChats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('No recent chats', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight)),
            )
          else
            ...recentChats.asMap().entries.map((e) {
              final timeLabel = e.key < _relativeTimeLabels.length ? _relativeTimeLabels[e.key] : '';
              return _recentChat(Icons.chat_bubble_outline_rounded, e.value.title, timeLabel);
            }),

          const SizedBox(height: 8),
          const Divider(color: AppColors.border, indent: 20, endIndent: 20, height: 1),

          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              _label('Navigate'),
              _item(Icons.home_outlined, 'Home', true, () => Navigator.pop(context)),
              _item(Icons.chat_bubble_outline, 'New Chat', false, () => Navigator.pop(context)),
              _item(Icons.history_rounded, 'Chat History', false, () => Navigator.pop(context)),
              _item(Icons.balance_rounded, 'Find a Lawyer', false, () { Navigator.pop(context); context.push('/lawyers'); }),
              _item(Icons.notifications_none_rounded, 'Notifications', false, () { Navigator.pop(context); context.push('/notifications'); }),
              const SizedBox(height: 12),
              _label('Account'),
              _item(Icons.person_outline_rounded, 'Profile', false, () { Navigator.pop(context); context.push('/profile'); }),
            ],
          )),
          const Divider(color: AppColors.border, indent: 20, endIndent: 20, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: _item(Icons.logout_rounded, 'Sign Out', false, () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/');
            }, isDestructive: true),
          ),
        ])),
      ),
    );
  }

  Widget _recentChat(IconData icon, String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(time, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textLight)),
        ]),
      ),
    );
  }

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 0, 6),
    child: Text(s.toUpperCase(), style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textLight)),
  );

  Widget _item(IconData icon, String label, bool active, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFDC4C4C) : (active ? AppColors.accent : AppColors.textMid);
    return Material(
      color: active ? AppColors.accent.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.textDark : color)),
          ]),
        ),
      ),
    );
  }
}
