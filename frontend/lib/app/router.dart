import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:clair/features/auth/presentation/screens/google_complete_screen.dart';
import 'package:clair/features/auth/presentation/screens/landing_screen.dart';
import 'package:clair/features/auth/presentation/screens/login_screen.dart';
import 'package:clair/features/auth/presentation/screens/signup_email_screen.dart';
import 'package:clair/features/auth/presentation/screens/signup_name_screen.dart';
import 'package:clair/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:clair/features/auth/presentation/screens/profile_screen.dart';
import 'package:clair/app/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isOnAuthPage = state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/verify-email') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (user != null && isOnAuthPage) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isGoogleFlow = extra?['is_google_flow'] as bool? ?? false;
          return SignUpNameScreen(isGoogleFlow: isGoogleFlow);
        },
      ),
      GoRoute(
        path: '/signup/email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SignUpEmailScreen(
            firstName: extra['first_name'] as String,
            lastName: extra['last_name'] as String,
          );
        },
      ),
      GoRoute(
        path: '/signup/google-complete',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return GoogleCompleteScreen(
            firstName: extra['first_name'] as String,
            lastName: extra['last_name'] as String,
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VerifyEmailScreen(email: extra['email'] as String);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
