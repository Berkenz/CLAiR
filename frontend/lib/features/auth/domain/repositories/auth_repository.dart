import 'package:clair/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> getCurrentUser();
}
