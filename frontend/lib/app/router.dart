import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clair/features/auth/presentation/providers/auth_provider.dart';
import 'package:clair/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:clair/features/auth/presentation/screens/google_complete_screen.dart';
import 'package:clair/features/auth/presentation/screens/login_screen.dart';
import 'package:clair/features/auth/presentation/screens/email_screen.dart';
import 'package:clair/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:clair/features/auth/presentation/screens/profile_screen.dart';
import 'package:clair/features/auth/presentation/screens/report_screen.dart';
import 'package:clair/features/auth/presentation/screens/security_screen.dart';
import 'package:clair/features/auth/presentation/screens/signup_name_screen.dart';
import 'package:clair/features/auth/presentation/screens/signup_screen.dart';
import 'package:clair/features/auth/presentation/screens/terms_of_use_screen.dart';
import 'package:clair/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:clair/features/chat/presentation/screens/chat_screen.dart';
import 'package:clair/features/history/presentation/screens/history_screen.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_screen.dart';
import 'package:clair/features/auth/presentation/screens/notification_settings_screen.dart';
import 'package:clair/features/notifications/presentation/screens/notification_screen.dart';
import 'package:clair/app/main_shell.dart';
import 'package:clair/app/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Never redirect away from the splash screen — let it handle navigation.
      if (state.matchedLocation.startsWith('/splash')) return null;

      final user = ref.read(currentUserProvider);
      final isOnAuthPage = state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/verify-email') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/terms') ||
          state.matchedLocation.startsWith('/privacy-policy');

      final isLegalPage = state.matchedLocation.startsWith('/terms') ||
          state.matchedLocation.startsWith('/privacy-policy');

      if (user != null && user.isAnonymous != true && isOnAuthPage && !isLegalPage) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/signup/google',
        builder: (context, state) =>
            const SignUpNameScreen(isGoogleFlow: true),
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
          return VerifyEmailScreen(
            email: extra['email'] as String,
            isPasswordReset: extra['is_password_reset'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/lawyers',
        builder: (context, state) => const LawyerFullScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationFullScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/email-settings',
        builder: (context, state) => const EmailScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
});
