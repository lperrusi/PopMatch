import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for item-based collaborative filtering
/// Tracks "users who liked X also liked Y" patterns
class CollaborativeFilteringService {
  static final CollaborativeFilteringService _instance =
      CollaborativeFilteringService._internal();
  factory CollaborativeFilteringService() => _instance;
  CollaborativeFilteringService._internal();

  // Co-occurrence matrix: movieId -> {otherMovieId: count}
  final Map<int, Map<int, int>> _coOccurrenceMatrix = {};

  // User-movie interactions: userId -> Set<movieId>
  final Map<String, Set<int>> _userLikes = {};

  // Movie popularity: movieId -> like count
  final Map<int, int> _moviePopularity = {};

  /// Initializes service and loads data from storage
  Future<void> initialize() async {
    await _loadFromStorage();
  }

  /// Records that a user liked a movie
  Future<void> recordUserLike(String userId, int movieId) async {
    _userLikes.putIfAbsent(userId, () => <int>{}).add(movieId);
    _moviePopularity[movieId] = (_moviePopularity[movieId] ?? 0) + 1;

    // Update co-occurrence matrix with other movies this user liked
    final userMovies = _userLikes[userId]!;
    for (final otherMovieId in userMovies) {
      if (otherMovieId != movieId) {
        _coOccurrenceMatrix.putIfAbsent(movieId, () => {})[otherMovieId] =
            (_coOccurrenceMatrix[movieId]![otherMovieId] ?? 0) + 1;
        _coOccurrenceMatrix.putIfAbsent(otherMovieId, () => {})[movieId] =
            (_coOccurrenceMatrix[otherMovieId]![movieId] ?? 0) + 1;
      }
    }

    await _saveToStorage();
  }

  /// Records that a user disliked a movie
  Future<void> recordUserDislike(String userId, int movieId) async {
    // Remove from likes if present
    _userLikes[userId]?.remove(movieId);
    await _saveToStorage();
  }

  /// Gets collaborative filtering score for a movie based on user's liked movies
  double getCollaborativeScore(int movieId, Set<int> userLikedMovies) {
    if (userLikedMovies.isEmpty) return 0.0;

    double totalScore = 0.0;
    int matches = 0;

    // For each movie the user liked, check co-occurrence with candidate movie
    for (final likedMovieId in userLikedMovies) {
      final coOccurrence = _coOccurrenceMatrix[likedMovieId]?[movieId] ?? 0;
      if (coOccurrence > 0) {
        // Normalize by popularity to avoid bias toward popular movies
        final likedMoviePopularity = _moviePopularity[likedMovieId] ?? 1;
        final score = coOccurrence / sqrt(likedMoviePopularity);
        totalScore += score;
        matches++;
      }
    }

    if (matches == 0) return 0.0;

    // Average score normalized by number of liked movies
    return totalScore / userLikedMovies.length;
  }

  /// Gets recommended movies using collaborative filtering
  List<int> getRecommendedMovies(Set<int> userLikedMovies, {int limit = 20}) {
    if (userLikedMovies.isEmpty) return [];

    final movieScores = <int, double>{};

    // For each liked movie, find co-occurring movies
    for (final likedMovieId in userLikedMovies) {
      final coOccurring = _coOccurrenceMatrix[likedMovieId] ?? {};

      for (final entry in coOccurring.entries) {
        final candidateMovieId = entry.key;
        final coOccurrenceCount = entry.value;

        // Skip if user already liked this movie
        if (userLikedMovies.contains(candidateMovieId)) continue;

        // Calculate score (normalized by popularity)
        final candidatePopularity = _moviePopularity[candidateMovieId] ?? 1;
        final score = coOccurrenceCount / sqrt(candidatePopularity);

        movieScores[candidateMovieId] =
            (movieScores[candidateMovieId] ?? 0.0) + score;
      }
    }

    // Sort by score and return top recommendations
    final sorted = movieScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Gets collaborative filtering weight multiplier for a movie
  /// IMPROVED: Better normalization for additive scoring
  double getCollaborativeWeight(int movieId, Set<int> userLikedMovies) {
    final score = getCollaborativeScore(movieId, userLikedMovies);

    // Convert score to weight (0-1 range for additive scoring)
    // Normalize score to 0-1 range (scores typically 0-5)
    // Higher score = higher weight
    if (score > 0) {
      // Normalize: assume max score is around 5.0, clamp to 0-1
      final normalizedScore = (score / 5.0).clamp(0.0, 1.0);
      // Return 0.3-1.0 range (minimum 0.3 for any match)
      return 0.3 + (normalizedScore * 0.7);
    }

    return 0.5; // Neutral weight (0.5) if no collaborative data
  }

  /// Saves data to persistent storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save co-occurrence matrix (simplified - only top pairs)
      final coOccurrenceData = <String, dynamic>{};
      for (final entry in _coOccurrenceMatrix.entries) {
        if (entry.value.isNotEmpty) {
          coOccurrenceData[entry.key.toString()] = entry.value.map(
            (k, v) => MapEntry(k.toString(), v),
          );
        }
      }

      // Save movie popularity
      final popularityData = _moviePopularity.map(
        (k, v) => MapEntry(k.toString(), v),
      );

      await prefs.setString('cf_cooccurrence', jsonEncode(coOccurrenceData));
      await prefs.setString('cf_popularity', jsonEncode(popularityData));
    } catch (e) {
      debugPrint('Error saving collaborative filtering data: $e');
    }
  }

  /// Loads data from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load co-occurrence matrix
      final coOccurrenceStr = prefs.getString('cf_cooccurrence');
      if (coOccurrenceStr != null) {
        final coOccurrenceData =
            jsonDecode(coOccurrenceStr) as Map<String, dynamic>;
        for (final entry in coOccurrenceData.entries) {
          final movieId = int.parse(entry.key);
          final coOccurrences = entry.value as Map<String, dynamic>;
          _coOccurrenceMatrix[movieId] = coOccurrences.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          );
        }
      }

      // Load movie popularity
      final popularityStr = prefs.getString('cf_popularity');
      if (popularityStr != null) {
        final popularityData =
            jsonDecode(popularityStr) as Map<String, dynamic>;
        _moviePopularity.clear();
        for (final entry in popularityData.entries) {
          _moviePopularity[int.parse(entry.key)] = entry.value as int;
        }
      }
    } catch (e) {
      debugPrint('Error loading collaborative filtering data: $e');
    }
  }

  /// Clears all data (for testing or privacy)
  Future<void> clearData() async {
    _coOccurrenceMatrix.clear();
    _userLikes.clear();
    _moviePopularity.clear();
    await _saveToStorage();
  }
}
