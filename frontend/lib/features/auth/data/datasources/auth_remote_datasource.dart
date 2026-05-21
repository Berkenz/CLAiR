import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:http_parser/http_parser.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'package:clair/core/config/oauth_ids.dart';
import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/auth/domain/entities/user_entity.dart';

GoogleSignIn _createPlatformGoogleSignIn() {
  const scopes = ['email', 'profile'];
  if (defaultTargetPlatform == TargetPlatform.android) {
    return GoogleSignIn(
      scopes: scopes,
      serverClientId: kFirebaseAndroidGoogleSignInServerClientId,
    );
  }
  return GoogleSignIn(scopes: scopes);
}

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required Dio dio,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _dio = dio,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? _createPlatformGoogleSignIn();

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
        throw AuthException('Could not create your account. Please try again.');
      }

      await firebaseUser.sendEmailVerification();

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw AuthException('Sign-in failed. Please try again.');
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
        throw AuthException('Something went wrong. Please try again.');
      }

      final refreshed = await getCurrentUser();
      return refreshed ?? UserEntity.fromJson(response.data!);
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
      throw AuthException('Sign-in failed. Please try again.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Sign-in failed. Please try again.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'firebase_token': idToken},
      );

      if (response.data == null) {
        throw AuthException('Something went wrong. Please try again.');
      }

      final refreshed = await getCurrentUser();
      return refreshed ?? UserEntity.fromJson(response.data!);
    } on DioException {
      await _firebaseAuth.signOut();
      rethrow;
    }
  }

  /// Google sign-in. Returns the user if already registered, a new-user flag
  /// if registration is needed, or a cancelled flag when the user dismisses
  /// the account picker without choosing an account.
  Future<GoogleAuthResult> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // sign_in_canceled / access_denied / network_error are user-initiated.
      const cancelCodes = {'sign_in_canceled', 'access_denied', 'network_error'};
      if (cancelCodes.contains(e.code)) {
        return const GoogleAuthResult(user: null, isNewUser: false, isCancelled: true);
      }
      rethrow;
    }
    if (googleUser == null) {
      return const GoogleAuthResult(user: null, isNewUser: false, isCancelled: true);
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
      throw AuthException('Google sign-in failed. Please try again.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Sign-in failed. Please try again.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.googleAuth,
        data: {'firebase_token': idToken},
      );

      if (response.data == null) {
        throw AuthException('Something went wrong. Please try again.');
      }

      final isNewUser = response.data!['is_new_user'] as bool? ?? false;
      if (isNewUser) {
        return const GoogleAuthResult(user: null, isNewUser: true);
      }

      final userData = response.data!['user'] as Map<String, dynamic>;
      final refreshed = await getCurrentUser();
      return GoogleAuthResult(
        user: refreshed ?? UserEntity.fromJson(userData),
        isNewUser: false,
      );
    } on DioException {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  /// Complete Google sign-in registration by providing first/last name.
  Future<UserEntity> completeGoogleRegistration({
    required String firstName,
    required String lastName,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw AuthException('Your session has expired. Please sign in again.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Sign-in failed. Please try again.');
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
      throw AuthException('Something went wrong. Please try again.');
    }

    final refreshed = await getCurrentUser();
    return refreshed ?? UserEntity.fromJson(response.data!);
  }

  /// Continue as anonymous guest.
  Future<UserEntity> signInAsGuest() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw AuthException('Could not start a guest session. Please try again.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw AuthException('Sign-in failed. Please try again.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.guest,
      data: {'firebase_token': idToken},
    );

    if (response.data == null) {
      throw AuthException('Something went wrong. Please try again.');
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
      throw AuthException('Something went wrong. Please try again.');
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
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.data == null) {
      throw AuthException('Something went wrong. Please try again.');
    }

    // Prefer a fresh /auth/me so photo_url and updated_at match persisted state.
    final refreshed = await getCurrentUser();
    if (refreshed != null) return refreshed;

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
      throw AuthException('You are not signed in. Please sign in and try again.');
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
      throw AuthException('Re-authentication failed. Please try again.');
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
      throw AuthException('Could not send verification email. Please try again.');
    }
  }

  /// Resends the email verification to the current user's email address.
  Future<void> resendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw AuthException('You are not signed in. Please sign in and try again.');
    if (user.emailVerified) throw AuthException('Your email is already verified.');
    await user.sendEmailVerification();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('You are not signed in. Please sign in and try again.');
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
    if (firebaseUser == null) throw AuthException('You are not signed in. Please sign in and try again.');

    final providers =
        firebaseUser.providerData.map((p) => p.providerId).toList();

    // Prefer Google when linked — Google Sign-In accounts may still list `password`
    // in providerData if the email was used elsewhere.
    if (providers.contains('google.com')) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google re-authentication was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      try {
        await firebaseUser.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw AuthException('Google sign-in failed. Please try again.');
        }
        throw AuthException('Google re-authentication failed. Please try again.');
      }
    } else if (providers.contains('password')) {
      if (password == null || password.isEmpty) {
        throw AuthException('Please enter your password to confirm account deletion.');
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
        throw AuthException('Re-authentication failed. Please try again.');
      }
    }

    // Backend must succeed first — otherwise re-sign-in can relink the old user by email.
    await _deleteBackendAccount();
    try {
      await firebaseUser.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ??
            'Your data was removed from our servers, but we could not finish '
            'closing your sign-in session. Please sign out and try again.',
      );
    }
    await signOut();
  }

  /// Ends a guest session: removes DB user (and cascaded chats), Firebase user, then signs out.
  Future<void> exitGuestSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      await signOut();
      return;
    }

    await _deleteBackendAccount();
    try {
      await firebaseUser.delete();
    } on FirebaseAuthException {
      // Already removed or invalid — still sign out locally.
    }
    await signOut();
  }

  Future<void> _deleteBackendAccount() async {
    await _dio.delete<void>(ApiEndpoints.deleteAccount);
  }

  Future<void> signOut() async {
    try {
      await _dio.delete<void>(ApiEndpoints.registerFcmToken);
    } catch (_) {}
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

    for (final path in [ApiEndpoints.me, ApiEndpoints.updateProfile]) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(path);
        if (response.data != null) {
          return UserEntity.fromJson(response.data!);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.user,
    required this.isNewUser,
    this.isCancelled = false,
  });
  final UserEntity? user;
  final bool isNewUser;

  /// True when the user dismissed the Google account picker without selecting
  /// an account. Callers should treat this silently — no error shown.
  final bool isCancelled;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
