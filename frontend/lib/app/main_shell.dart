import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/services/location_service.dart';
import 'package:clair/core/session/user_session.dart';
import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/l10n/app_localizations.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';
import 'package:clair/features/home/presentation/screens/home_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/chat/utils/guest_chat_reset.dart';
import 'package:clair/features/library/presentation/screens/library_screen.dart';
import 'package:clair/features/lawyer/presentation/providers/lawyer_provider.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_screen.dart';
import 'package:clair/features/appointments/presentation/screens/appointment_screen.dart';
import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/features/appointments/presentation/providers/direct_message_provider.dart';
import 'package:clair/core/notifications/push_notification_service.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/features/notifications/presentation/utils/push_notification_navigation.dart';
import 'package:clair/features/notifications/presentation/widgets/realtime_notification_banner.dart';
import 'package:clair/core/tutorial/tutorial_overlay.dart';
import 'package:clair/core/tutorial/tutorial_provider.dart';
import 'package:clair/shared/widgets/app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  Timer? _notificationPollTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPress;

  // Keys for each bottom-nav item so the tutorial can spotlight them.
  final _navKeys = List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      ref.read(historyProvider.notifier).syncWithUser(user?.id);
      ref.read(notificationInboxProvider.notifier).refresh();
      ref.read(locationProvider.notifier).prefetchIfNeeded();
      final pending = ref.read(pendingPushNotificationProvider);
      if (pending != null) {
        applyPushNotificationNavigation(ref, pending);
        ref.read(pendingPushNotificationProvider.notifier).state = null;
      }
    });
    _notificationPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (!mounted) return;
        ref.read(notificationInboxProvider.notifier).pollSilently();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(notificationInboxProvider.notifier).pollSilently();
      ref.read(locationProvider.notifier).prefetchIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationPollTimer?.cancel();
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

  Future<void> _fabNewChat() async {
    _closeFab();
    if (!await resetChatWithGuestGuard(context: context, ref: ref) ||
        !mounted) {
      return;
    }
    ref.read(mainShellTabProvider.notifier).state = 1;
  }

  void _fabFindLawyer() {
    _closeFab();
    ref.read(mainShellTabProvider.notifier).state = 3;
  }

  void _handleBack() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return;
    }
    if (_fabOpen) {
      _closeFab();
      return;
    }
    if (ref.read(lawyerMapSheetOpenProvider)) {
      ref.read(lawyerMapSheetOpenProvider.notifier).state = false;
      return;
    }
    if (ref.read(lawyerMapViewActiveProvider)) {
      ref.read(lawyerMapViewActiveProvider.notifier).state = false;
      return;
    }

    final currentIndex = ref.read(mainShellTabProvider);
    if (currentIndex != 0) {
      ref.read(mainShellTabProvider.notifier).state = 0;
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      final l10n = AppLocalizations.of(context)!;
      final scaffoldContext = _scaffoldKey.currentContext;
      if (scaffoldContext == null) return;
      final messenger = ScaffoldMessenger.of(scaffoldContext);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.pressBackAgainToExit),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    SystemNavigator.pop();
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
    final lawyerMapSheetOpen = ref.watch(lawyerMapSheetOpenProvider);
    final lawyerMapViewActive = ref.watch(lawyerMapViewActiveProvider);

    ref.listen<UserEntity?>(currentUserProvider, (previous, next) {
      applyUserSessionChange(ref, previous: previous, next: next);
    });

    ref.listen<int>(mainShellTabProvider, (prev, next) {
      _closeFab();
      if (next != 3) {
        ref.read(lawyerMapSheetOpenProvider.notifier).state = false;
        ref.read(lawyerMapViewActiveProvider.notifier).state = false;
      }
      if (next == 4 && prev != next) {
        ref.read(notificationInboxProvider.notifier).refresh();
      }
    });

    ref.listen(pendingPushNotificationProvider, (prev, next) {
      if (next == null) return;
      applyPushNotificationNavigation(ref, next);
      ref.read(pendingPushNotificationProvider.notifier).state = null;
    });

    final tutorialActive = ref.watch(tutorialProvider).show;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          backgroundColor: cl.bg,
          drawer: const AppDrawer(),
          body: GestureDetector(
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
          floatingActionButton: currentIndex == 1 ||
                  tutorialActive ||
                  lawyerMapSheetOpen ||
                  lawyerMapViewActive
              ? null
              : _QuickActionsFab(
                  open: _fabOpen,
                  anim: _fabAnim,
                  onToggle: _toggleFab,
                  onNewChat: _fabNewChat,
                  onFindLawyer: _fabFindLawyer,
                ),
          bottomNavigationBar: _buildNav(context, currentIndex, navLabels),
        ),
        if (tutorialActive)
          TutorialOverlay(navItemKeys: _navKeys),
        const Positioned(
          left: 12,
          right: 12,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: RealtimeNotificationBanner(),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildNav(BuildContext context, int currentIndex, List<String> labels) {
    final cl = context.c;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final inbox = ref.watch(notificationInboxProvider);
    final dmAggregate = ref.watch(dmUnreadAggregateProvider);
    final totalUnread = inbox.unreadCount > dmAggregate ? inbox.unreadCount : dmAggregate;

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
              if (i == 4) {
                return _navItem(
                  i,
                  currentIndex,
                  labels,
                  totalUnread,
                );
              }
              return _navItem(i, currentIndex, labels, 0);
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int i,
    int currentIndex,
    List<String> labels,
    int badgeCount, {
    bool badgeDotOnly = false,
  }) {
    final cl = context.c;
    final active = currentIndex == i;

    Widget iconWidget = Icon(
      active ? _activeIcons[i] : _icons[i],
      size: 24,
      color: active ? cl.accent : cl.textLight,
    );

    if (badgeDotOnly && badgeCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: cl.surface, width: 1.5),
              ),
            ),
          ),
        ],
      );
    } else if (!badgeDotOnly && badgeCount > 0) {
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
      key: _navKeys[i],
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
                child: const Icon(
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
