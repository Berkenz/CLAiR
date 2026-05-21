import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/chat/presentation/providers/chat_provider.dart';
import 'package:clair/features/history/presentation/providers/history_provider.dart';

/// Clears and reloads user-scoped providers when the signed-in account changes.
void applyUserSessionChange(
  WidgetRef ref, {
  UserEntity? previous,
  UserEntity? next,
}) {
  if (previous?.id == next?.id) return;

  ref.read(historyProvider.notifier).reset();
  ref.read(chatProvider.notifier).reset();

  if (next != null && !next.isAnonymous) {
    ref.read(historyProvider.notifier).syncWithUser(next.id);
  }
}
