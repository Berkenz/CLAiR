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

  static const String conversations = '/conversations';
  static String conversationDetail(String id) => '/conversations/$id';
  static String conversationUpdate(String id) => '/conversations/$id';
  static String conversationPdf(String id) => '/conversations/$id/pdf';
  static String conversationAppointmentSummary(String id) =>
      '/conversations/$id/appointment-summary';
}
