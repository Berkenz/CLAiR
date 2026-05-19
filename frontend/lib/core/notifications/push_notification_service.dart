import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/core/notifications/push_notification_payload.dart';
import 'package:clair/firebase_options.dart';
import 'package:clair/shared/providers/shared_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _androidChannelId = 'clair_notifications';
const _androidChannelName = 'CLAiR notifications';

/// Background FCM handler (required top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Pending navigation from a notification tap (cold start / background).
final pendingPushNotificationProvider =
    StateProvider<PushNotificationPayload?>((ref) => null);

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !Platform.isAndroid) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              importance: Importance.high,
            ),
          );
    }

    await _messaging.requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _queueNavigation(initial);
    }

    _messaging.onTokenRefresh.listen((_) => syncTokenWithBackend());
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    if (parts.length < 2) return;
    _ref.read(pendingPushNotificationProvider.notifier).state =
        PushNotificationPayload(
      notificationType: parts[0],
      appointmentId: parts[1].isEmpty ? null : parts[1],
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final type = data['notification_type'] ?? '';
    final apptId = data['appointment_id'] ?? '';

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: '$type|$apptId',
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    _queueNavigation(message);
  }

  void _queueNavigation(RemoteMessage message) {
    final payload = PushNotificationPayload.fromData(message.data);
    if (payload.notificationType.isEmpty) return;
    _ref.read(pendingPushNotificationProvider.notifier).state = payload;
  }

  Future<void> syncTokenWithBackend() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final dio = _ref.read(apiClientProvider).dio;
      await dio.put<void>(
        ApiEndpoints.registerFcmToken,
        data: {'token': token},
      );
    } catch (e, st) {
      debugPrint('FCM token sync failed: $e\n$st');
    }
  }

  Future<void> clearTokenOnBackend() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final dio = _ref.read(apiClientProvider).dio;
      await dio.delete<void>(ApiEndpoints.registerFcmToken);
    } catch (_) {}
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
