import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;

/// Converts any exception into a short, user-friendly message.
///
/// Checks for Dio backend responses, Firebase auth codes, native plugin
/// errors, and known exception patterns before falling back to a generic
/// message.
String friendlyErrorMessage(Object e) {
  // 1. Backend returned a structured error via Dio
  if (e is DioException) {
    if (e.response?.data is Map) {
      final detail = (e.response!.data as Map)['detail'];
      if (detail is String && detail.isNotEmpty) return _sanitize(detail);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'Session expired. Please sign in again.';
        if (code == 403) return 'You don\'t have permission to do that.';
        if (code == 404) return 'The requested resource was not found.';
        if (code == 429) return 'Too many requests. Please wait a moment.';
        if (code != null && code >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Something went wrong. Please try again.';
      default:
        break;
    }
  }

  // 2. Firebase Auth errors — map codes to readable messages
  if (e is FirebaseAuthException) {
    return _firebaseCodeToMessage(e.code, e.message);
  }

  // 3. Native plugin errors (e.g. google_sign_in PlatformException)
  if (e is PlatformException) {
    switch (e.code) {
      case 'network_error':
        return 'No internet connection. Check your network and try again.';
      case 'sign_in_failed':
        return 'Google Sign-In failed. Please try again.';
      case 'sign_in_required':
        return 'Please sign in to continue.';
      default:
        final msg = e.message;
        if (msg != null && msg.isNotEmpty) return _sanitize(msg);
        return 'Something went wrong. Please try again.';
    }
  }

  // 4. Raw string from our own AuthException / other typed exceptions
  final raw = e.toString();
  return _sanitize(raw);
}

/// Maps well-known Firebase Auth error codes to friendly copy.
String _firebaseCodeToMessage(String code, String? fallback) {
  switch (code) {
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'operation-not-allowed':
      return 'This sign-in method is not enabled.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'requires-recent-login':
      return 'Please sign in again before making this change.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with a different sign-in method.';
    case 'credential-already-in-use':
      return 'This credential is already linked to another account.';
    case 'expired-action-code':
      return 'This link has expired. Please request a new one.';
    case 'invalid-action-code':
      return 'This link is invalid or has already been used.';
    default:
      if (fallback != null && fallback.isNotEmpty) return _sanitize(fallback);
      return 'Authentication failed. Please try again.';
  }
}

/// Strips common exception class prefixes and technical jargon so raw
/// messages are at least readable if none of the above matched.
String _sanitize(String raw) {
  var msg = raw;

  // Remove exception class wrappers: "AuthException: …", "Exception: …"
  msg = msg.replaceFirst(RegExp(r'^\w*Exception:\s*'), '');

  // Firebase bracket format: "[firebase_auth/code] Human message"
  final fbMatch = RegExp(r'^\[[\w/\-]+\]\s*').firstMatch(msg);
  if (fbMatch != null) {
    msg = msg.substring(fbMatch.end);
  }

  msg = msg.trim();
  if (msg.isEmpty) return 'Something went wrong. Please try again.';

  // Catch overly-technical messages that leaked through
  final lower = msg.toLowerCase();
  if (lower.contains('malformed') ||
      lower.contains('unexpected character') ||
      lower.contains('formatexception') ||
      lower.contains('socket') ||
      lower.contains('errno') ||
      lower.contains('handshake') ||
      lower.contains('certificate') ||
      lower.contains('eof') ||
      lower.contains('json')) {
    return 'Something went wrong. Please try again.';
  }

  // Capitalise first letter
  if (msg.isNotEmpty) {
    msg = msg[0].toUpperCase() + msg.substring(1);
  }

  // Ensure it ends with punctuation
  if (!msg.endsWith('.') && !msg.endsWith('!') && !msg.endsWith('?')) {
    msg = '$msg.';
  }

  return msg;
}
