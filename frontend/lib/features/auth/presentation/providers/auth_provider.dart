import 'package:firebase_auth/firebase_auth.dart';
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

/// Watches Firebase auth state to know if anyone is signed in at all.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Holds the current app user fetched from the backend.
/// Set after successful login/register/guest flows.
final currentUserProvider =
    StateProvider<UserEntity?>((ref) => null);
