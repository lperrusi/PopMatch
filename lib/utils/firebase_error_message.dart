import 'package:firebase_core/firebase_core.dart';

/// Short copy for UI; log the full [error] with [debugLabel] in callers.
String userFacingFirebaseMessage(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Sign in to use social features.';
      case 'failed-precondition':
        if ((error.message ?? '').trim().isNotEmpty) {
          return error.message!.trim();
        }
        return 'Service is updating. Try again in a minute.';
      case 'permission-denied':
        return 'You do not have permission for this action.';
      case 'unavailable':
      case 'deadline-exceeded':
      case 'internal':
      case 'unknown':
        return 'Could not reach the server. Check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
