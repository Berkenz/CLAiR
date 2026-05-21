import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/core/theme/app_colors.dart';
import 'package:clair/core/utils/error_helpers.dart';
import 'package:clair/core/session/user_session.dart';
import 'package:clair/features/auth/presentation/providers/auth_provider.dart';

/// Shown when a Google sign-in user is new and needs to provide their name.
class GoogleCompleteScreen extends ConsumerStatefulWidget {
  const GoogleCompleteScreen({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  final String firstName;
  final String lastName;

  @override
  ConsumerState<GoogleCompleteScreen> createState() =>
      _GoogleCompleteScreenState();
}

class _GoogleCompleteScreenState extends ConsumerState<GoogleCompleteScreen> {
  bool _loading = false;

  Future<void> _complete() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.completeGoogleRegistration(
        firstName: widget.firstName,
        lastName: widget.lastName,
      );
      final previous = ref.read(currentUserProvider);
      ref.read(currentUserProvider.notifier).state = user;
      applyUserSessionChange(ref, previous: previous, next: user);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
            backgroundColor: context.c.crimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _complete,
                child: const Text('Retry'),
              ),
      ),
    );
  }
}
