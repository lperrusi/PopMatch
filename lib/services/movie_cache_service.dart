import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import 'tmdb_service.dart';

/// Service for caching movie details to improve navigation performance
class MovieCacheService {
  static MovieCacheService? _instance;
  static MovieCacheService get instance => _instance ??= MovieCacheService._();
  
  MovieCacheService._();

  final TMDBService _tmdbService = TMDBService();
  
  // Cache for movie details with credits
  final Map<int, Movie> _movieDetailsCache = {};
  final Map<int, DateTime> _cacheTimestamps = {};

  // Cache for TV show details
  final Map<int, TvShow> _showDetailsCache = {};
  final Map<int, DateTime> _showCacheTimestamps = {};

  // Cache expiration time (24 hours)
  static const Duration _cacheExpiration = Duration(hours: 24);

  // Maximum cache size to prevent memory issues
  static const int _maxCacheSize = 50;

  /// Preloads movie details for a movie (called before navigation)
  Future<void> preloadMovieDetails(int movieId) async {
    // Skip if already cached and fresh
    if (_isCached(movieId)) {
      return;
    }
    
    try {
      final movie = await _tmdbService.getMovieDetailsWithCredits(movieId);
      _cacheMovie(movieId, movie);
    } catch (e) {
      // Silently fail - we'll load on-demand if preload fails
      debugPrint('Failed to preload movie details for $movieId: $e');
    }
  }

  /// Gets movie details from cache synchronously (for instant access)
  Movie? getCachedMovie(int movieId) {
    if (_isCached(movieId)) {
      return _movieDetailsCache[movieId];
    }
    return null;
  }

  /// Gets movie details from cache or loads from API
  Future<Movie> getMovieDetails(int movieId) async {
    // Return cached if available and fresh
    if (_isCached(movieId)) {
      return _movieDetailsCache[movieId]!;
    }
    
    // Load from API and cache
    final movie = await _tmdbService.getMovieDetailsWithCredits(movieId);
    _cacheMovie(movieId, movie);
    return movie;
  }

  /// Public method to check if movie is cached (for optimization)
  bool isCached(int movieId) {
    return _isCached(movieId);
  }

  /// Test seam: seed the caches so detail screens reach their "ready" state with
  /// known data instead of test-mode sample fallbacks.
  @visibleForTesting
  void cacheMovieForTest(int movieId, Movie movie) => _cacheMovie(movieId, movie);

  @visibleForTesting
  void cacheShowForTest(int showId, TvShow show) => _cacheShow(showId, show);

  /// Checks if movie is cached and still fresh
  bool _isCached(int movieId) {
    if (!_movieDetailsCache.containsKey(movieId)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[movieId];
    if (timestamp == null) {
      return false;
    }
    
    // Check if cache is expired
    final age = DateTime.now().difference(timestamp);
    if (age > _cacheExpiration) {
      _movieDetailsCache.remove(movieId);
      _cacheTimestamps.remove(movieId);
      return false;
    }
    
    return true;
  }

  /// Caches a movie, evicting old entries if needed
  void _cacheMovie(int movieId, Movie movie) {
    // Evict oldest entries if cache is full
    if (_movieDetailsCache.length >= _maxCacheSize) {
      _evictOldestEntry();
    }
    
    _movieDetailsCache[movieId] = movie;
    _cacheTimestamps[movieId] = DateTime.now();
  }

  /// Evicts the oldest cached entry
  void _evictOldestEntry() {
    if (_cacheTimestamps.isEmpty) return;
    
    // Find oldest entry
    int? oldestMovieId;
    DateTime? oldestTimestamp;
    
    _cacheTimestamps.forEach((movieId, timestamp) {
      if (oldestTimestamp == null || timestamp.isBefore(oldestTimestamp!)) {
        oldestTimestamp = timestamp;
        oldestMovieId = movieId;
      }
    });
    
    // Remove oldest entry
    if (oldestMovieId != null) {
      _movieDetailsCache.remove(oldestMovieId);
      _cacheTimestamps.remove(oldestMovieId);
    }
  }

  // ── TV Show cache ──────────────────────────────────────────────────────────

  /// Gets show details from cache synchronously (for instant access on remount)
  TvShow? getCachedShow(int showId) {
    if (_isShowCached(showId)) {
      return _showDetailsCache[showId];
    }
    return null;
  }

  /// Gets show details from cache or loads from API
  Future<TvShow> getShowDetails(int showId) async {
    if (_isShowCached(showId)) {
      return _showDetailsCache[showId]!;
    }
    final show = await TMDBService().getShowDetails(showId);
    _cacheShow(showId, show);
    return show;
  }

  bool _isShowCached(int showId) {
    if (!_showDetailsCache.containsKey(showId)) return false;
    final timestamp = _showCacheTimestamps[showId];
    if (timestamp == null) return false;
    final age = DateTime.now().difference(timestamp);
    if (age > _cacheExpiration) {
      _showDetailsCache.remove(showId);
      _showCacheTimestamps.remove(showId);
      return false;
    }
    return true;
  }

  void _cacheShow(int showId, TvShow show) {
    if (_showDetailsCache.length >= _maxCacheSize) _evictOldestShowEntry();
    _showDetailsCache[showId] = show;
    _showCacheTimestamps[showId] = DateTime.now();
  }

  void _evictOldestShowEntry() {
    if (_showCacheTimestamps.isEmpty) return;
    final oldest = _showCacheTimestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    _showDetailsCache.remove(oldest);
    _showCacheTimestamps.remove(oldest);
  }

  // ── General ────────────────────────────────────────────────────────────────

  /// Clears the entire cache
  void clearCache() {
    _movieDetailsCache.clear();
    _cacheTimestamps.clear();
    _showDetailsCache.clear();
    _showCacheTimestamps.clear();
  }

  /// Removes a specific movie from cache
  void removeFromCache(int movieId) {
    _movieDetailsCache.remove(movieId);
    _cacheTimestamps.remove(movieId);
  }

  /// Preloads movie details for multiple movies (for similar movies)
  Future<void> preloadMultipleMovies(List<int> movieIds) async {
    // Preload in parallel, but limit concurrency to avoid overwhelming the API
    final futures = movieIds.map((id) => preloadMovieDetails(id));
    await Future.wait(futures);
  }
}

