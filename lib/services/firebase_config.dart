import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the app
class FirebaseConfig {
  static const bool _useFirebase = true; // Firebase enabled for production

  /// Test-only: when true, [isEnabled] is false so AuthService uses development path without Firebase.
  static bool _testMode = false;

  @visibleForTesting
  static void setTestMode(bool value) {
    _testMode = value;
  }

  /// Initializes Firebase with appropriate configuration
  static Future<void> initialize() async {
    if (_useFirebase && !_testMode) {
      // Production Firebase configuration
      await Firebase.initializeApp();
    } else {
      // Development fallback - no Firebase initialization
      if (kDebugMode && !_testMode) {
        debugPrint('Firebase disabled for development');
      }
    }
  }

  /// Checks if Firebase is enabled (false when [setTestMode] is true)
  static bool get isEnabled => _useFirebase && !_testMode;

  /// Gets the Firebase project ID
  static String get projectId => _useFirebase
      ? const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'popmatch-app')
      : 'dev-popmatch';

  /// Gets the Firebase API key
  static String get apiKey => _useFirebase
      ? const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '')
      : 'dev-api-key';
} 