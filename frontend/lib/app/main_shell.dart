import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/features/home/presentation/screens/home_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/library/presentation/screens/library_screen.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_screen.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_screen.dart';
import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/shared/widgets/app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _icons = [
    Icons.home_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.library_books_outlined,
    Icons.balance_outlined,
    Icons.event_note_outlined,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.library_books_rounded,
    Icons.balance_rounded,
    Icons.event_note_rounded,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationInboxProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final navLabels = [
      l10n.navHome,
      l10n.navChat,
      l10n.navLibrary,
      l10n.navLawyers,
      l10n.navAppointments,
    ];
    final currentIndex = ref.watch(mainShellTabProvider);

    ref.listen<int>(mainShellTabProvider, (prev, next) {
      if (next == 4 && prev != next) {
        ref.read(notificationInboxProvider.notifier).refresh();
      }
    });

    return Scaffold(
      backgroundColor: cl.bg,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: [
              const HomeScreen(),
              const ChatScreen(),
              const LibraryScreen(),
              const LawyerTabScreen(),
              const AppointmentTabScreen(),
            ][currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildNav(context, currentIndex, navLabels),
    );
  }

  Widget _buildNav(BuildContext context, int currentIndex, List<String> labels) {
    final cl = context.c;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 8),
      decoration: BoxDecoration(
        color: cl.surface,
        boxShadow: [
          BoxShadow(
            color: cl.textDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            labels.length,
            (i) => _navItem(
              i,
              currentIndex,
              labels,
              ref.watch(notificationInboxProvider).unreadCount,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, int currentIndex, List<String> labels, int unreadCount) {
    final cl = context.c;
    final active = currentIndex == i;
    final showDot = unreadCount > 0 && (i == 0 || i == 4);

    Widget iconWidget = Icon(
      active ? _activeIcons[i] : _icons[i],
      size: 24,
      color: active ? cl.accent : cl.textLight,
    );
    if (showDot) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: cl.surface, width: 1.2),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => ref.read(mainShellTabProvider.notifier).state = i,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: active
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cl.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          iconWidget,
          if (active) ...[
            const SizedBox(width: 6),
            Text(
              labels[i],
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cl.accent,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
