import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  static const String appName = 'CLAiR';
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    const isProduction =
        bool.fromEnvironment('PRODUCTION', defaultValue: false);
    if (isProduction) {
      return 'https://clair-7icn.onrender.com/api/v1';
    }
    // Android emulator → host loopback. Physical device cannot use 10.0.2.2;
    // run with: flutter run --dart-define=API_BASE_URL=http://YOUR_PC_LAN_IP:8000/api/v1
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}
