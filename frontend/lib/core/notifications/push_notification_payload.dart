/// Parsed FCM data payload for deep linking.
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.notificationType,
    this.appointmentId,
  });

  final String notificationType;
  final String? appointmentId;

  factory PushNotificationPayload.fromData(Map<String, dynamic> data) {
    final type = '${data['notification_type'] ?? ''}'.trim();
    final apptRaw = data['appointment_id'];
    final appt = apptRaw?.toString().trim();
    return PushNotificationPayload(
      notificationType: type,
      appointmentId: (appt == null || appt.isEmpty) ? null : appt,
    );
  }
}
