import 'package:flutter/foundation.dart';
import '../models/streaming_platform.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import 'tmdb_service.dart';

/// Service for handling streaming platform data and availability.
/// Uses TMDB watch/providers API for accurate "Where to watch" data (no fake fallback).
class StreamingService {
  static StreamingService? _instance;
  static StreamingService get instance => _instance ??= StreamingService._();

  final TMDBService _tmdb = TMDBService();
  static const Duration _availabilityCacheTtl = Duration(minutes: 10);
  final Map<int, ({DateTime cachedAt, MovieStreamingAvailability? value})>
      _movieAvailabilityCache = {};
  final Map<int, ({DateTime cachedAt, MovieStreamingAvailability? value})>
      _tvAvailabilityCache = {};

  /// ISO 3166-1 alpha-2 country code used for all TMDB watch/providers lookups.
  /// Set once at startup via [setUserCountry]. Cache is cleared on change.
  String _userCountry = 'US';

  StreamingService._();

  /// Updates the country used for watch/providers lookups and clears the cache
  /// so stale data from the old country is not served.
  void setUserCountry(String countryCode) {
    if (_userCountry == countryCode) return;
    _userCountry = countryCode;
    _movieAvailabilityCache.clear();
    _tvAvailabilityCache.clear();
    debugPrint('StreamingService: country set to $_userCountry');
  }

  String get userCountry => _userCountry;

  /// TMDB provider_id (from watch/providers API) -> our StreamingPlatform id
  static const Map<int, String> _tmdbProviderIdToPlatformId = {
    8: 'netflix',
    9: 'amazon_prime',
    15: 'hulu',
    337: 'disney_plus',
    350: 'apple_tv',
    384: 'hbo_max',
    1899: 'hbo_max',        // Max (HBO Max renamed 2023)
    387: 'peacock',
    531: 'paramount_plus',
    43: 'tubi',
    382: 'pluto_tv',
    188: 'youtube_tv',
    119: 'amazon_prime',    // Amazon Prime Video (alternate ID)
    283: 'crunchyroll',     // Crunchyroll
    11: 'mubi',             // Mubi (international arthouse)
  };

  /// Gets streaming availability for a movie from TMDB for the user's country.
  ///
  /// Returns:
  /// - `null` if the TMDB API call failed (network error, bad key) — caller
  ///   should treat this as "unknown" and not filter the movie out.
  /// - A [MovieStreamingAvailability] with an **empty** `availablePlatforms`
  ///   list when the API succeeds but the title has no streaming options in
  ///   this country — caller should treat this as "confirmed not streaming".
  /// - A [MovieStreamingAvailability] with populated platforms otherwise.
  Future<MovieStreamingAvailability?> getStreamingAvailability(int movieId) async {
    final cached = _movieAvailabilityCache[movieId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _availabilityCacheTtl) {
      return cached.value;
    }
    try {
      final providerIds = await _tmdb.getMovieWatchProviderIds(movieId, country: _userCountry);
      if (providerIds == null) {
        // API error — return null so callers know data is unavailable.
        return null;
      }
      // Build the platform list (may be empty when title has no streaming in country).
      final platformIds = <String>{};
      for (final tmdbId in providerIds) {
        final ourId = _tmdbProviderIdToPlatformId[tmdbId];
        if (ourId != null && StreamingPlatform.getById(ourId) != null) {
          platformIds.add(ourId);
        }
      }
      final availability = MovieStreamingAvailability(
        movieId: movieId,
        availablePlatforms: platformIds.toList()..sort(),
        rentalPrice: null,
        purchasePrice: null,
        isFree: false,
      );
      _movieAvailabilityCache[movieId] =
          (cachedAt: DateTime.now(), value: availability);
      return availability;
    } catch (e) {
      debugPrint('StreamingService getStreamingAvailability: $e');
      return null;
    }
  }

  /// Gets streaming availability for multiple movies (uses TMDB for each).
  Future<Map<int, MovieStreamingAvailability>> getStreamingAvailabilityForMovies(List<int> movieIds) async {
    final Map<int, MovieStreamingAvailability> result = {};
    for (final movieId in movieIds) {
      final availability = await getStreamingAvailability(movieId);
      if (availability != null) result[movieId] = availability;
    }
    return result;
  }

  /// Gets streaming availability for a TV series from TMDB for the user's country.
  ///
  /// Returns `null` on API error, an empty-platform [MovieStreamingAvailability]
  /// when confirmed not streaming, or a populated one when available.
  Future<MovieStreamingAvailability?> getStreamingAvailabilityForTv(int seriesId) async {
    final cached = _tvAvailabilityCache[seriesId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _availabilityCacheTtl) {
      return cached.value;
    }
    try {
      final providerIds = await _tmdb.getTvWatchProviderIds(seriesId, country: _userCountry);
      if (providerIds == null) {
        // API error — return null so callers know data is unavailable.
        return null;
      }
      final platformIds = <String>{};
      for (final tmdbId in providerIds) {
        final ourId = _tmdbProviderIdToPlatformId[tmdbId];
        if (ourId != null && StreamingPlatform.getById(ourId) != null) {
          platformIds.add(ourId);
        }
      }
      final availability = MovieStreamingAvailability(
        movieId: seriesId,
        availablePlatforms: platformIds.toList()..sort(),
        rentalPrice: null,
        purchasePrice: null,
        isFree: false,
      );
      _tvAvailabilityCache[seriesId] =
          (cachedAt: DateTime.now(), value: availability);
      return availability;
    } catch (e) {
      debugPrint('StreamingService getStreamingAvailabilityForTv: $e');
      return null;
    }
  }

  /// Gets all available streaming platforms
  List<StreamingPlatform> getAvailablePlatforms() {
    return StreamingPlatform.getAvailablePlatforms();
  }

  /// Gets platform by ID
  StreamingPlatform? getPlatformById(String platformId) {
    return StreamingPlatform.getById(platformId);
  }

  /// Filters movies by streaming platform (uses TMDB data)
  Future<List<Movie>> filterMoviesByPlatform(List<Movie> movies, String platformId) async {
    final List<Movie> filteredMovies = [];
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.isAvailableOn(platformId)) {
        filteredMovies.add(movie.copyWith(streamingAvailability: availability));
      }
    }
    return filteredMovies;
  }

  /// Gets movies available on any of the given platforms (uses TMDB data).
  ///
  /// Three-way outcome per movie:
  /// - API error (`null`) → include (unknown, can't confirm either way)
  /// - Confirmed not streaming (empty platforms) → exclude
  /// - On a selected platform → include with availability attached
  /// - On streaming but not a selected platform → exclude
  Future<List<Movie>> getMoviesOnMultiplePlatforms(List<Movie> movies, List<String> platformIds) async {
    // All availability checks run in parallel — callers are expected to pre-limit
    // the input list (e.g., top 80) so this stays fast.
    final availabilities = await Future.wait(
      movies.map((movie) => getStreamingAvailability(movie.id)),
      eagerError: false,
    );
    final filteredMovies = <Movie>[];
    for (var j = 0; j < movies.length; j++) {
      final availability = availabilities[j];
      if (availability == null) {
        // API error — include without tag; _applyFilters will pass it through.
        filteredMovies.add(movies[j]);
      } else if (availability.availablePlatforms.isEmpty) {
        // Confirmed not on streaming in this country — exclude.
      } else if (platformIds.any((id) => availability.isAvailableOn(id))) {
        filteredMovies.add(movies[j].copyWith(streamingAvailability: availability));
      }
      // Else: on streaming but not on any selected platform — exclude.
    }
    return filteredMovies;
  }

  /// Gets TV shows available on any of the given platforms (uses TMDB watch providers for TV).
  ///
  /// Same three-way logic as [getMoviesOnMultiplePlatforms].
  Future<List<TvShow>> getShowsOnMultiplePlatforms(List<TvShow> shows, List<String> platformIds) async {
    // All availability checks run in parallel — callers are expected to pre-limit
    // the input list (e.g., top 80) so this stays fast.
    final availabilities = await Future.wait(
      shows.map((show) => getStreamingAvailabilityForTv(show.id)),
      eagerError: false,
    );
    final filteredShows = <TvShow>[];
    for (var j = 0; j < shows.length; j++) {
      final availability = availabilities[j];
      if (availability == null) {
        // API error — include without tag.
        filteredShows.add(shows[j]);
      } else if (availability.availablePlatforms.isEmpty) {
        // Confirmed not on streaming in this country — exclude.
      } else if (platformIds.any((id) => availability.isAvailableOn(id))) {
        filteredShows.add(shows[j].copyWith(streamingAvailability: availability));
      }
      // Else: on streaming but not on any selected platform — exclude.
    }
    return filteredShows;
  }

  /// Gets free movies (TMDB flatrate only; we don't get free vs paid from API, so this may be empty)
  Future<List<Movie>> getFreeMovies(List<Movie> movies) async {
    final List<Movie> freeMovies = [];
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.isFree) {
        freeMovies.add(movie.copyWith(streamingAvailability: availability));
      }
    }
    return freeMovies;
  }

  /// Gets movies available for rent under a certain price (TMDB doesn't give price in list; kept for API compatibility)
  Future<List<Movie>> getMoviesUnderRentalPrice(List<Movie> movies, double maxPrice) async {
    final List<Movie> affordableMovies = [];
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null && availability.rentalPrice != null) {
        final priceString = availability.rentalPrice!.replaceAll('\$', '');
        final price = double.tryParse(priceString);
        if (price != null && price <= maxPrice) {
          affordableMovies.add(movie.copyWith(streamingAvailability: availability));
        }
      }
    }
    return affordableMovies;
  }

  /// Gets platform statistics (uses TMDB data)
  Future<Map<String, int>> getPlatformStatistics(List<Movie> movies) async {
    final Map<String, int> platformStats = {};
    for (final movie in movies) {
      final availability = await getStreamingAvailability(movie.id);
      if (availability != null) {
        for (final platformId in availability.availablePlatforms) {
          platformStats[platformId] = (platformStats[platformId] ?? 0) + 1;
        }
      }
    }
    return platformStats;
  }
} 