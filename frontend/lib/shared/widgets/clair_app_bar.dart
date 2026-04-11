import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class ClairAppBar extends ConsumerWidget {
  final String? chatTitle;
  final Widget? trailing;
  final bool showDrawer;
  const ClairAppBar({super.key, this.chatTitle, this.trailing, this.showDrawer = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.textDark.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          if (showDrawer)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark, size: 22),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          if (chatTitle != null)
            Text(chatTitle!, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark))
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (trailing != null)
            trailing!
          else ...[
            // Notification bell
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.fieldBg, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, color: AppColors.textMid, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            // Profile avatar
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: user?.photoUrl != null
                    ? ClipOval(child: Image.network(user!.photoUrl!, fit: BoxFit.cover))
                    : Center(child: user?.displayName != null
                        ? Text(user!.displayName![0].toUpperCase(), style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent))
                        : const Icon(Icons.person_outline_rounded, color: AppColors.textMid, size: 18)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}
