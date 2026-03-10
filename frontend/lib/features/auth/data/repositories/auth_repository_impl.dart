import 'package:clair/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';
import 'package:clair/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final AuthRemoteDataSource _remote;

  @override
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) =>
      _remote.registerWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

  @override
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) =>
      _remote.loginWithEmail(email: email, password: password);

  @override
  Future<GoogleAuthResult> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<UserEntity> completeGoogleRegistration({
    required String firstName,
    required String lastName,
  }) =>
      _remote.completeGoogleRegistration(
        firstName: firstName,
        lastName: lastName,
      );

  @override
  Future<UserEntity> signInAsGuest() => _remote.signInAsGuest();

  @override
  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? location,
  }) =>
      _remote.updateProfile(
        firstName: firstName,
        lastName: lastName,
        photoUrl: photoUrl,
        location: location,
      );

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _remote.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<UserEntity?> getCurrentUser() => _remote.getCurrentUser();
}
