import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import 'movie_discovery_service.dart';
import 'matrix_factorization_service.dart';
import 'collaborative_filtering_service.dart';
import 'tmdb_service.dart';

/// Rating values: like=+1, dislike=-0.5, neutral/skip=0 (prompt spec).
class RecEngineRatings {
  static const double like = 1.0;
  static const double dislike = -0.5;
  static const double neutral = 0.0;
}

/// Single recommendation result with hybrid score.
class MovieRec {
  final int movieId;
  final double score;
  final Movie? movie;

  const MovieRec({required this.movieId, required this.score, this.movie});
}

/// Collaborative filtering engine: rating store, ALS-style factors (via MF),
/// hybrid score (0.4*content + 0.4*cf + 0.1*mood + 0.1*popularity), cold start, local cache.
class RecEngine {
  static RecEngine? _instance;
  static RecEngine get instance => _instance ??= RecEngine._();

  RecEngine._();

  static const _ratingsKey = 'rec_engine_user_ratings';
  static const _coldStartThreshold = 3;
  static const _contentWeight = 0.4;
  static const _cfWeight = 0.4;
  static const _moodWeight = 0.1;
  static const _popularityWeight = 0.1;
  static const _maxRecommendations = 50;

  final MatrixFactorizationService _mf = MatrixFactorizationService();
  final CollaborativeFilteringService _cf = CollaborativeFilteringService();
  final MovieDiscoveryService _discovery = MovieDiscoveryService.instance;
  final TMDBService _tmdb = TMDBService();

  /// In-memory rating matrix: userId -> movieId -> rating (+1, -0.5, 0).
  /// Persisted to SharedPreferences; optional Firestore sync to collection `user_ratings` can be added when cloud_firestore is used.
  final Map<String, Map<int, double>> _ratings = {};

  /// Loads rating store from SharedPreferences (call early).
  Future<void> loadRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_ratingsKey);
      if (json == null) return;
      final data = jsonDecode(json) as Map<String, dynamic>;
      _ratings.clear();
      for (final entry in data.entries) {
        final userMap = entry.value as Map<String, dynamic>;
        _ratings[entry.key] = userMap.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        );
      }
    } catch (e) {
      debugPrint('RecEngine: loadRatings error $e');
    }
  }

  /// Persists rating store to SharedPreferences.
  Future<void> _saveRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _ratings.map(
        (u, m) => MapEntry(u, m.map((k, v) => MapEntry(k.toString(), v))),
      );
      await prefs.setString(_ratingsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('RecEngine: saveRatings error $e');
    }
  }

  /// Records a user rating and updates the CF matrix incrementally.
  /// [rating] use RecEngineRatings.like, .dislike, .neutral.
  Future<void> recordRating(String userId, int movieId, double rating) async {
    _ratings.putIfAbsent(userId, () => {})[movieId] = rating;
    await _saveRatings();

    if (rating == RecEngineRatings.like) {
      _cf.recordUserLike(userId, movieId);
    } else if (rating == RecEngineRatings.dislike) {
      _cf.recordUserDislike(userId, movieId);
    }

    final target = rating == RecEngineRatings.like
        ? 1.0
        : (rating == RecEngineRatings.dislike ? -0.5 : 0.0);
    await _mf.updateFromFeedback(userId, movieId, target);
  }

  int _ratingCount(String userId) {
    final userRatings = _ratings[userId];
    if (userRatings == null) return 0;
    return userRatings.values.where((v) => v != RecEngineRatings.neutral).length;
  }

  /// Returns recommendations for [userId] using hybrid score.
  /// Cold start: fallback to content + trending. Uses cached user factors for <500ms.
  /// [moodId] optional (e.g. 'chill', 'excited') for mood_match component.
  Future<List<MovieRec>> getRecommendations(
    String userId, {
    String? moodId,
    List<int>? preferredGenres,
  }) async {
    await loadRatings();
    await _mf.loadFromStorage();

    if (userId.isEmpty) {
      return _fallbackContentAndTrending(
        userId,
        moodId: moodId,
        preferredGenres: preferredGenres,
      );
    }

    final count = _ratingCount(userId);
    if (count < _coldStartThreshold) {
      return _fallbackContentAndTrending(
        userId,
        moodId: moodId,
        preferredGenres: preferredGenres,
      );
    }

    final prefs = UserDiscoveryPrefs(
      likedGenres: preferredGenres ?? const [],
      dislikedGenres: const [],
      streamingServices: const [],
      mood: moodId,
      releaseYear: null,
    );
    List<Movie> candidates;
    try {
      candidates = await _discovery.getDiscoverMoviesBySimilarity(
        userId: userId,
        userPrefs: prefs,
        limit: 80,
      );
    } catch (e) {
      debugPrint('RecEngine: discovery fallback $e');
      return _fallbackContentAndTrending(
        userId,
        moodId: moodId,
        preferredGenres: preferredGenres,
      );
    }

    if (candidates.isEmpty) {
      return _fallbackContentAndTrending(
        userId,
        moodId: moodId,
        preferredGenres: preferredGenres,
      );
    }

    final seenIds = _ratings[userId]?.keys.toSet() ?? {};
    candidates = candidates.where((m) => !seenIds.contains(m.id)).toList();
    if (candidates.isEmpty) return [];

    final contentScores = <int, double>{};
    for (final m in candidates) {
      contentScores[m.id] = (m.weight ?? 0.5).clamp(0.0, 1.0);
    }

    final cfScores = <int, double>{};
    for (final m in candidates) {
      final raw = _mf.getMatrixFactorizationWeight(userId, m.id);
      cfScores[m.id] = raw.clamp(0.0, 1.0);
    }

    final moodScores = <int, double>{};
    final moodGenres = moodId != null ? Mood.getById(moodId)?.preferredGenres : null;
    for (final m in candidates) {
      if (moodGenres != null && m.genreIds != null && moodGenres.isNotEmpty) {
        final match = m.genreIds!.where((g) => moodGenres.contains(g)).length;
        moodScores[m.id] = (match / moodGenres.length).clamp(0.0, 1.0);
      } else {
        moodScores[m.id] = 0.5;
      }
    }

    final popularityScores = <int, double>{};
    double maxPop = 1.0;
    for (final m in candidates) {
      final p = (m.popularity ?? 0) / 100.0;
      if (p > maxPop) maxPop = p;
      popularityScores[m.id] = p;
    }
    if (maxPop > 0) {
      for (final k in popularityScores.keys) {
        popularityScores[k] = (popularityScores[k]! / maxPop).clamp(0.0, 1.0);
      }
    }

    final recs = <MovieRec>[];
    for (final m in candidates) {
      final content = contentScores[m.id] ?? 0.5;
      final cf = cfScores[m.id] ?? 0.5;
      final mood = moodScores[m.id] ?? 0.5;
      final pop = popularityScores[m.id] ?? 0.5;
      final hybrid = _contentWeight * content +
          _cfWeight * cf +
          _moodWeight * mood +
          _popularityWeight * pop;
      recs.add(MovieRec(movieId: m.id, score: hybrid, movie: m));
    }
    recs.sort((a, b) => b.score.compareTo(a.score));
    return recs.take(_maxRecommendations).toList();
  }

  Future<List<MovieRec>> _fallbackContentAndTrending(
    String userId, {
    String? moodId,
    List<int>? preferredGenres,
  }) async {
    final fallbackGenres = preferredGenres ?? [18, 35, 28];
    List<Movie> movies;
    try {
      movies = await _discovery.getDiscoverMoviesBySimilarity(
        userId: userId,
        userPrefs: UserDiscoveryPrefs(
          likedGenres: fallbackGenres,
          dislikedGenres: const [],
          streamingServices: const [],
          mood: moodId,
          releaseYear: null,
        ),
        limit: _maxRecommendations,
      );
    } catch (_) {
      try {
        final list = await _tmdb.getPopularMovies(page: 1);
        movies = list.take(_maxRecommendations).toList();
      } catch (e) {
        debugPrint('RecEngine: fallback error $e');
        return [];
      }
    }
    return movies
        .map((m) => MovieRec(
              movieId: m.id,
              score: m.weight ?? 0.5,
              movie: m,
            ))
        .toList();
  }

  /// Optional: run ALS-style batch update (call in background).
  Future<void> runALSBatch() async {
    await loadRatings();
    await _mf.loadFromStorage();
  }

  /// Clears rating store for a user.
  Future<void> clearRatingsForUser(String userId) async {
    _ratings.remove(userId);
    await _saveRatings();
  }
}
