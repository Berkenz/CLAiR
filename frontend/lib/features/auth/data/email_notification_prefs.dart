import 'package:shared_preferences/shared_preferences.dart';

/// Local email notification preference keys (client-side until backend prefs exist).
class EmailNotificationPrefs {
  EmailNotificationPrefs._();

  static const caseActivity = 'email_pref_case_activity';
  static const appointments = 'email_pref_appointments';
  static const legalTips = 'email_pref_legal_tips';
  static const newsletter = 'email_pref_newsletter';
  static const inAppAlerts = 'pref_in_app_alerts';

  /// Whether realtime in-app notification banners may be shown.
  static Future<bool> inAppAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(inAppAlerts) ?? true;
  }

  static Future<EmailNotificationPrefsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EmailNotificationPrefsState(
      caseActivity: prefs.getBool(caseActivity) ?? true,
      appointments: prefs.getBool(appointments) ?? true,
      legalTips: prefs.getBool(legalTips) ?? true,
      newsletter: prefs.getBool(newsletter) ?? false,
    );
  }

  static Future<void> save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}

class EmailNotificationPrefsState {
  const EmailNotificationPrefsState({
    required this.caseActivity,
    required this.appointments,
    required this.legalTips,
    required this.newsletter,
  });

  final bool caseActivity;
  final bool appointments;
  final bool legalTips;
  final bool newsletter;
}
