import 'package:clair/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  });
  Future<GoogleAuthResult> signInWithGoogle();
  Future<UserEntity> completeGoogleRegistration({
    required String firstName,
    required String lastName,
  });
  Future<UserEntity> signInAsGuest();
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
}
