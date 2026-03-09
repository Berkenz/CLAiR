import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Usage:
//  1. Add `drawer: const AppDrawer()` to your root Scaffold.
//  2. ClairAppBar hamburger calls: Scaffold.of(context).openDrawer()
// ─────────────────────────────────────────────────────────────────────────────

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBrown,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo header ───────────────────────────────────
              const _DrawerHeader(),

              _DrawerDivider(),

              // ── Nav items ─────────────────────────────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    // ── Main ──────────────────────────────────
                    const _SectionLabel('Main'),
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/home');
                      },
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'New Chat',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/chat');
                      },
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'Chat History',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/history');
                      },
                    ),
                    _NavItem(
                      icon: Icons.folder_outlined,
                      activeIcon: Icons.folder_rounded,
                      label: 'My Documents',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/documents');
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Legal Tools ───────────────────────────
                    const _SectionLabel('Legal Tools'),
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.person_search_outlined,
                      label: 'Find a Lawyer',
                      badge: 'New',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/find-lawyer');
                      },
                    ),
                    _NavItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Legal Dictionary',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/dictionary');
                      },
                    ),
                    _NavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Appointments',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/appointments');
                      },
                    ),
                    _NavItem(
                      icon: Icons.bookmark_outline_rounded,
                      activeIcon: Icons.bookmark_rounded,
                      label: 'Saved Tips',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/saved-tips');
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Account ───────────────────────────────
                    const _SectionLabel('Account'),
                    const SizedBox(height: 4),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _NavItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & FAQ',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/help');
                      },
                    ),
                  ],
                ),
              ),

              // ── Sign out ──────────────────────────────────────
              _DrawerDivider(),
              _SignOutButton(
                onTap: () async {
                  Navigator.pop(context);
                  final repository = ref.read(authRepositoryProvider);
                  await repository.signOut();
                  if (context.mounted) context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — just the CLAiR logo, no user info
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Image.asset(
              'assets/images/CLAiR-icon.png',
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'clair',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Satoshi',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: Colors.white.withOpacity(0.28),
          fontFamily: 'Satoshi',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Item
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.isActive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.11) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.06),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  size: 19,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.65),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                if (isActive && badge == null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divider
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
      indent: 20,
      endIndent: 20,
      height: 16,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign Out
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      child: Material(
        color: AppColors.crimson.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.crimson.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: AppColors.crimson.withOpacity(0.9),
                ),
                const SizedBox(width: 14),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.crimson.withOpacity(0.9),
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
