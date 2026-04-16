import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class ClairAppBar extends ConsumerWidget {
  final String? chatTitle;
  final List<Widget>? actions;
  final bool showNotificationBell;
  final VoidCallback? onTitleTap;
  final VoidCallback? onActionsTap;
  final VoidCallback? onNewChat;

  const ClairAppBar({
    super.key,
    this.chatTitle,
    this.actions,
    this.showNotificationBell = true,
    this.onTitleTap,
    this.onActionsTap,
    this.onNewChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cl = context.c;

    return Container(
      color: cl.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: Icon(
                  Icons.menu_rounded,
                  color: cl.textDark,
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
                          color: cl.textDark,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'clair',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: cl.textDark,
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
                      color: cl.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: cl.border, width: 1.5),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: cl.textDark,
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
                    color: cl.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: cl.border, width: 1.5),
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
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: cl.textDark,
                                    fontFamily: 'Satoshi',
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline_rounded,
                                  color: cl.textDark,
                                  size: 18,
                                ),
                        ),
                ),
              ),
            ],
          ),

          if (chatTitle != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: onTitleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            chatTitle!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cl.textDark.withOpacity(0.65),
                              fontFamily: 'Satoshi',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onTitleTap != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: cl.textDark.withOpacity(0.45),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onNewChat != null || onActionsTap != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 1,
                    color: cl.border,
                  ),
                  const SizedBox(width: 4),
                ],
                if (onNewChat != null)
                  GestureDetector(
                    onTap: onNewChat,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_square,
                        size: 18,
                        color: cl.textDark.withOpacity(0.55),
                      ),
                    ),
                  ),
                if (onActionsTap != null)
                  GestureDetector(
                    onTap: onActionsTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: cl.textDark.withOpacity(0.55),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
