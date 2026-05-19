import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/app/main_shell_tab.dart';
import 'package:clair/core/notifications/push_notification_payload.dart';
import 'package:clair/features/appointments/presentation/providers/appointment_provider.dart';

/// Navigate to the correct screen after the user taps a push notification.
Future<void> applyPushNotificationNavigation(
  WidgetRef ref,
  PushNotificationPayload payload,
) async {
  final apptId = payload.appointmentId;
  if (apptId == null || apptId.isEmpty) return;

  final type = payload.notificationType;
  if (type == 'new_direct_message') {
    ref.read(mainShellTabProvider.notifier).state = 4;
    await ref.read(appointmentProvider.notifier).loadAppointments(force: true);
    ref.read(pendingLawyerChatAppointmentIdProvider.notifier).state = apptId;
    return;
  }
  if (type == 'appointment_accepted' ||
      type == 'appointment_rejected' ||
      type == 'appointment_resolved') {
    ref.read(mainShellTabProvider.notifier).state = 4;
    await ref.read(appointmentProvider.notifier).loadAppointments(force: true);
    ref.read(pendingAppointmentDetailIdProvider.notifier).state = apptId;
  }
}
