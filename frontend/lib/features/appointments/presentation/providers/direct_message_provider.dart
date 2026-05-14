import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/appointments/data/datasources/direct_message_datasource.dart';
import 'package:clair/features/appointments/domain/entities/direct_message_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

// ── Data source provider ──────────────────────────────────────────────────────

final directMessageDataSourceProvider = Provider<DirectMessageDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DirectMessageDataSource(dio: apiClient.dio);
});

// ── State ─────────────────────────────────────────────────────────────────────

const _errUnset = Object();

class DirectMessageState {
  const DirectMessageState({
    this.messages = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  final List<DirectMessageEntity> messages;
  final int unreadCount;
  final bool isLoading;
  final bool isSending;
  final String? error;

  DirectMessageState copyWith({
    List<DirectMessageEntity>? messages,
    int? unreadCount,
    bool? isLoading,
    bool? isSending,
    Object? error = _errUnset,
  }) {
    return DirectMessageState(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: identical(error, _errUnset) ? this.error : error as String?,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DirectMessageNotifier extends StateNotifier<DirectMessageState> {
  DirectMessageNotifier(this._dataSource, this._appointmentId)
      : super(const DirectMessageState());

  final DirectMessageDataSource _dataSource;
  final String _appointmentId;

  Timer? _pollTimer;
  bool _tearDown = false;

  void _setState(DirectMessageState next) {
    if (_tearDown) return;
    final captured = next;
    // Let Riverpod / Element detach finish before notifying (avoids defunct
    // ConsumerStatefulElement when list cells or routes churn in the same frame).
    scheduleMicrotask(() {
      if (_tearDown) return;
      try {
        state = captured;
      } on AssertionError {
        // Rare: a dependent was disposed mid-notify; drop this emission.
      }
    });
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void startPolling() {
    loadMessages();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    try {
      final result = await _dataSource.listMessages(_appointmentId);
      if (_tearDown) return;
      _setState(state.copyWith(
        messages: result.messages,
        unreadCount: result.unreadCount,
        error: null,
      ));
    } catch (_) {
      // Polling failures are silent — the user sees stale data but no error
    }
  }

  // ── Initial load ───────────────────────────────────────────────────────────

  Future<void> loadMessages() async {
    if (_tearDown) return;
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _dataSource.listMessages(_appointmentId);
      if (_tearDown) return;
      _setState(state.copyWith(
        messages: result.messages,
        unreadCount: result.unreadCount,
        isLoading: false,
        error: null,
      ));
      // Mark incoming messages as read
      await _dataSource.markRead(_appointmentId);
    } catch (e) {
      if (_tearDown) return;
      _setState(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // ── Send text ──────────────────────────────────────────────────────────────

  Future<bool> sendMessage(String content) async {
    if (state.isSending) return false;
    _setState(state.copyWith(isSending: true, error: null));
    try {
      final msg = await _dataSource.sendMessage(_appointmentId, content);
      if (_tearDown) return false;
      _setState(state.copyWith(
        messages: [...state.messages, msg],
        isSending: false,
      ));
      return true;
    } catch (e) {
      if (_tearDown) return false;
      _setState(state.copyWith(isSending: false, error: e.toString()));
      return false;
    }
  }

  // ── Send attachment ────────────────────────────────────────────────────────

  Future<bool> sendAttachment({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    if (state.isSending) return false;
    _setState(state.copyWith(isSending: true, error: null));
    try {
      final msg = await _dataSource.uploadAttachment(
        _appointmentId,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        caption: caption,
      );
      if (_tearDown) return false;
      _setState(state.copyWith(
        messages: [...state.messages, msg],
        isSending: false,
      ));
      return true;
    } catch (e) {
      if (_tearDown) return false;
      _setState(state.copyWith(isSending: false, error: e.toString()));
      return false;
    }
  }

  /// Fetches the unread count without loading all messages or marking as read.
  /// Safe to call from list-view cards for badge display.
  Future<void> fetchCountOnly() async {
    if (state.isLoading || state.messages.isNotEmpty) return;
    try {
      final result = await _dataSource.listMessages(_appointmentId);
      if (_tearDown) return;
      _setState(state.copyWith(unreadCount: result.unreadCount));
    } catch (_) {
      // Silently ignore — badge just stays at 0.
    }
  }

  void clearError() {
    if (_tearDown) return;
    _setState(state.copyWith(error: null));
  }

  @override
  void dispose() {
    _tearDown = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }
}

// ── Provider factory ──────────────────────────────────────────────────────────

final directMessageProvider = StateNotifierProvider.autoDispose.family<
    DirectMessageNotifier, DirectMessageState, String>(
  (ref, appointmentId) {
    final dataSource = ref.watch(directMessageDataSourceProvider);
    return DirectMessageNotifier(dataSource, appointmentId);
  },
);
