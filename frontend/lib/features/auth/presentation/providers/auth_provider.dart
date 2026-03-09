import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:clair/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/domain/repositories/auth_repository.dart';
import 'package:clair/shared/providers/shared_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteDataSource = AuthRemoteDataSource(dio: apiClient.dio);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

// FRONTEND DEV MODE: Mock user state
final mockUserStateProvider = StateProvider<UserEntity?>((ref) => null);

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  // COMMENTED OUT FOR FRONTEND DEVELOPMENT
  // Uncomment when backend is ready
  /*
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
  */
  
  // Mock user for frontend development
  final mockUser = ref.watch(mockUserStateProvider);
  return Stream.value(mockUser);
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  // COMMENTED OUT FOR FRONTEND DEVELOPMENT
  // Uncomment when backend is ready
  /*
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
  */
  
  // Mock user for frontend development
  final mockUser = ref.watch(mockUserStateProvider);
  return Future.value(mockUser);
});

class SignInNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    // COMMENTED OUT FOR FRONTEND DEVELOPMENT
    // Uncomment when backend is ready
    /*
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
    });
    */
    
    // Mock successful sign-in for frontend development
    await Future.delayed(const Duration(seconds: 1));
    
    // Set mock user to simulate login (triggers navigation to home)
    ref.read(mockUserStateProvider.notifier).state = UserEntity(
      id: 'mock-123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: null,
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    state = const AsyncData(null);
  }
}

final signInWithGoogleProvider =
    AsyncNotifierProvider<SignInNotifier, void>(() => SignInNotifier());
