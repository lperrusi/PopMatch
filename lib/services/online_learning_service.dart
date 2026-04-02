import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'matrix_factorization_service.dart';
import 'rec_engine.dart';

/// Online Learning Service for real-time model updates
/// 
/// This service handles incremental learning from user interactions,
/// updating models in real-time without full retraining
class OnlineLearningService {
  static final OnlineLearningService _instance = OnlineLearningService._internal();
  factory OnlineLearningService() => _instance;
  OnlineLearningService._internal();

  final MatrixFactorizationService _mfService = MatrixFactorizationService();

  // Track last update time per user to avoid too frequent updates
  final Map<String, DateTime> _lastUpdateTime = {};
  
  // Minimum time between updates (seconds)
  static const int _minUpdateInterval = 5;

  /// Records a user interaction and triggers online learning
  /// 
  /// [userId]: User who performed the action
  /// [movieId]: Movie that was interacted with
  /// [action]: 'like', 'dislike', 'skip', 'view'
  /// [context]: Optional context (time, mood, etc.)
  Future<void> recordInteraction({
    required String userId,
    required int movieId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    // Check if we should update (rate limiting)
    final lastUpdate = _lastUpdateTime[userId];
    if (lastUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(lastUpdate).inSeconds;
      if (timeSinceUpdate < _minUpdateInterval) {
        return; // Skip update if too soon
      }
    }

    try {
      // RecEngine records rating (like=+1, dislike=-0.5, neutral=0) and updates MF + CF incrementally
      if (action == 'like') {
        await RecEngine.instance.recordRating(userId, movieId, RecEngineRatings.like);
      } else if (action == 'dislike') {
        await RecEngine.instance.recordRating(userId, movieId, RecEngineRatings.dislike);
      } else if (action == 'skip') {
        await RecEngine.instance.recordRating(userId, movieId, RecEngineRatings.neutral);
      }
      
      // Note: Adaptive weighting updates are handled in swipe_screen.dart
      // to have access to User object and strategy information

      _lastUpdateTime[userId] = DateTime.now();
      
      debugPrint('Online learning: Updated models for user $userId, action: $action');
    } catch (e) {
      debugPrint('Error in online learning update: $e');
    }
  }

  /// Batch updates from user's current preferences
  /// More efficient for initial setup or major preference changes
  Future<void> batchUpdateFromUser(String userId, List<int> likedMovieIds) async {
    try {
      // Update matrix factorization with all liked movies
      await _mfService.updateFromUserLikes(userId, likedMovieIds);
      
      debugPrint('Batch update: Updated models for user $userId');
    } catch (e) {
      debugPrint('Error in batch update: $e');
    }
  }

  /// Incrementally updates user embeddings when preferences change
  Future<void> updateUserEmbeddings(String userId, List<int> newLikedMovies) async {
    try {
      // Update matrix factorization embeddings
      await _mfService.updateFromUserLikes(userId, newLikedMovies);
      
      debugPrint('Updated embeddings for user $userId');
    } catch (e) {
      debugPrint('Error updating user embeddings: $e');
    }
  }

  /// Gets the current model freshness (time since last update)
  Duration? getModelFreshness(String userId) {
    final lastUpdate = _lastUpdateTime[userId];
    if (lastUpdate == null) return null;
    return DateTime.now().difference(lastUpdate);
  }

  /// Forces an update regardless of rate limiting (for testing)
  Future<void> forceUpdate(String userId, int movieId, bool liked) async {
    await RecEngine.instance.recordRating(
      userId,
      movieId,
      liked ? RecEngineRatings.like : RecEngineRatings.dislike,
    );
    _lastUpdateTime[userId] = DateTime.now();
  }

  /// Clears update history (for testing)
  void clearUpdateHistory() {
    _lastUpdateTime.clear();
  }

  /// Saves update history to storage
  Future<void> saveUpdateHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = <String, String>{};
      
      for (final entry in _lastUpdateTime.entries) {
        historyData[entry.key] = entry.value.toIso8601String();
      }
      
      await prefs.setString('online_learning_history', jsonEncode(historyData));
    } catch (e) {
      debugPrint('Error saving update history: $e');
    }
  }

  /// Loads update history from storage
  Future<void> loadUpdateHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('online_learning_history');
      
      if (historyStr != null) {
        final historyData = jsonDecode(historyStr) as Map<String, dynamic>;
        _lastUpdateTime.clear();
        
        for (final entry in historyData.entries) {
          _lastUpdateTime[entry.key] = DateTime.parse(entry.value as String);
        }
      }
    } catch (e) {
      debugPrint('Error loading update history: $e');
    }
  }
}
