import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clair/features/auth/presentation/screens/profile_screen.dart';
import 'package:clair/features/auth/presentation/screens/login_screen.dart';
import 'package:clair/features/lawyer/presentation/screens/lawyer_screen.dart';
import 'package:clair/features/notifications/presentation/screens/notification_screen.dart';
import 'package:clair/app/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const MainShell()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/lawyers', builder: (_, __) => const LawyerFullScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationFullScreen()),
    ],
  );
});
