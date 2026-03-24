import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/home/presentation/screens/home_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/history/presentation/screens/history_screen.dart';
import 'package:clair/shared/widgets/app_drawer.dart';

final mainShellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _icons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.history_rounded,
  ];

  static const _labels = ['Home', 'Chat', 'History'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainShellTabProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: currentIndex,
          children: const [
            HomeScreen(),
            ChatScreen(),
            HistoryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBrown.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (i) => _buildNavItem(i, currentIndex),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, int currentIndex) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => ref.read(mainShellTabProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 22, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[index],
              size: 22,
              color: isActive
                  ? Colors.white
                  : AppColors.darkBrown.withOpacity(0.4),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                _labels[index],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
