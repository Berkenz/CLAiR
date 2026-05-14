import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/features/notifications/presentation/utils/notification_navigation.dart';
import 'package:clair/l10n/app_localizations.dart';

Future<void> _confirmDeleteNotification(
  BuildContext context,
  WidgetRef ref,
  InAppNotificationEntity n,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cl = context.c;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        l10n.notifDeleteConfirmTitle,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: cl.textDark,
        ),
      ),
      content: Text(
        l10n.notifDeleteConfirmBody,
        style: GoogleFonts.nunito(fontSize: 14, color: cl.textMid, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.commonCancel,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: cl.textMid,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.commonDelete,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: Colors.red.shade700,
            ),
          ),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await ref.read(notificationInboxProvider.notifier).deleteNotification(n.id);
  }
}

Future<void> _confirmClearAllNotifications(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cl = context.c;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        l10n.notifClearAllConfirmTitle,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: cl.textDark,
        ),
      ),
      content: Text(
        l10n.notifClearAllConfirmBody,
        style: GoogleFonts.nunito(fontSize: 14, color: cl.textMid, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            l10n.commonCancel,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: cl.textMid,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.notifClearAll,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: Colors.red.shade700,
            ),
          ),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await ref.read(notificationInboxProvider.notifier).clearAllNotifications();
  }
}

/// Standalone page with back button (for /notifications route)
class NotificationFullScreen extends ConsumerStatefulWidget {
  const NotificationFullScreen({super.key});

  @override
  ConsumerState<NotificationFullScreen> createState() =>
      _NotificationFullScreenState();
}

class _NotificationFullScreenState extends ConsumerState<NotificationFullScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationInboxProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    return Scaffold(
      backgroundColor: cl.bg,
      body: SafeArea(
        child: _NotificationBody(
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class _NotificationBody extends ConsumerWidget {
  const _NotificationBody({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.c;
    final l10n = AppLocalizations.of(context)!;
    final inbox = ref.watch(notificationInboxProvider);

    ref.listen<NotificationInboxState>(notificationInboxProvider, (prev, next) {
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        ref.read(notificationInboxProvider.notifier).clearError();
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cl.surface, cl.bg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: Icon(Icons.arrow_back_rounded, color: cl.textDark),
                  ),
                Expanded(
                  child: Text(
                    l10n.notifications,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cl.textDark,
                    ),
                  ),
                ),
                if (inbox.unreadCount > 0)
                  TextButton(
                    onPressed: inbox.isLoading
                        ? null
                        : () => ref
                            .read(notificationInboxProvider.notifier)
                            .markAllRead(),
                    child: Text(
                      l10n.notifMarkAllRead,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cl.accent,
                      ),
                    ),
                  ),
                if (inbox.notifications.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: cl.textDark),
                    enabled: !inbox.isLoading,
                    onSelected: (value) {
                      if (value == 'clear') {
                        _confirmClearAllNotifications(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'clear',
                        child: Text(
                          l10n.notifClearAll,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: inbox.isLoading && inbox.notifications.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: cl.accent),
                  )
                : RefreshIndicator(
                    color: cl.accent,
                    onRefresh: () =>
                        ref.read(notificationInboxProvider.notifier).refresh(),
                    child: inbox.notifications.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.35,
                              ),
                              Center(
                                child: Text(
                                  l10n.notifEmpty,
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    color: cl.textMid,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            itemCount: inbox.notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final n = inbox.notifications[i];
                              return _NotificationTile(
                                notification: n,
                                onTap: () => handleInAppNotificationTap(
                                  context,
                                  ref,
                                  n,
                                  fromNotificationScreen: true,
                                ),
                                onDelete: () =>
                                    _confirmDeleteNotification(context, ref, n),
                                deleteTooltip: l10n.notifDeleteTooltip,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.deleteTooltip,
  });

  final InAppNotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final cl = context.c;
    final unread = !notification.isRead;
    final icon = switch (notification.notificationType) {
      'appointment_accepted' => Icons.check_circle_outline_rounded,
      'appointment_rejected' => Icons.cancel_outlined,
      'new_direct_message' => Icons.chat_bubble_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        color: unread ? cl.surface : cl.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unread
              ? cl.accent.withValues(alpha: 0.22)
              : cl.border,
        ),
        boxShadow: unread
            ? [
                BoxShadow(
                  color: cl.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: unread
                                ? cl.accent.withValues(alpha: 0.1)
                                : cl.border.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: unread ? cl.accent : cl.textMid,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: cl.textDark,
                                      ),
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              if (notification.body != null &&
                                  notification.body!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notification.body!.trim(),
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    color: cl.textMid,
                                    height: 1.4,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(notification.createdAt),
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: cl.textLight,
                                ),
                              ),
                              if (notification.appointmentId != null &&
                                  (notification.notificationType ==
                                          'appointment_accepted' ||
                                      notification.notificationType ==
                                          'appointment_rejected')) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Tap to view appointment',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cl.accent,
                                  ),
                                ),
                              ],
                              if (notification.appointmentId != null &&
                                  notification.notificationType ==
                                      'new_direct_message') ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Tap to open chat',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cl.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: deleteTooltip,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: cl.textLight,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(local);
  }
}
