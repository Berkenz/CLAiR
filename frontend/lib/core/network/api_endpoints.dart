class ApiEndpoints {
  ApiEndpoints._();

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleAuth = '/auth/google';
  static const String googleComplete = '/auth/google/complete';
  static const String guest = '/auth/guest';
  static const String me = '/auth/me';
  static const String deleteAccount = '/auth/account';
  static const String updateProfile = '/users/me';
  static const String uploadProfilePhoto = '/users/me/photo';

  static const String chatSend = '/chat/send';

  static const String lawyerDirectory = '/lawyer/directory';

  static const String appointments = '/appointments';
  static const String appointmentTypes = '/appointments/types';
  static const String appointmentCancellationReasons =
      '/appointments/cancellation-reasons';

  static String appointmentCancel(String id) => '/appointments/$id/cancel';

  static String appointmentMessages(String id) => '/appointments/$id/messages';
  static String appointmentMessagesUpload(String id) =>
      '/appointments/$id/messages/upload';
  static String appointmentMessagesRead(String id) =>
      '/appointments/$id/messages/read';

  static const String notifications = '/notifications';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationDelete(String id) => '/notifications/$id';
  static const String notificationsDeleteAll = '/notifications/all';

  static const String conversations = '/conversations';
  static String conversationDetail(String id) => '/conversations/$id';
  static String conversationUpdate(String id) => '/conversations/$id';
  static String conversationPdf(String id) => '/conversations/$id/pdf';
  static String conversationAppointmentSummary(String id) =>
      '/conversations/$id/appointment-summary';
}
