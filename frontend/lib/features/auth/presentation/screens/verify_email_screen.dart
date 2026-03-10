import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  final String email;
  final bool isPasswordReset;

  @override
  Widget build(BuildContext context) {
    final title = isPasswordReset ? 'Reset Password' : 'Verify Email';
    final heading = isPasswordReset
        ? 'We have sent a password reset link to'
        : 'We have sent a verification link to';
    final body = isPasswordReset
        ? 'Click on the link to reset your password. '
            'You might want to check your spam folder.'
        : 'Click on the link to complete the verification process. '
            'You might want to check your spam folder.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.email_outlined, size: 64),
            const SizedBox(height: 24),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
