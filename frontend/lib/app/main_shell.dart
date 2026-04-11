import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/home/presentation/screens/home_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/saved/presentation/screens/saved_screen.dart';
import 'package:clair/features/history/presentation/screens/history_screen.dart';
import 'package:clair/shared/widgets/app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  static const _labels = ['Home', 'Chat', 'Saved', 'History'];
  static const _icons = [
    Icons.home_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.bookmark_outline_rounded,
    Icons.history_rounded,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.bookmark_rounded,
    Icons.history_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_idx),
            child: const [HomeScreen(), ChatScreen(), SavedScreen(), HistoryScreen()][_idx],
          ),
        ),
      ),
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.textDark.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, _navItem),
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final active = _idx == i;
    return GestureDetector(
      onTap: () => setState(() => _idx = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: active
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? _activeIcons[i] : _icons[i], size: 24,
              color: active ? AppColors.accent : AppColors.textLight),
          if (active) ...[
            const SizedBox(width: 6),
            Text(_labels[i], style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ],
        ]),
      ),
    );
  }
}
