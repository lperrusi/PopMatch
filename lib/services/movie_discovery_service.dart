import 'dart:convert';
import 'dart:math' show sqrt;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import 'tmdb_service.dart';

/// User preferences for discovery (aligned with prompt: likedGenres, dislikedGenres, streamingServices, mood).
class UserDiscoveryPrefs {
  final List<int> likedGenres;
  final List<int> dislikedGenres;
  final List<String> streamingServices; // our platform ids: netflix, hbo_max, etc.
  final String? mood; // chill, excited, romantic, etc.
  final int? releaseYear; // optional filter (e.g. prefer movies from this year or range)

  const UserDiscoveryPrefs({
    this.likedGenres = const [],
    this.dislikedGenres = const [],
    this.streamingServices = const [],
    this.mood,
    this.releaseYear,
  });

  String get cacheKey {
    final parts = [
      likedGenres.join(','),
      dislikedGenres.join(','),
      streamingServices.join(','),
      mood ?? '',
      releaseYear?.toString() ?? '',
    ];
    return parts.join('|').hashCode.toString();
  }
}

/// Mood → TMDB genre IDs (prompt: chill→drama/comedy, excited→action, romantic→romance).
const Map<String, List<int>> _moodToGenreIds = {
  'chill': [18, 35], // Drama, Comedy
  'excited': [28, 12], // Action, Adventure
  'romantic': [10749, 35], // Romance, Comedy
  'happy': [35, 10751, 16], // Comedy, Family, Animation
  'sad': [35, 10751, 18], // Comedy, Family, Drama
  'relaxed': [18, 14, 36], // Drama, Fantasy, History
  'mysterious': [9648, 53, 80], // Mystery, Thriller, Crime
  'nostalgic': [36, 18, 10402], // History, Drama, Music
  'inspired': [18, 36, 99], // Drama, History, Documentary
};

/// TMDB provider ID by our platform id (reverse of StreamingService mapping).
const Map<String, int> _platformIdToTmdbProvider = {
  'netflix': 8,
  'amazon_prime': 9,
  'hulu': 15,
  'disney_plus': 337,
  'apple_tv': 350,
  'hbo_max': 384,
  'peacock': 387,
  'paramount_plus': 531,
  'tubi': 43,
  'pluto_tv': 382,
  'youtube_tv': 188,
};

/// Fixed genre dimension set for TF-style vectors (TMDB movie genre IDs).
const List<int> _genreDimensionIds = [
  28, 12, 16, 35, 80, 99, 18, 10751, 14, 36, 27, 10402, 9648, 10749, 878, 53, 10752, 37,
];

/// Advanced TMDB discovery: discover endpoint + genre/keyword TF-style vectors + cosine similarity + 24h cache + mood mapping.
/// Returns up to 50 movies ranked by content similarity score.
class MovieDiscoveryService {
  static MovieDiscoveryService? _instance;
  static MovieDiscoveryService get instance => _instance ??= MovieDiscoveryService._();

  MovieDiscoveryService._();

  final TMDBService _tmdb = TMDBService();
  static const _cachePrefix = 'movie_discovery_cache_';
  static const _cacheExpiry = Duration(hours: 24);
  static const _maxResults = 50;
  static const _defaultMinRating = 5.0;

  /// Fetches movies via discover filtered by prefs, scores by content similarity, caches 24h.
  /// [userId] used for cache key; pass empty string if no user.
  Future<List<Movie>> getDiscoverMoviesBySimilarity({
    required String userId,
    required UserDiscoveryPrefs userPrefs,
    int limit = _maxResults,
  }) async {
    final cacheKey = '$_cachePrefix${userId}_${userPrefs.cacheKey}';
    try {
      final cached = await _getCached(cacheKey);
      if (cached != null && cached.length >= limit) {
        return cached.take(limit).toList();
      }
    } catch (e) {
      debugPrint('MovieDiscoveryService: cache read error $e');
    }

    List<Movie> movies;
    try {
      movies = await _fetchDiscoverMovies(userPrefs);
    } catch (e) {
      debugPrint('MovieDiscoveryService: discover fetch error $e');
      rethrow;
    }

    if (movies.isEmpty) return [];

    final userVector = _buildUserPreferenceVector(userPrefs);
    final scored = <Movie>[];
    for (final movie in movies) {
      final movieVector = _buildMovieGenreVector(movie);
      final sim = _cosineSimilarity(userVector, movieVector);
      scored.add(movie.copyWith(weight: sim));
    }
    scored.sort((a, b) => (b.weight ?? 0).compareTo(a.weight ?? 0));
    final result = scored.take(limit).toList();

    try {
      await _setCached(cacheKey, result);
    } catch (e) {
      debugPrint('MovieDiscoveryService: cache write error $e');
    }
    return result;
  }

  /// Fetches movies from TMDB discover with genre, year, rating, streaming filters and mood mapping.
  Future<List<Movie>> _fetchDiscoverMovies(UserDiscoveryPrefs prefs) async {
    List<int> genres = List.from(prefs.likedGenres);
    if (prefs.mood != null && prefs.mood!.isNotEmpty) {
      final moodGenres = _moodToGenreIds[prefs.mood!.toLowerCase()];
      if (moodGenres != null) {
        final set = genres.toSet()..addAll(moodGenres);
        genres = set.toList();
      }
    }
    if (genres.isEmpty) {
      genres = [18, 35, 28]; // default: Drama, Comedy, Action
    }

    final year = prefs.releaseYear;
    final minYear = year != null ? year - 2 : DateTime.now().year - 15;
    List<int>? watchProviderIds;
    if (prefs.streamingServices.isNotEmpty) {
      watchProviderIds = prefs.streamingServices
          .map((id) => _platformIdToTmdbProvider[id])
          .whereType<int>()
          .toList();
      if (watchProviderIds.isEmpty) watchProviderIds = null;
    }

    final all = <Movie>[];
    int page = 1;
    while (all.length < _maxResults + 20) {
      final list = await _tmdb.discoverMovies(
        genres: genres,
        year: year,
        minYear: minYear,
        minRating: _defaultMinRating,
        page: page,
        withWatchProviderIds: watchProviderIds,
        watchRegion: 'US',
      );
      if (list.isEmpty) break;
      final seen = all.map((m) => m.id).toSet();
      for (final m in list) {
        if (!seen.contains(m.id)) {
          all.add(m);
          seen.add(m.id);
        }
      }
      if (list.length < 20) break;
      page++;
    }
    return all;
  }

  /// Builds user preference vector (TF-style): positive for liked genres, negative for disliked.
  List<double> _buildUserPreferenceVector(UserDiscoveryPrefs prefs) {
    final vec = List<double>.filled(_genreDimensionIds.length, 0.0);
    final likedSet = prefs.likedGenres.toSet();
    final dislikedSet = prefs.dislikedGenres.toSet();
    for (int i = 0; i < _genreDimensionIds.length; i++) {
      final g = _genreDimensionIds[i];
      if (likedSet.contains(g)) vec[i] = 1.0;
      if (dislikedSet.contains(g)) vec[i] = -0.5;
    }
    if (prefs.mood != null && prefs.mood!.isNotEmpty) {
      final moodGenres = _moodToGenreIds[prefs.mood!.toLowerCase()];
      if (moodGenres != null) {
        for (int i = 0; i < _genreDimensionIds.length; i++) {
          if (moodGenres.contains(_genreDimensionIds[i]) && vec[i] == 0.0) {
            vec[i] = 0.8;
          }
        }
      }
    }
    return vec;
  }

  /// Builds movie genre vector (simple term frequency: 1 if movie has genre, 0 otherwise).
  List<double> _buildMovieGenreVector(Movie movie) {
    final vec = List<double>.filled(_genreDimensionIds.length, 0.0);
    final ids = movie.genreIds ?? [];
    for (int i = 0; i < _genreDimensionIds.length; i++) {
      if (ids.contains(_genreDimensionIds[i])) vec[i] = 1.0;
    }
    return vec;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    normA = sqrt(normA);
    normB = sqrt(normB);
    if (normA == 0.0 || normB == 0.0) return 0.0;
    final sim = dot / (normA * normB);
    return sim.clamp(-1.0, 1.0);
  }

  Future<List<Movie>?> _getCached(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final tsKey = '${key}_ts';
    final ts = prefs.getInt(tsKey);
    if (ts == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - ts > _cacheExpiry.inMilliseconds) {
      await prefs.remove(key);
      await prefs.remove(tsKey);
      return null;
    }
    final json = prefs.getString(key);
    if (json == null) return null;
    final list = jsonDecode(json) as List;
    return list.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _setCached(String key, List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    final tsKey = '${key}_ts';
    final list = movies.map((m) => m.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
    await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clears discovery cache for a user (e.g. on logout).
  Future<void> clearCacheForUser(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_cachePrefix${userId}_';
    for (final k in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await prefs.remove(k);
    }
  }
}
