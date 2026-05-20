import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/features/auth/data/email_notification_prefs.dart';
import 'package:clair/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:clair/features/notifications/domain/entities/in_app_notification_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationRemoteDataSource(dio: api.dio);
});

const _errorUnset = Object();
const _bannerUnset = Object();

class NotificationInboxState {
  const NotificationInboxState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.pendingRealtimeBanner,
  });

  final List<InAppNotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  /// Newest unread item detected since the last inbox snapshot (for banner UI).
  final InAppNotificationEntity? pendingRealtimeBanner;

  NotificationInboxState copyWith({
    List<InAppNotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    Object? error = _errorUnset,
    Object? pendingRealtimeBanner = _bannerUnset,
  }) {
    return NotificationInboxState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _errorUnset) ? this.error : error as String?,
      pendingRealtimeBanner: identical(pendingRealtimeBanner, _bannerUnset)
          ? this.pendingRealtimeBanner
          : pendingRealtimeBanner as InAppNotificationEntity?,
    );
  }
}

class NotificationInboxNotifier extends StateNotifier<NotificationInboxState> {
  NotificationInboxNotifier(this._remote) : super(const NotificationInboxState());

  final NotificationRemoteDataSource _remote;

  final Set<String> _bannerBaselineIds = {};
  DateTime? _inboxMaxCreatedAtWatermark;
  bool _bannerPrimed = false;
  bool _silentPollInFlight = false;

  InAppNotificationEntity? _computeBannerAfterFetch(
    List<InAppNotificationEntity> notifications,
  ) {
    DateTime? maxCreatedThis;
    for (final n in notifications) {
      if (maxCreatedThis == null || n.createdAt.isAfter(maxCreatedThis)) {
        maxCreatedThis = n.createdAt;
      }
    }

    final prevIds = Set<String>.from(_bannerBaselineIds);
    final prevWatermark = _inboxMaxCreatedAtWatermark;

    final ids = notifications.map((n) => n.id).where((id) => id.isNotEmpty).toSet();
    _bannerBaselineIds
      ..clear()
      ..addAll(ids);

    if (maxCreatedThis != null) {
      final wm = _inboxMaxCreatedAtWatermark;
      if (wm == null || maxCreatedThis.isAfter(wm)) {
        _inboxMaxCreatedAtWatermark = maxCreatedThis;
      }
    }

    if (!_bannerPrimed) {
      _bannerPrimed = true;
      return null;
    }

    final newcomers = <InAppNotificationEntity>[];
    final seen = <String>{};
    for (final n in notifications) {
      if (n.isRead || n.id.isEmpty) continue;
      final idNew = !prevIds.contains(n.id);
      final timeNew =
          prevWatermark != null && n.createdAt.isAfter(prevWatermark);
      if (idNew || timeNew) {
        if (seen.add(n.id)) newcomers.add(n);
      }
    }

    if (newcomers.isNotEmpty) {
      newcomers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return newcomers.first;
    }

    final cur = state.pendingRealtimeBanner;
    if (cur != null) {
      InAppNotificationEntity? match;
      for (final n in notifications) {
        if (n.id == cur.id) {
          match = n;
          break;
        }
      }
      return (match != null && !match.isRead) ? cur : null;
    }
    return null;
  }

  Future<InAppNotificationEntity?> _bannerForFetch(
    List<InAppNotificationEntity> notifications,
  ) async {
    final computed = _computeBannerAfterFetch(notifications);
    if (!await EmailNotificationPrefs.inAppAlertsEnabled()) return null;
    return computed;
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _remote.fetchInbox();
      final banner = await _bannerForFetch(result.notifications);
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        isLoading: false,
        error: null,
        pendingRealtimeBanner: banner,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  /// Lightweight poll while the main shell is visible (no loading spinner).
  Future<void> pollSilently() async {
    if (_silentPollInFlight || state.isLoading) return;
    _silentPollInFlight = true;
    try {
      final result = await _remote.fetchInbox();
      final banner = await _bannerForFetch(result.notifications);
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        pendingRealtimeBanner: banner,
      );
    } catch (_) {
      // Ignore transient failures for background polls.
    } finally {
      _silentPollInFlight = false;
    }
  }

  void dismissPendingBanner() {
    state = state.copyWith(pendingRealtimeBanner: null);
  }

  Future<void> markRead(String notificationId) async {
    await _remote.markRead(notificationId);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _remote.markAllRead();
    await refresh();
  }

  Future<void> deleteNotification(String notificationId) async {
    final id = notificationId.trim();
    if (id.isEmpty) return;
    await _remote.deleteNotification(id);
    await refresh();
  }

  Future<void> clearAllNotifications() async {
    await _remote.deleteAllNotifications();
    await refresh();
  }

  /// Marks unread inbox rows whose payload matches [appointmentId].
  ///
  /// When [notificationTypes] is provided, only notifications whose
  /// [InAppNotificationEntity.notificationType] is in the set are touched.
  /// This prevents opening an appointment detail from also clearing unread
  /// DM notifications that the user hasn't viewed yet.
  Future<void> markReadForAppointment(
    String appointmentId, {
    Set<String>? notificationTypes,
  }) async {
    final id = appointmentId.trim();
    if (id.isEmpty) return;

    List<String> unreadIdsForAppt() {
      return state.notifications
          .where(
            (n) =>
                !n.isRead &&
                n.appointmentId != null &&
                n.appointmentId == id &&
                (notificationTypes == null ||
                    notificationTypes.contains(n.notificationType)),
          )
          .map((n) => n.id)
          .toList();
    }

    var ids = unreadIdsForAppt();
    if (ids.isEmpty) {
      await refresh();
      ids = unreadIdsForAppt();
    }
    if (ids.isEmpty) return;

    for (final nid in ids) {
      try {
        await _remote.markRead(nid);
      } catch (_) {
        // One failure should not block the rest.
      }
    }
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
