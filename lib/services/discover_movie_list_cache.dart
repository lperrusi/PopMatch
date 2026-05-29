import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';

/// Persists the last-fetched Discover deck to SharedPreferences so cards can be
/// shown instantly on the next cold open while fresh content loads in background.
class DiscoverMovieListCache {
  static final DiscoverMovieListCache _instance =
      DiscoverMovieListCache._internal();
  factory DiscoverMovieListCache() => _instance;
  DiscoverMovieListCache._internal();

  static DiscoverMovieListCache get instance => _instance;

  // Movie deck cache keys
  static const String keyCurated = 'curated';
  static const String keyPersonalized = 'personalized';

  // Show deck cache keys
  static const String keyShowsCurated = 'shows_curated';
  static const String keyShowsPersonalized = 'shows_personalized';

  static const Duration _curatedTtl = Duration(hours: 24);
  static const Duration _personalizedTtl = Duration(hours: 12);

  Duration _ttlFor(String cacheKey) =>
      cacheKey == keyPersonalized ? _personalizedTtl : _curatedTtl;

  String _spKey(String cacheKey) => 'discover_movie_list_$cacheKey';

  /// Returns the cached movie list if it exists and hasn't expired, otherwise null.
  Future<List<Movie>?> load(String cacheKey) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final json = sp.getString(_spKey(cacheKey));
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
      if (cachedAt == null) return null;

      if (DateTime.now().difference(cachedAt) > _ttlFor(cacheKey)) {
        unawaited(sp.remove(_spKey(cacheKey)));
        return null;
      }

      final list = map['movies'] as List<dynamic>;
      return list
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Persists up to 50 movies from [movies] to SharedPreferences.
  Future<void> save(String cacheKey, List<Movie> movies) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _spKey(cacheKey),
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'movies': movies.take(50).map((m) => m.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  /// Removes the cached list for [cacheKey].
  Future<void> clear(String cacheKey) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_spKey(cacheKey));
    } catch (_) {}
  }

  // ── TV Show variants ────────────────────────────────────────────────────────

  Future<List<TvShow>?> loadShows(String cacheKey) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final json = sp.getString(_spKey(cacheKey));
      if (json == null) return null;

      final map = jsonDecode(json) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
      if (cachedAt == null) return null;

      if (DateTime.now().difference(cachedAt) > _ttlFor(cacheKey)) {
        unawaited(sp.remove(_spKey(cacheKey)));
        return null;
      }

      final list = map['shows'] as List<dynamic>;
      return list
          .map((e) => TvShow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveShows(String cacheKey, List<TvShow> shows) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(
        _spKey(cacheKey),
        jsonEncode({
          'cachedAt': DateTime.now().toIso8601String(),
          'shows': shows.take(50).map((s) => s.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }
}

