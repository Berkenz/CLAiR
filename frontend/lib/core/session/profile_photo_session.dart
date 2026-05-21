import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/session/profile_photo_bust_store.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

int? _serverPhotoBustMs(UserEntity user) =>
    user.updatedAt?.toUtc().millisecondsSinceEpoch;

/// Applies server user + syncs local cache-bust from [updated_at] / persisted value.
Future<void> syncProfilePhotoBust(WidgetRef ref, UserEntity user) async {
  final saved = await ProfilePhotoBustStore.load(user.id);
  final bust = effectiveProfilePhotoBust(
    serverUpdatedAtMs: _serverPhotoBustMs(user),
    localBustMs: saved,
  );
  ref.read(profilePhotoCacheVersionProvider.notifier).state = bust;
}

/// Updates in-memory user and forces a new image fetch after photo upload.
Future<void> applyProfilePhotoUpdate(WidgetRef ref, UserEntity user) async {
  ref.read(currentUserProvider.notifier).state = user;
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  final bust = effectiveProfilePhotoBust(
    serverUpdatedAtMs: _serverPhotoBustMs(user),
    localBustMs: now,
  ) ?? now;
  ref.read(profilePhotoCacheVersionProvider.notifier).state = bust;
  await ProfilePhotoBustStore.save(user.id, bust);
}

/// Reloads the signed-in user from the API (source of truth for photo_url).
Future<UserEntity?> refreshCurrentUser(WidgetRef ref) async {
  final user = await ref.read(authRepositoryProvider).getCurrentUser();
  if (user != null) {
    ref.read(currentUserProvider.notifier).state = user;
    await syncProfilePhotoBust(ref, user);
  }
  return user;
}

Future<void> resetProfilePhotoCache(WidgetRef ref, {String? userId}) async {
  ref.read(profilePhotoCacheVersionProvider.notifier).state = null;
  if (userId != null) {
    await ProfilePhotoBustStore.clear(userId);
  }
}
