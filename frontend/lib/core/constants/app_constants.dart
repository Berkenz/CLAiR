import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  static const String appName = 'CLAiR';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}
