import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/notifications/push_notification_payload.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:clair/features/notifications/presentation/utils/push_notification_navigation.dart';

/// Handles in-app notification taps from the inbox screen or the realtime banner.
Future<void> handleInAppNotificationTap(
  BuildContext context,
  WidgetRef ref,
  InAppNotificationEntity n, {
  required bool fromNotificationScreen,
}) async {
  await ref.read(notificationInboxProvider.notifier).markRead(n.id);
  if (!context.mounted) return;

  final apptId = n.appointmentId;
  if (apptId != null &&
      (n.notificationType == 'new_direct_message' ||
          n.notificationType == 'appointment_accepted' ||
          n.notificationType == 'appointment_rejected' ||
          n.notificationType == 'appointment_resolved')) {
    await applyPushNotificationNavigation(
      ref,
      PushNotificationPayload(
        notificationType: n.notificationType,
        appointmentId: apptId.trim(),
      ),
    );
    if (!context.mounted) return;
    if (fromNotificationScreen) {
      Navigator.of(context).pop();
    }
    return;
  }
  if (fromNotificationScreen) {
    Navigator.of(context).pop();
  }
}
