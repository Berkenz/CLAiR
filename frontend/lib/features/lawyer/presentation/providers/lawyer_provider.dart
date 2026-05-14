import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/lawyer/data/datasources/lawyer_remote_datasource.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final lawyerDataSourceProvider = Provider<LawyerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LawyerRemoteDataSource(dio: apiClient.dio);
});

/// Sentinel so [LawyerState.copyWith] can set `error` to null explicitly.
const _errorUnset = Object();

class LawyerState {
  final List<LawyerEntity> lawyers;
  final bool isLoading;
  final String? error;

  const LawyerState({
    this.lawyers = const [],
    this.isLoading = false,
    this.error,
  });

  LawyerState copyWith({
    List<LawyerEntity>? lawyers,
    bool? isLoading,
    Object? error = _errorUnset,
  }) =>
      LawyerState(
        lawyers: lawyers ?? this.lawyers,
        isLoading: isLoading ?? this.isLoading,
        error: identical(error, _errorUnset) ? this.error : error as String?,
      );
}
/// Notifier for the lawyer provider.
class LawyerNotifier extends StateNotifier<LawyerState> {
  LawyerNotifier(this._dataSource) : super(const LawyerState());

  final LawyerRemoteDataSource _dataSource;

  Future<void> loadLawyers() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _waitForFirebaseSession();
      await _ensureIdTokenReady();
      final lawyers = await _dataSource.getLawyers();
      state = state.copyWith(lawyers: lawyers, isLoading: false, error: null);
    } catch (e) {
      Object report = e;
      if (_looksLikeAuthNotReady(e)) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await _waitForFirebaseSession();
          await _ensureIdTokenReady();
          final lawyers = await _dataSource.getLawyers();
          state = state.copyWith(lawyers: lawyers, isLoading: false, error: null);
          return;
        } catch (e2) {
          report = e2;
        }
      }
      if (_looksLikeUserNotSyncedYet(report)) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          await _ensureIdTokenReady();
          final lawyers = await _dataSource.getLawyers();
          state = state.copyWith(lawyers: lawyers, isLoading: false, error: null);
          return;
        } catch (e3) {
          report = e3;
        }
      }
      state = state.copyWith(isLoading: false, error: report.toString());
    }
  }

  /// After a cold start, [FirebaseAuth.instance.currentUser] can be null for a
  /// short time while the persisted session restores. Directory requests need a
  /// Bearer token, so we wait briefly for a non-null user before calling the API.
  Future<void> _waitForFirebaseSession() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .where((u) => u != null)
          .first
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // No session appeared in time; caller may still try (logged-out user).
    }
  }

  /// Forces a fresh ID token after session restore so the first API call is not
  /// sent with a stale or empty Bearer header.
  Future<void> _ensureIdTokenReady() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true);
    } catch (_) {
      try {
        await user.getIdToken();
      } catch (_) {}
    }
  }

  bool _looksLikeAuthNotReady(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('401') ||
        s.contains('sign in again') ||
        s.contains('authorization') ||
        s.contains('missing or invalid') ||
        s.contains('token unavailable') ||
        s.contains('id token');
  }

  /// Right after sign-up / first launch the backend user row can lag Firebase.
  bool _looksLikeUserNotSyncedYet(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('user not found');
  }

  void clearError() => state = state.copyWith(error: null);
}

final lawyerProvider = StateNotifierProvider<LawyerNotifier, LawyerState>((ref) {
  final dataSource = ref.watch(lawyerDataSourceProvider);
  return LawyerNotifier(dataSource);
});
