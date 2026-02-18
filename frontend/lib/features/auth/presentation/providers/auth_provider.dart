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

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});

class SignInNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
    });
  }
}

final signInWithGoogleProvider =
    AsyncNotifierProvider<SignInNotifier, void>(() => SignInNotifier());
