import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/constants/app_constants.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.displayName ?? user?.email ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium,
                      )
                    : null,
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.displayName ?? user?.email ?? 'User'}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are signed in successfully.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final repository = ref.read(authRepositoryProvider);
                    await repository.signOut();
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
