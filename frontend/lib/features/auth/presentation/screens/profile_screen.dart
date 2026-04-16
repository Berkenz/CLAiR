import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/appearance_screen.dart';
import 'package:clair/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final user = ref.watch(currentUserProvider);
    final name = user?.displayName ?? 'User';
    final parts = name.split(' ');
    final initials = parts
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cl.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cl.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: cl.textDark,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Settings',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cl.textDark,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 38),
            ]),
            const SizedBox(height: 28),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cl.accent.withValues(alpha: 0.12),
                    cl.accentLight.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cl.cardShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user?.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        user!.photoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: cl.accent,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cl.textDark,
              ),
            ),
            Text(
              user?.email ?? '',
              style: GoogleFonts.nunito(fontSize: 13, color: cl.textMid),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cl.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cl.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            _section(context, 'Account', [
              _row(context, Icons.mail_outline_rounded, 'Email', () {}),
              _row(
                context,
                Icons.notifications_outlined,
                'Notifications',
                () => context.push('/notifications'),
              ),
              _row(context, Icons.lock_outline_rounded, 'Security', () {}),
            ]),
            const SizedBox(height: 16),

            _section(context, 'App', [
              _row(
                context,
                Icons.palette_outlined,
                'Appearance',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppearanceScreen(),
                  ),
                ),
              ),
              _row(context, Icons.language_rounded, 'App Language', () {}),
            ]),
            const SizedBox(height: 16),

            _section(context, 'About', [
              _row(context, Icons.flag_outlined, 'Report', () {}),
              _row(context, Icons.help_outline_rounded, 'Help Center', () {}),
              _row(context, Icons.description_outlined, 'Terms of Use', () {}),
              _row(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
            ]),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.read(currentUserProvider.notifier).state = null;
                ref.read(chatProvider.notifier).reset();
                if (context.mounted) context.go('/login');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Center(
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC4C4C),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final cl = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cl.textMid,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: cl.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.border),
          boxShadow: [
            BoxShadow(
              color: cl.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, indent: 48, color: cl.border),
          ],
        ]),
      ),
    ]);
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final cl = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Icon(icon, size: 20, color: cl.textMid),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cl.textDark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: cl.textLight,
            ),
          ]),
        ),
      ),
    );
  }
}
