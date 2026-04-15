import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class ClairAppBar extends ConsumerWidget {
  final String? chatTitle;
  final List<Widget>? actions;
  final bool showNotificationBell;

  const ClairAppBar({
    super.key,
    this.chatTitle,
    this.actions,
    this.showNotificationBell = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.darkBrown,
                  size: 24,
                ),
              ),

              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Image.asset(
                          'assets/images/CLAiR-icon.png',
                          fit: BoxFit.contain,
                          color: AppColors.darkBrown,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'clair',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBrown,
                          fontFamily: 'Satoshi',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (actions != null) ...actions!,

              if (showNotificationBell) ...[
                GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.tan, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.darkBrown,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tan, width: 1.5),
                  ),
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: user != null
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkBrown,
                                    fontFamily: 'Satoshi',
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.darkBrown,
                                  size: 18,
                                ),
                        ),
                ),
              ),
            ],
          ),

          if (chatTitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                chatTitle!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBrown.withOpacity(0.65),
                  fontFamily: 'Satoshi',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
