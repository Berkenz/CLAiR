import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last known profile-photo cache-bust (ms) per user across app restarts.
class ProfilePhotoBustStore {
  ProfilePhotoBustStore._();

  static String _key(String userId) => 'profile_photo_bust_$userId';

  static Future<void> save(String userId, int bustMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(userId), bustMs);
  }

  static Future<int?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(userId));
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

/// Prefer the newest bust timestamp we know about (device upload vs server updated_at).
int? effectiveProfilePhotoBust({
  required int? serverUpdatedAtMs,
  int? localBustMs,
}) {
  if (serverUpdatedAtMs == null) return localBustMs;
  if (localBustMs == null) return serverUpdatedAtMs;
  return serverUpdatedAtMs > localBustMs ? serverUpdatedAtMs : localBustMs;
}
