import 'dart:io' show Platform;

class AppConstants {
  AppConstants._();

  static const String appName = 'CLAiR';

  static String get baseUrl {
    const isProduction =
        bool.fromEnvironment('PRODUCTION', defaultValue: false);
    if (isProduction) {
      return 'https://clair-7icn.onrender.com/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}
