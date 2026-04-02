import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:io';
import 'package:popmatch/utils/auth_error_handler.dart';

void main() {
  group('AuthErrorHandler Tests', () {
    test('Handles FirebaseAuthException - user-not-found', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(
          message, 'No account found with this email. Please sign up first.');
    });

    test('Handles FirebaseAuthException - wrong-password', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Invalid email or password. Please try again.');
    });

    test('Handles FirebaseAuthException - email-already-in-use', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message,
          'An account with this email already exists. Please sign in instead.');
    });

    test('Handles FirebaseAuthException - weak-password', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'weak-password',
        message: 'Weak password',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message,
          'Password is too weak. Please use a stronger password (at least 6 characters).');
    });

    test('Handles FirebaseAuthException - network-request-failed', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network error',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message,
          'Network error. Please check your connection and try again.');
    });

    test('Handles SocketException', () {
      const error = SocketException('Connection failed');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message,
          'No internet connection. Please check your network and try again.');
    });

    test('Handles HttpException', () {
      const error = HttpException('HTTP error');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Network error occurred. Please try again later.');
    });

    test('Handles timeout errors', () {
      final error = Exception('Request timeout');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message,
          'Request timed out. Please check your connection and try again.');
    });

    test('Handles JSON parsing errors', () {
      final error = Exception('FormatException: Invalid JSON');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(
          message, 'Data format error. Please try again or contact support.');
    });

    test('Handles canceled errors', () {
      final error = Exception('Sign-in canceled');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Sign-in was canceled.');
    });

    test('Handles generic exceptions', () {
      final error = Exception('Something went wrong');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Something went wrong');
    });

    test('Removes Exception: prefix', () {
      // When creating Exception('Exception: Test error'),
      // toString() returns "Exception: Exception: Test error"
      final error = Exception('Exception: Test error');
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Test error');
    });

    test('isNetworkError detects SocketException', () {
      const error = SocketException('Connection failed');
      expect(AuthErrorHandler.isNetworkError(error), true);
    });

    test('isNetworkError detects network-request-failed', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network error',
      );
      expect(AuthErrorHandler.isNetworkError(error), true);
    });

    test('isCanceledError detects canceled operations', () {
      final error = Exception('Sign-in canceled');
      expect(AuthErrorHandler.isCanceledError(error), true);
    });

    test('Handles default FirebaseAuthException', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Custom error message',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Custom error message');
    });

    test('Handles FirebaseAuthException without message', () {
      final error = firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
      );
      final message = AuthErrorHandler.getErrorMessage(error);
      expect(message, 'Authentication failed. Please try again.');
    });
  });
}
