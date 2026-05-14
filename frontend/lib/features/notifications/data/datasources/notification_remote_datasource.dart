import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({List<InAppNotificationEntity> notifications, int unreadCount})>
      fetchInbox() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
      );
      final data = response.data;
      if (data == null) {
        return (notifications: <InAppNotificationEntity>[], unreadCount: 0);
      }
      final list = data['notifications'] as List<dynamic>? ?? [];
      final unread = data['unread_count'];
      final unreadCount = unread is int
          ? unread
          : (unread is num ? unread.toInt() : 0);
      return (
        notifications: list
            .map((e) => InAppNotificationEntity.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
        unreadCount: unreadCount,
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _dio.patch<void>(
        ApiEndpoints.notificationMarkRead(notificationId),
      );
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post<void>(ApiEndpoints.notificationsReadAll);
    } on DioException catch (e) {
      throw NotificationApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    }
    return 'Could not load notifications.';
  }
}

class NotificationApiException implements Exception {
  NotificationApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
