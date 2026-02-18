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

  Future<UserEntity> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Google sign in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Firebase sign in failed');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Failed to get ID token');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.auth,
      data: {'id_token': idToken},
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return _parseUserFromJson(response.data!);
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentUser();
    });
  }

  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) return null;

      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      if (response.data == null) return null;

      return _parseUserFromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  UserEntity _parseUserFromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}
