import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clair/features/auth/presentation/screens/profile_screen.dart';
import 'package:clair/features/auth/presentation/screens/login_screen.dart';
import 'package:clair/app/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    // Redirect re-enabled when real auth is wired up:
    // redirect: (context, state) {
    //   final isLoggedIn = authState.valueOrNull != null;
    //   final isLoggingIn = state.matchedLocation == '/';
    //   if (!isLoggedIn && !isLoggingIn) return '/';
    //   if (isLoggedIn && isLoggingIn) return '/home';
    //   return null;
    // },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
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
