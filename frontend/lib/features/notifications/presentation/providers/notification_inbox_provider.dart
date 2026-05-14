import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationRemoteDataSource(dio: api.dio);
});

const _errorUnset = Object();

class NotificationInboxState {
  const NotificationInboxState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<InAppNotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationInboxState copyWith({
    List<InAppNotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    Object? error = _errorUnset,
  }) {
    return NotificationInboxState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorUnset) ? this.error : error as String?,
    );
  }
}

class NotificationInboxNotifier extends StateNotifier<NotificationInboxState> {
  NotificationInboxNotifier(this._remote) : super(const NotificationInboxState());

  final NotificationRemoteDataSource _remote;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _remote.fetchInbox();
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  Future<void> markRead(String notificationId) async {
    await _remote.markRead(notificationId);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _remote.markAllRead();
    await refresh();
  }

  void clearError() => state = state.copyWith(error: null);
}

final notificationInboxProvider =
    StateNotifierProvider<NotificationInboxNotifier, NotificationInboxState>(
  (ref) {
    final remote = ref.watch(notificationRemoteDataSourceProvider);
    return NotificationInboxNotifier(remote);
  },
);
