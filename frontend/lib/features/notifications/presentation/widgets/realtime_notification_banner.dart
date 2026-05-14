import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/features/notifications/presentation/utils/notification_navigation.dart';
import 'package:clair/l10n/app_localizations.dart';

/// Top-of-app banner when a new unread notification arrives (driven by inbox polling).
class RealtimeNotificationBanner extends ConsumerWidget {
  const RealtimeNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final pending = ref.watch(notificationInboxProvider).pendingRealtimeBanner;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: pending == null
          ? const SizedBox.shrink(key: ValueKey('notif-banner-empty'))
          : Material(
              key: ValueKey('notif-banner-${pending.id}'),
              elevation: 6,
              shadowColor: cl.textDark.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              color: cl.surface,
              child: InkWell(
                onTap: () {
                  handleInAppNotificationTap(
                    context,
                    ref,
                    pending,
                    fromNotificationScreen: false,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cl.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: cl.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                pending.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: cl.textDark,
                                  height: 1.25,
                                ),
                              ),
                              if (pending.body != null &&
                                  pending.body!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  pending.body!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    color: cl.textMid,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.notifBannerDismissTooltip,
                          onPressed: () => ref
                              .read(notificationInboxProvider.notifier)
                              .dismissPendingBanner(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: cl.textLight,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
