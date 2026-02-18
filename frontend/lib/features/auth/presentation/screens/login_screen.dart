import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/constants/app_constants.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInState = ref.watch(signInWithGoogleProvider);

    ref.listen<AsyncValue<void>>(signInWithGoogleProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.toString().replaceFirst('Exception: ', ''),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const Spacer(flex: 2),
              GoogleSignInButton(
                onPressed: () {
                  ref.read(signInWithGoogleProvider.notifier).signInWithGoogle();
                },
                isLoading: signInState.isLoading,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
