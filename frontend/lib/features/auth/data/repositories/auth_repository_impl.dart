import 'package:clair/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      return await _remoteDataSource.signInWithGoogle();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges;

  @override
  Future<UserEntity?> getCurrentUser() =>
      _remoteDataSource.getCurrentUser();
}
