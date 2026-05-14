import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/features/home/presentation/screens/home_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/library/presentation/screens/library_screen.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_screen.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_screen.dart';
import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/shared/widgets/app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
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

  bool _fabOpen = false;
  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationInboxProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  void _closeFab() {
    if (!_fabOpen) return;
    setState(() => _fabOpen = false);
    _fabAnim.reverse();
  }

  void _fabNewChat() {
    _closeFab();
    ref.read(chatProvider.notifier).reset();
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _fabFindLawyer() {
    _closeFab();
    ref.read(mainShellTabProvider.notifier).state = 3;
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
      _closeFab();
      if (next == 4 && prev != next) {
        ref.read(notificationInboxProvider.notifier).refresh();
      }
    });

    return Scaffold(
      backgroundColor: cl.bg,
      drawer: const AppDrawer(),
      body: GestureDetector(
        // Tap anywhere in the body to close the FAB when open.
        onTap: _fabOpen ? _closeFab : null,
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
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
      ),
      floatingActionButton: currentIndex == 1
          ? null
          : _QuickActionsFab(
              open: _fabOpen,
              anim: _fabAnim,
              onToggle: _toggleFab,
              onNewChat: _fabNewChat,
              onFindLawyer: _fabFindLawyer,
            ),
      bottomNavigationBar: _buildNav(context, currentIndex, navLabels),
    );
  }

  Widget _buildNav(BuildContext context, int currentIndex, List<String> labels) {
    final cl = context.c;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final apptPendingCount = ref.watch(appointmentProvider).pendingCount;

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
            (i) {
              final badgeCount = i == 4 ? apptPendingCount : 0;
              return _navItem(i, currentIndex, labels, badgeCount);
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, int currentIndex, List<String> labels, int badgeCount) {
    final cl = context.c;
    final active = currentIndex == i;

    Widget iconWidget = Icon(
      active ? _activeIcons[i] : _icons[i],
      size: 24,
      color: active ? cl.accent : cl.textLight,
    );

    if (badgeCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cl.surface, width: 1.2),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: GoogleFonts.nunito(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
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

// ── Quick Actions FAB ─────────────────────────────────────────────────────────

class _QuickActionsFab extends StatelessWidget {
  const _QuickActionsFab({
    required this.open,
    required this.anim,
    required this.onToggle,
    required this.onNewChat,
    required this.onFindLawyer,
  });

  final bool open;
  final AnimationController anim;
  final VoidCallback onToggle;
  final VoidCallback onNewChat;
  final VoidCallback onFindLawyer;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Book appointment action ─────────────────────────────────────────
        _FabAction(
          anim: anim,
          delay: 0.0,
          icon: Icons.balance_rounded,
          label: 'Find a Lawyer',
          cl: cl,
          onTap: onFindLawyer,
        ),
        const SizedBox(height: 10),

        // ── New chat action ─────────────────────────────────────────────────
        _FabAction(
          anim: anim,
          delay: 0.08,
          icon: Icons.chat_bubble_rounded,
          label: 'New Chat',
          cl: cl,
          onTap: onNewChat,
        ),
        const SizedBox(height: 14),

        // ── Main FAB ────────────────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cl.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cl.accent.withValues(alpha: open ? 0.15 : 0.35),
                  blurRadius: open ? 8 : 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: open ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FabAction extends StatelessWidget {
  const _FabAction({
    required this.anim,
    required this.delay,
    required this.icon,
    required this.label,
    required this.cl,
    required this.onTap,
  });

  final AnimationController anim;
  final double delay;
  final IconData icon;
  final String label;
  final AppColorTheme cl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Stagger the entrance: each child starts slightly after the previous.
    final staggered = CurvedAnimation(
      parent: anim,
      curve: Interval(delay, delay + 0.7, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: staggered,
      builder: (context, child) {
        final v = staggered.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: cl.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cl.textDark.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cl.textDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mini FAB circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cl.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cl.textDark.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: cl.accent),
            ),
          ],
        ),
      ),
    );
  }
}
