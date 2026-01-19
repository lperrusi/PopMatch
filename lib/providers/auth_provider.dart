import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_handler.dart';

/// Provider for managing authentication state
class AuthProvider with ChangeNotifier {
  User? _userData;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();

  // Getters
  User? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userData != null;

  /// Initializes the auth provider
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user is authenticated
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _userData = await _authService.getCurrentUser();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userData = await _authService.signInWithEmailAndPassword(email, password);
      
      // CRITICAL: Verify user data was loaded correctly
      if (_userData != null) {
        debugPrint('✅ Sign-in successful. User: ${_userData!.email}');
        debugPrint('📋 User preferences: ${_userData!.preferences}');
        debugPrint('🎯 onboardingCompleted: ${_userData!.preferences['onboardingCompleted']}');
      } else {
        debugPrint('⚠️ Sign-in returned null user data');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign-in error: $e');
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userData = await _authService.signUpWithEmailAndPassword(email, password, displayName);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with Google
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userData = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with Apple
  Future<void> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userData = await _authService.signInWithApple();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }



  /// Adds a movie to watchlist
  Future<void> addToWatchlist(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.addToWatchlist(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a movie from watchlist
  Future<void> removeFromWatchlist(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.removeFromWatchlist(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Adds a movie to liked movies
  Future<void> addLikedMovie(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.addLikedMovie(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a movie from liked movies
  Future<void> removeLikedMovie(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.removeLikedMovie(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Adds a movie to disliked movies
  Future<void> addDislikedMovie(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.addDislikedMovie(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a movie from disliked movies
  Future<void> removeDislikedMovie(String movieId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.removeDislikedMovie(movieId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Adds a show to liked shows
  Future<void> addLikedShow(String showId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.addLikedShow(showId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a show from liked shows
  Future<void> removeLikedShow(String showId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.removeLikedShow(showId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Adds a show to disliked shows
  Future<void> addDislikedShow(String showId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.addDislikedShow(showId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a show from disliked shows
  Future<void> removeDislikedShow(String showId) async {
    if (_userData == null) return;
    
    try {
      _userData = _userData!.removeDislikedShow(showId);
      await _saveUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates user preferences
  Future<void> updatePreferences(Map<String, dynamic> newPreferences) async {
    if (_userData == null) {
      debugPrint('❌ Cannot update preferences: userData is null');
      return;
    }
    
    try {
      debugPrint('📝 Updating preferences: $newPreferences');
      _userData = _userData!.updatePreferences(newPreferences);
      debugPrint('✅ Updated user preferences. onboardingCompleted: ${_userData!.preferences['onboardingCompleted']}');
      await _saveUserData();
      debugPrint('✅ Saved user data to SharedPreferences');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Sends email verification to the current user
  Future<void> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-throw so UI can handle it
    }
  }

  /// Sends verification code email
  Future<void> sendVerificationCodeEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendVerificationCodeEmail(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verifies a code for an email
  Future<bool> verifyCode(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isValid = await _authService.verifyCode(email, code);
      _isLoading = false;
      notifyListeners();
      return isValid;
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs out the user
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _userData = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = AuthErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Checks if a movie is in watchlist
  bool isInWatchlist(String movieId) {
    return _userData?.watchlist.contains(movieId) ?? false;
  }

  /// Checks if a movie is liked
  bool isLikedMovie(String movieId) {
    return _userData?.likedMovies.contains(movieId) ?? false;
  }

  /// Checks if a movie is disliked
  bool isDislikedMovie(String movieId) {
    return _userData?.dislikedMovies.contains(movieId) ?? false;
  }

  /// Checks if a show is liked
  bool isLikedShow(String showId) {
    return _userData?.likedShows.contains(showId) ?? false;
  }

  /// Checks if a show is disliked
  bool isDislikedShow(String showId) {
    return _userData?.dislikedShows.contains(showId) ?? false;
  }

  /// Saves user data to SharedPreferences
  Future<void> _saveUserData() async {
    if (_userData == null) {
      debugPrint('❌ Cannot save user data: userData is null');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_userData!.toJson());
      await prefs.setString('user_data', userJson);
      debugPrint('✅ User data saved successfully. Email: ${_userData!.email}, onboardingCompleted: ${_userData!.preferences['onboardingCompleted']}');
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clears error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 