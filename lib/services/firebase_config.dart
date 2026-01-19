import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for the app
class FirebaseConfig {
  static const bool _useFirebase = true; // Firebase enabled for production

  /// Initializes Firebase with appropriate configuration
  static Future<void> initialize() async {
    if (_useFirebase) {
      // Production Firebase configuration
      await Firebase.initializeApp();
    } else {
      // Development fallback - no Firebase initialization
      if (kDebugMode) {
        print('Firebase disabled for development');
      }
    }
  }

  /// Checks if Firebase is enabled
  static bool get isEnabled => _useFirebase;

  /// Gets the Firebase project ID
  static String get projectId => _useFirebase ? 'popmatch-app' : 'dev-popmatch';

  /// Gets the Firebase API key
  static String get apiKey => _useFirebase ? 'your-api-key' : 'dev-api-key';
} 