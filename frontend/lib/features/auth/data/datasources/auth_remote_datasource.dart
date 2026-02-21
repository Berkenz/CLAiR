import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required Dio dio,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _dio = dio,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Email/password sign-up: creates Firebase user, sends verification email,
  /// then registers with the backend.
  Future<UserEntity> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw AuthException('Failed to create account');
    }

    await firebaseUser.sendEmailVerification();

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'firebase_token': idToken,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  /// Email/password login.
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw AuthException('Login failed');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'firebase_token': idToken},
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  /// Google sign-in. Returns the user if already registered, or null
  /// plus a flag if the user needs to complete registration.
  Future<GoogleAuthResult> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Google sign in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Firebase sign in failed');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.googleAuth,
      data: {'firebase_token': idToken},
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    final isNewUser = response.data!['is_new_user'] as bool? ?? false;
    if (isNewUser) {
      return GoogleAuthResult(user: null, isNewUser: true);
    }

    final userData = response.data!['user'] as Map<String, dynamic>;
    return GoogleAuthResult(
      user: UserEntity.fromJson(userData),
      isNewUser: false,
    );
  }

  /// Complete Google sign-in registration by providing first/last name.
  Future<UserEntity> completeGoogleRegistration({
    required String firstName,
    required String lastName,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw AuthException('No authenticated user');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.googleComplete,
      data: {
        'firebase_token': idToken,
        'first_name': firstName,
        'last_name': lastName,
      },
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  /// Continue as anonymous guest.
  Future<UserEntity> signInAsGuest() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw AuthException('Anonymous sign in failed');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.guest,
      data: {'firebase_token': idToken},
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Stream<User?> get firebaseAuthStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      if (response.data == null) return null;
      return UserEntity.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }
}

class GoogleAuthResult {
  const GoogleAuthResult({required this.user, required this.isNewUser});
  final UserEntity? user;
  final bool isNewUser;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
