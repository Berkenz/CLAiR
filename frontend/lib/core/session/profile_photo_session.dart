import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/shared/utils/profile_photo_url.dart';

/// Updates in-memory user and bumps avatar cache after a successful photo upload.
void applyProfilePhotoUpdate(WidgetRef ref, UserEntity user) {
  ref.read(currentUserProvider.notifier).state = user;
  ref.read(profilePhotoCacheVersionProvider.notifier).update((v) => v + 1);
}

/// Clears Flutter's decoded image cache for the previous avatar URL.
void evictProfilePhotoCache({
  required String? previousPhotoUrl,
  DateTime? previousUpdatedAt,
  int? previousCacheVersion,
}) {
  final url = profilePhotoDisplayUrl(
    previousPhotoUrl,
    updatedAt: previousUpdatedAt,
    cacheVersion: previousCacheVersion,
  );
  if (url != null) {
    NetworkImage(url).evict();
  }
}

void resetProfilePhotoCache(WidgetRef ref) {
  ref.read(profilePhotoCacheVersionProvider.notifier).state = 0;
}
