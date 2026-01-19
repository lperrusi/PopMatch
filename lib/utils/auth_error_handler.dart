import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:io';

/// Utility class for handling authentication errors and converting them to user-friendly messages
class AuthErrorHandler {
  /// Converts various exception types to user-friendly error messages
  static String getErrorMessage(dynamic error) {
    // Handle Firebase Auth exceptions
    if (error is firebase_auth.FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    }

    // Handle Firebase exceptions
    if (error is firebase_auth.FirebaseException) {
      return _getFirebaseErrorMessage(error);
    }

    // Handle network errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is HttpException) {
      return 'Network error occurred. Please try again later.';
    }

    // Handle timeout errors
    if (error.toString().contains('timeout') || 
        error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Handle JSON parsing errors
    if (error.toString().contains('FormatException') ||
        error.toString().contains('jsonDecode')) {
      return 'Data format error. Please try again or contact support.';
    }

    // Handle generic exceptions
    String errorString = error.toString();
    
    // Remove common prefixes (handle nested "Exception: " prefixes)
    while (errorString.startsWith('Exception: ')) {
      errorString = errorString.substring(11); // "Exception: " is 11 characters
    }
    if (errorString.startsWith('Exception:')) {
      errorString = errorString.substring(10); // "Exception:" is 10 characters
    }
    
    // Handle specific error messages
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    }
    
    if (errorString.contains('wrong-password') || 
        errorString.contains('invalid-credential')) {
      return 'Invalid email or password. Please try again.';
    }
    
    if (errorString.contains('email-already-in-use') ||
        errorString.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    
    if (errorString.contains('invalid-email')) {
      return 'Invalid email address. Please check and try again.';
    }
    
    if (errorString.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    
    if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    }
    
    if (errorString.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please use another method.';
    }
    
    if (errorString.contains('network-request-failed') ||
        errorString.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    
    if (errorString.contains('canceled') || 
        errorString.contains('Canceled')) {
      return 'Sign-in was canceled.';
    }
    
    if (errorString.contains('not available')) {
      return 'This sign-in method is not available on this device.';
    }

    // Return cleaned error message or default
    return errorString.isNotEmpty 
        ? errorString 
        : 'An unexpected error occurred. Please try again.';
  }

  /// Converts Firebase Auth exception codes to user-friendly messages
  static String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password (at least 6 characters).';
      
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please use another method.';
      
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign out and sign in again.';
      
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      
      case 'invalid-verification-id':
        return 'Verification session expired. Please try again.';
      
      case 'quota-exceeded':
        return 'Service temporarily unavailable. Please try again later.';
      
      case 'too-many-requests':
        return 'Too many verification emails sent. Please wait a few minutes before trying again.';
      
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Converts Firebase exceptions to user-friendly messages
  static String _getFirebaseErrorMessage(firebase_auth.FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Permission denied. Please contact support.';
    }
    
    if (error.code == 'unavailable') {
      return 'Service temporarily unavailable. Please try again later.';
    }
    
    return error.message ?? 'An error occurred. Please try again.';
  }

  /// Checks if an error is a network-related error
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
           error is HttpException ||
           (error is firebase_auth.FirebaseAuthException && 
            error.code == 'network-request-failed') ||
           error.toString().contains('network') ||
           error.toString().contains('timeout');
  }

  /// Checks if an error is a user-canceled operation
  static bool isCanceledError(dynamic error) {
    return error.toString().contains('canceled') ||
           error.toString().contains('Canceled');
  }
}
