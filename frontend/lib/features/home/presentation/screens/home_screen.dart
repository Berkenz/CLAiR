import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hello, ${user?.displayName ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 8),
              Text(user!.email!),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(authRepositoryProvider);
                await repo.signOut();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) context.go('/');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
