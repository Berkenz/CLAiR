import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';
import 'package:clair/features/notifications/presentation/providers/notification_inbox_provider.dart';

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
  if (apptId != null && n.notificationType == 'new_direct_message') {
    ref.read(mainShellTabProvider.notifier).state = 4;
    await ref.read(appointmentProvider.notifier).loadAppointments(force: true);
    if (!context.mounted) return;
    if (fromNotificationScreen) {
      Navigator.of(context).pop();
    }
    ref.read(pendingLawyerChatAppointmentIdProvider.notifier).state =
        apptId.trim();
    return;
  }
  if (apptId != null &&
      (n.notificationType == 'appointment_accepted' ||
          n.notificationType == 'appointment_rejected' ||
          n.notificationType == 'appointment_resolved')) {
    ref.read(mainShellTabProvider.notifier).state = 4;
    await ref.read(appointmentProvider.notifier).loadAppointments(force: true);
    if (!context.mounted) return;
    if (fromNotificationScreen) {
      Navigator.of(context).pop();
    }
    ref.read(pendingAppointmentDetailIdProvider.notifier).state =
        apptId.trim();
    return;
  }
  if (fromNotificationScreen) {
    Navigator.of(context).pop();
  }
}
