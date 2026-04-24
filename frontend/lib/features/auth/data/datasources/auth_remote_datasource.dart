import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

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
    User? firebaseUser;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      firebaseUser = credential.user;
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
    } catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      rethrow;
    }
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

  Future<UserEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? location,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (photoUrl != null) data['photo_url'] = photoUrl;
    if (location != null) data['location'] = location;

    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.updateProfile,
      data: data,
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  /// Upload a profile photo via backend (Supabase Storage) and return updated user.
  Future<UserEntity> uploadProfilePhoto(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.uploadProfilePhoto,
      data: formData,
    );

    if (response.data == null) {
      throw AuthException('Invalid response from server');
    }

    return UserEntity.fromJson(response.data!);
  }

  /// Sends a verification link to [newEmail]. Once the user clicks it,
  /// Firebase automatically updates their email address. Requires recent
  /// auth — reauthenticates with [currentPassword] first.
  Future<void> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('No authenticated user');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException('Incorrect password. Please try again.');
      }
      throw AuthException(e.message ?? 'Re-authentication failed');
    }

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('This email address is already in use.');
      }
      if (e.code == 'invalid-email') {
        throw AuthException('Please enter a valid email address.');
      }
      throw AuthException(e.message ?? 'Failed to send verification email');
    }
  }

  /// Resends the email verification to the current user's email address.
  Future<void> resendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('No authenticated user');
    if (user.emailVerified) throw AuthException('Email is already verified');
    await user.sendEmailVerification();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('No authenticated user');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Permanently deletes the account from Firebase and the backend.
  /// For email users, [password] must be provided for re-authentication.
  /// For Google users, a Google sign-in sheet will be shown for re-authentication.
  /// For anonymous/guest users, no re-authentication is required.
  Future<void> deleteAccount({String? password}) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) throw AuthException('No authenticated user');

    final providers =
        firebaseUser.providerData.map((p) => p.providerId).toList();

    if (providers.contains('password')) {
      if (password == null || password.isEmpty) {
        throw AuthException('Password is required to delete your account');
      }
      final credential = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: password,
      );
      try {
        await firebaseUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw AuthException('Incorrect password. Please try again.');
        }
        throw AuthException(e.message ?? 'Re-authentication failed');
      }
    } else if (providers.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google re-authentication was cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      try {
        await firebaseUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        throw AuthException(e.message ?? 'Google re-authentication failed');
      }
    }

    try {
      await _dio.delete<void>(ApiEndpoints.deleteAccount);
    } catch (_) {
      // Best-effort backend cleanup — still proceed with Firebase deletion.
    }

    await firebaseUser.delete();

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
