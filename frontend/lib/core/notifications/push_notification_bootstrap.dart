import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/notifications/push_notification_service.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

/// Initializes FCM and syncs the device token when the user is signed in.
class PushNotificationBootstrap extends ConsumerStatefulWidget {
  const PushNotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrap> createState() =>
      _PushNotificationBootstrapState();
}

class _PushNotificationBootstrapState
    extends ConsumerState<PushNotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(pushNotificationServiceProvider).initialize();
      final user = ref.read(currentUserProvider);
      if (user != null && user.isAnonymous != true) {
        await ref.read(pushNotificationServiceProvider).syncTokenWithBackend();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && next.isAnonymous != true) {
        ref.read(pushNotificationServiceProvider).syncTokenWithBackend();
      }
    });
    return widget.child;
  }
}
