import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'firebase_config.dart';
import '../utils/auth_error_handler.dart';

/// Service for handling authentication operations including Google and Apple sign-in
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Only initialize FirebaseAuth when Firebase is enabled
  firebase_auth.FirebaseAuth? get _auth => 
      FirebaseConfig.isEnabled ? firebase_auth.FirebaseAuth.instance : null;

  /// Signs in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Get the Google Sign In instance
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      
      // Initialize if not already initialized (this is safe to call multiple times)
      try {
        await googleSignIn.initialize();
      } catch (e) {
        // Already initialized, ignore
      }

      // Trigger the authentication flow
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Get access token from authorization client
      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);
        accessToken = authz.accessToken;
      } catch (e) {
        // If authorization fails, we'll try with just the idToken
      }
      
      if (!FirebaseConfig.isEnabled) {
        // Development mode - store user info and create account
        final prefs = await SharedPreferences.getInstance();
        
        // Check if user already exists
        final userInfoJson = prefs.getString('user_info') ?? '{}';
        final userInfoMap = Map<String, dynamic>.from(jsonDecode(userInfoJson));
        final emailLower = googleUser.email.toLowerCase();
        
        User user;
        if (userInfoMap.containsKey(emailLower)) {
          // Existing user - try to load their existing data from user_data first
          final existingUserJson = prefs.getString('user_data');
          if (existingUserJson != null) {
            try {
              final existingUserMap = jsonDecode(existingUserJson) as Map<String, dynamic>;
              final existingUser = User.fromJson(existingUserMap);
              final existingUserInfo = userInfoMap[emailLower] as Map<String, dynamic>;
              
              // If the user ID matches, return the existing user (with all their data including preferences)
              if (existingUser.id == existingUserInfo['id'] as String) {
                // Update photo URL if available from Google
                final updatedUser = existingUser.copyWith(photoURL: googleUser.photoUrl);
                await _saveUserData(updatedUser);
                return updatedUser;
              }
            } catch (e) {
              // If parsing fails, create new user below
              debugPrint('Error loading existing user data: $e');
            }
          }
          
          // No existing user data found, create new user with user info (but preserve structure)
          final existingUserInfo = userInfoMap[emailLower] as Map<String, dynamic>;
          user = User(
            id: existingUserInfo['id'] as String,
            email: googleUser.email,
            displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
            photoURL: googleUser.photoUrl,
            watchlist: [],
            likedMovies: [],
            dislikedMovies: [],
            likedShows: [],
            dislikedShows: [],
            preferences: {}, // Will be set during onboarding
          );
        } else {
          // New user - create account
          final userId = 'google_user_${DateTime.now().millisecondsSinceEpoch}';
          final userInfo = {
            'email': emailLower,
            'displayName': googleUser.displayName ?? googleUser.email.split('@')[0],
            'id': userId,
            'provider': 'google',
          };
          userInfoMap[emailLower] = userInfo;
          await prefs.setString('user_info', jsonEncode(userInfoMap));
          
          user = User(
            id: userId,
            email: googleUser.email,
            displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
            photoURL: googleUser.photoUrl,
            watchlist: [],
            likedMovies: [],
            dislikedMovies: [],
            likedShows: [],
            dislikedShows: [],
            preferences: {},
          );
        }

        await _saveUserData(user);
        return user;
      }

      // Production mode - use Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = 
          await _auth!.signInWithCredential(credential);
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Convert Firebase user to our User model
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        photoURL: firebaseUser.photoURL,
        watchlist: [],
        likedMovies: [],
        dislikedMovies: [],
        likedShows: [],
        dislikedShows: [],
        preferences: {},
      );

      await _saveUserData(user);
      return user;
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Handle canceled errors
      if (AuthErrorHandler.isCanceledError(e)) {
        throw Exception('Google sign-in was canceled');
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Signs in with Apple
  Future<User?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Get email and name from credential
      final email = credential.email;
      final givenName = credential.givenName ?? '';
      final familyName = credential.familyName ?? '';
      final displayName = '${givenName} ${familyName}'.trim();
      
      if (email == null) {
        throw Exception('Email is required for Apple Sign In');
      }

      if (!FirebaseConfig.isEnabled) {
        // Development mode - store user info and create account
        final prefs = await SharedPreferences.getInstance();
        
        // Check if user already exists
        final userInfoJson = prefs.getString('user_info') ?? '{}';
        final userInfoMap = Map<String, dynamic>.from(jsonDecode(userInfoJson));
        final emailLower = email.toLowerCase();
        
        User user;
        if (userInfoMap.containsKey(emailLower)) {
          // Existing user - try to load their existing data from user_data
          final existingUserJson = prefs.getString('user_data');
          if (existingUserJson != null) {
            try {
              final existingUserMap = jsonDecode(existingUserJson) as Map<String, dynamic>;
              final existingUser = User.fromJson(existingUserMap);
              final existingUserInfo = userInfoMap[emailLower] as Map<String, dynamic>;
              
              // If the user ID matches, return the existing user (with all their data)
              if (existingUser.id == existingUserInfo['id'] as String) {
                await _saveUserData(existingUser);
                return existingUser;
              }
            } catch (e) {
              // If parsing fails, create new user below
              debugPrint('Error loading existing user data: $e');
            }
          }
          
          // No existing user data found, try to preserve any existing preferences structure
          final existingUserInfo = userInfoMap[emailLower] as Map<String, dynamic>;
          // Try to load any existing preferences from a previous session
          Map<String, dynamic> existingPreferences = {};
          // Reuse existingUserJson from above if it was loaded, otherwise try again
          final existingUserJsonForPrefs = existingUserJson ?? prefs.getString('user_data');
          if (existingUserJsonForPrefs != null) {
            try {
              final existingUserMap = jsonDecode(existingUserJsonForPrefs) as Map<String, dynamic>;
              if (existingUserMap['preferences'] != null) {
                existingPreferences = Map<String, dynamic>.from(existingUserMap['preferences']);
              }
            } catch (e) {
              debugPrint('Error loading existing preferences: $e');
            }
          }
          
          user = User(
            id: existingUserInfo['id'] as String,
            email: email,
            displayName: displayName.isNotEmpty 
                ? displayName 
                : (existingUserInfo['displayName'] as String? ?? email.split('@')[0]),
            photoURL: null,
            watchlist: [],
            likedMovies: [],
            dislikedMovies: [],
            likedShows: [],
            dislikedShows: [],
            preferences: existingPreferences, // Preserve existing preferences if any
          );
        } else {
          // New user - create account
          final userId = 'apple_user_${DateTime.now().millisecondsSinceEpoch}';
          final userInfo = {
            'email': emailLower,
            'displayName': displayName.isNotEmpty ? displayName : email.split('@')[0],
            'id': userId,
            'provider': 'apple',
          };
          userInfoMap[emailLower] = userInfo;
          await prefs.setString('user_info', jsonEncode(userInfoMap));
          
          user = User(
            id: userId,
            email: email,
            displayName: displayName.isNotEmpty ? displayName : email.split('@')[0],
            photoURL: null,
            watchlist: [],
            likedMovies: [],
            dislikedMovies: [],
            likedShows: [],
            dislikedShows: [],
            preferences: {},
          );
        }

        await _saveUserData(user);
        return user;
      }

      // Production mode - use Firebase
      // Create OAuth credential for Firebase
      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final firebase_auth.UserCredential userCredential = 
          await _auth!.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // Convert Firebase user to our User model
      final String finalDisplayName = firebaseUser.displayName ?? 
          (displayName.isNotEmpty 
              ? displayName 
              : (firebaseUser.email?.split('@')[0] ?? 'User'));
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: finalDisplayName,
        photoURL: firebaseUser.photoURL,
        watchlist: [],
        likedMovies: [],
        dislikedMovies: [],
        likedShows: [],
        dislikedShows: [],
        preferences: {},
      );

      // Save user data locally
      await _saveUserData(user);
      
      return user;
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Handle canceled errors
      if (AuthErrorHandler.isCanceledError(e)) {
        throw Exception('Apple sign-in was canceled');
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Signs in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (!FirebaseConfig.isEnabled) {
        // Development fallback - validate credentials
        final prefs = await SharedPreferences.getInstance();
        final registeredUsersJson = prefs.getString('registered_users');
        
        if (registeredUsersJson == null) {
          throw Exception('No account found with this email. Please sign up first.');
        }
        
        Map<String, String> registeredUsers;
        try {
          registeredUsers = Map<String, String>.from(jsonDecode(registeredUsersJson));
        } catch (e) {
          throw Exception('Error reading user data. Please try again.');
        }
        final emailLower = email.toLowerCase();
        
        // Check if email is registered
        if (!registeredUsers.containsKey(emailLower)) {
          throw Exception('No account found with this email. Please sign up first.');
        }
        
        // Validate password
        final storedPasswordHash = registeredUsers[emailLower];
        final providedPasswordHash = _hashPassword(password);
        
        if (storedPasswordHash != providedPasswordHash) {
          throw Exception('Invalid password. Please try again.');
        }
        
        // Load user info
        final userInfoJson = prefs.getString('user_info') ?? '{}';
        Map<String, dynamic> userInfoMap;
        try {
          userInfoMap = Map<String, dynamic>.from(jsonDecode(userInfoJson));
        } catch (e) {
          throw Exception('Error reading user data. Please try again.');
        }
        final userInfo = userInfoMap[emailLower] as Map<String, dynamic>?;
        
        if (userInfo == null) {
          throw Exception('User data not found. Please sign up again.');
        }
        
        await Future.delayed(const Duration(seconds: 1));
        
        final userId = userInfo['id'] as String;
        
        // Try to load existing user data first to preserve favorites, watchlist, preferences, etc.
        final existingUserJson = prefs.getString('user_data');
        if (existingUserJson != null) {
          try {
            final existingUserMap = jsonDecode(existingUserJson) as Map<String, dynamic>;
            final existingUser = User.fromJson(existingUserMap);
            
            // In development mode, match by email (more reliable than ID which has timestamp)
            // This ensures we load existing user data even if IDs don't match exactly
            final existingEmail = existingUser.email.toLowerCase();
            if (existingEmail == emailLower) {
              debugPrint('✅ Loaded existing user data for $emailLower');
              debugPrint('📋 User preferences: ${existingUser.preferences}');
              debugPrint('🎯 onboardingCompleted: ${existingUser.preferences['onboardingCompleted']}');
              
              // Update the user ID to match the current session if it's different
              // This ensures consistency while preserving all user data
              if (existingUser.id != userId) {
                debugPrint('⚠️ User ID mismatch. Updating ID from ${existingUser.id} to $userId');
                final updatedUser = existingUser.copyWith(id: userId);
                await _saveUserData(updatedUser);
                return updatedUser;
              }
              
              return existingUser;
            }
            
            // Fallback: Also check by ID if email doesn't match
            if (existingUser.id == userId) {
              debugPrint('✅ Loaded existing user data by ID for $emailLower');
              debugPrint('📋 User preferences: ${existingUser.preferences}');
              return existingUser;
            }
            
            debugPrint('⚠️ Found user data but email/ID mismatch. Existing: ${existingUser.email} (${existingUser.id}), Current: $emailLower ($userId)');
          } catch (e) {
            // If parsing fails, create new user
            debugPrint('❌ Error loading existing user data: $e');
          }
        } else {
          debugPrint('⚠️ No existing user_data found in SharedPreferences');
        }
        
        // No existing user data found, create new user
        debugPrint('⚠️ Creating new user for $emailLower (no existing data found)');
        final user = User(
          id: userId,
          email: email,
          displayName: userInfo['displayName'] as String? ?? email.split('@')[0],
          photoURL: null,
          watchlist: [],
          likedMovies: [],
          dislikedMovies: [],
          likedShows: [],
          dislikedShows: [],
          preferences: {},
        );

        await _saveUserData(user);
        debugPrint('✅ Created and saved new user with empty preferences');
        return user;
      }

      // Production email sign-in
      final firebase_auth.UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Try to load existing user data first to preserve preferences, watchlist, etc.
      final prefs = await SharedPreferences.getInstance();
      final existingUserJson = prefs.getString('user_data');
      if (existingUserJson != null) {
        try {
          final existingUserMap = jsonDecode(existingUserJson) as Map<String, dynamic>;
          final existingUser = User.fromJson(existingUserMap);
          
          // If the user ID matches, return the existing user (with all their data)
          if (existingUser.id == firebaseUser.uid) {
            return existingUser;
          }
        } catch (e) {
          // If parsing fails, create new user
          debugPrint('Error loading existing user data: $e');
        }
      }

      // No existing user data found, create new user
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        photoURL: firebaseUser.photoURL,
        watchlist: [],
        likedMovies: [],
        dislikedMovies: [],
        likedShows: [],
        dislikedShows: [],
        preferences: {},
      );

      // Save user data locally
      await _saveUserData(user);
      
      return user;
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Signs up with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      if (!FirebaseConfig.isEnabled) {
        // Development fallback - check if user already exists
        final prefs = await SharedPreferences.getInstance();
        final registeredUsersJson = prefs.getString('registered_users');
        Map<String, String> registeredUsers = {};
        
        if (registeredUsersJson != null) {
          try {
            registeredUsers = Map<String, String>.from(jsonDecode(registeredUsersJson));
          } catch (e) {
            throw Exception('Error reading user data. Please try again.');
          }
        }
        
        // Check if email is already registered
        if (registeredUsers.containsKey(email.toLowerCase())) {
          throw Exception('An account with this email already exists');
        }
        
        // Hash password and store credentials
        final passwordHash = _hashPassword(password);
        registeredUsers[email.toLowerCase()] = passwordHash;
        await prefs.setString('registered_users', jsonEncode(registeredUsers));
        
        // Also store user info for quick lookup
        final userInfo = {
          'email': email.toLowerCase(),
          'displayName': displayName,
          'id': 'email_user_${DateTime.now().millisecondsSinceEpoch}',
        };
        final userInfoJson = prefs.getString('user_info') ?? '{}';
        Map<String, dynamic> userInfoMap;
        try {
          userInfoMap = Map<String, dynamic>.from(jsonDecode(userInfoJson));
        } catch (e) {
          throw Exception('Error reading user data. Please try again.');
        }
        userInfoMap[email.toLowerCase()] = userInfo;
        await prefs.setString('user_info', jsonEncode(userInfoMap));
        
        await Future.delayed(const Duration(seconds: 1));
        
        final user = User(
          id: userInfo['id'] as String,
          email: email,
          displayName: displayName,
          photoURL: null,
          watchlist: [],
          likedMovies: [],
          dislikedMovies: [],
          likedShows: [],
          dislikedShows: [],
          preferences: {},
        );

        await _saveUserData(user);
        return user;
      }

      // Production email sign-up
      final firebase_auth.UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create account');
      }

      // Update display name
      await firebaseUser.updateDisplayName(displayName);

      // Generate and send verification code (instead of Firebase verification link)
      try {
        await sendVerificationCodeEmail(email);
      } catch (e) {
        // Log but don't fail sign-up if verification code email fails
        debugPrint('Failed to send verification code email: $e');
      }

      // Convert Firebase user to our User model
      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: displayName,
        photoURL: firebaseUser.photoURL,
        watchlist: [],
        likedMovies: [],
        dislikedMovies: [],
        likedShows: [],
        dislikedShows: [],
        preferences: {},
      );

      // Save user data locally
      await _saveUserData(user);
      
      return user;
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      if (FirebaseConfig.isEnabled) {
        await Future.wait([
          _auth!.signOut(),
        ]);
      }
      
      // IMPORTANT: Do NOT clear user_data on sign out
      // User data (preferences, watchlist, etc.) should be preserved
      // Only clear the authentication session, not the user data
      // This allows users to sign back in and retain their preferences
      debugPrint('✅ Signed out - user data preserved for next login');
      
      // Note: We're NOT calling _clearUserData() here
      // User data will be loaded again when they sign in
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Gets the current user
  Future<User?> getCurrentUser() async {
    try {
      if (!FirebaseConfig.isEnabled) {
        // Development fallback - load from local storage
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        
        if (userJson != null) {
          try {
            final userMap = jsonDecode(userJson) as Map<String, dynamic>;
            return User.fromJson(userMap);
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            return null;
          }
        }
        return null;
      }

      // Production - check Firebase user
      final firebaseUser = _auth!.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      // Try to load from local storage first
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      
      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          return User.fromJson(userMap);
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // Fall through to create from Firebase user
        }
      }

      // If not in local storage, create from Firebase user
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        photoURL: firebaseUser.photoURL,
        watchlist: [],
        likedMovies: [],
        dislikedMovies: [],
        likedShows: [],
        dislikedShows: [],
        preferences: {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Saves user data to local storage
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user data: $e');
      // Don't throw - this is a non-critical operation
      // User can still use the app, data just won't persist locally
    }
  }

  /// Clears user data from local storage
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
      // Don't throw - this is a non-critical operation
    }
  }

  /// Sends email verification to the current user
  Future<void> sendEmailVerification() async {
    try {
      if (!FirebaseConfig.isEnabled) {
        // Development mode - just return success (email already "sent" during sign-up)
        return;
      }

      final firebaseUser = _auth!.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (firebaseUser.emailVerified) {
        throw Exception('Email is already verified');
      }

      await firebaseUser.sendEmailVerification();
    } catch (e) {
      // Re-throw Firebase exceptions directly to preserve error codes
      if (e is firebase_auth.FirebaseAuthException || 
          e is firebase_auth.FirebaseException) {
        rethrow;
      }
      // Use error handler for user-friendly messages
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  /// Checks if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      if (!FirebaseConfig.isEnabled) {
        // Development fallback - check if user data exists AND user is registered
        // Just having user_data isn't enough - user must have actually signed in
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        if (userJson == null) return false;
        
        // Also check if user is in registered_users (meaning they actually signed in)
        final registeredUsersJson = prefs.getString('registered_users');
        if (registeredUsersJson == null) return false;
        
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          final userEmail = (userMap['email'] as String?)?.toLowerCase();
          if (userEmail == null) return false;
          
          final registeredUsers = Map<String, String>.from(jsonDecode(registeredUsersJson));
          // User is authenticated if they exist in registered_users
          return registeredUsers.containsKey(userEmail);
        } catch (e) {
          return false;
        }
      }

      // Production - check Firebase user
      final firebaseUser = _auth!.currentUser;
      return firebaseUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Hashes a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Generates and stores a verification code for an email
  Future<String> generateVerificationCode(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = _generateVerificationCode();
      final emailLower = email.toLowerCase();
      
      // Store code with expiration (15 minutes)
      final codeData = {
        'code': code,
        'email': emailLower,
        'expiresAt': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final codesJson = prefs.getString('verification_codes') ?? '{}';
      final codesMap = Map<String, dynamic>.from(jsonDecode(codesJson));
      codesMap[emailLower] = codeData;
      
      await prefs.setString('verification_codes', jsonEncode(codesMap));
      
      debugPrint('✅ Generated verification code for $emailLower: $code');
      
      return code;
    } catch (e) {
      debugPrint('Error generating verification code: $e');
      rethrow;
    }
  }

  /// Verifies a code for an email
  Future<bool> verifyCode(String email, String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailLower = email.toLowerCase();
      
      final codesJson = prefs.getString('verification_codes');
      if (codesJson == null) {
        return false;
      }
      
      final codesMap = Map<String, dynamic>.from(jsonDecode(codesJson));
      final codeData = codesMap[emailLower] as Map<String, dynamic>?;
      
      if (codeData == null) {
        return false;
      }
      
      // Check if code matches
      final storedCode = codeData['code'] as String?;
      if (storedCode != code) {
        return false;
      }
      
      // Check if code has expired
      final expiresAtStr = codeData['expiresAt'] as String?;
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          // Code expired, remove it
          codesMap.remove(emailLower);
          await prefs.setString('verification_codes', jsonEncode(codesMap));
          return false;
        }
      }
      
      // Code is valid - remove it and mark email as verified
      codesMap.remove(emailLower);
      await prefs.setString('verification_codes', jsonEncode(codesMap));
      
      // Mark email as verified in Firebase if enabled
      if (FirebaseConfig.isEnabled) {
        final firebaseUser = _auth!.currentUser;
        if (firebaseUser != null && firebaseUser.email?.toLowerCase() == emailLower) {
          // Reload user to check if email is verified
          await firebaseUser.reload();
          // If not verified, we can't manually verify it, but we'll mark it in our system
          // For now, we'll just proceed - the user will need to verify via Firebase
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error verifying code: $e');
      return false;
    }
  }

  /// Sends verification code via email using Firebase Cloud Functions
  Future<void> sendVerificationCodeEmail(String email) async {
    try {
      final code = await generateVerificationCode(email);
      
      if (FirebaseConfig.isEnabled) {
        // Call Cloud Function to send email with verification code
        try {
          final functions = FirebaseFunctions.instance;
          final callable = functions.httpsCallable('sendVerificationCode');
          
          final result = await callable.call({
            'email': email,
            'code': code,
          });
          
          debugPrint('✅ Verification code email sent via Cloud Function: $email');
          if (kDebugMode && result.data != null) {
            debugPrint('Cloud Function response: ${result.data}');
          }
        } catch (e) {
          // If Cloud Function fails, log the code so user can still verify
          debugPrint('⚠️ Cloud Function error: $e');
          debugPrint('📧 Verification code for $email: $code');
          debugPrint('⚠️ Email not sent. Please check Cloud Functions setup or use code from logs.');
          
          // Don't rethrow - code is still generated and stored, user can verify manually
          // Or configure email service in Cloud Functions
        }
      } else {
        // Development mode - just log the code
        debugPrint('📧 [DEV] Verification code for $email: $code');
      }
    } catch (e) {
      debugPrint('Error sending verification code email: $e');
      rethrow;
    }
  }
} 