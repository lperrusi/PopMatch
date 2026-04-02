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
  static const int _platformFilterBatchSize = 6;
  final Map<int, ({DateTime cachedAt, MovieStreamingAvailability? value})>
      _movieAvailabilityCache = {};
  final Map<int, ({DateTime cachedAt, MovieStreamingAvailability? value})>
      _tvAvailabilityCache = {};

  StreamingService._();

  /// TMDB provider_id (from watch/providers API) -> our StreamingPlatform id
  static const Map<int, String> _tmdbProviderIdToPlatformId = {
    8: 'netflix',
    9: 'amazon_prime',
    15: 'hulu',
    337: 'disney_plus',
    350: 'apple_tv',
    384: 'hbo_max',
    387: 'peacock',
    531: 'paramount_plus',
    43: 'tubi',
    382: 'pluto_tv',
    188: 'youtube_tv',
    119: 'amazon_prime', // Amazon Prime Video (alternate)
  };

  /// Gets streaming availability for a movie from TMDB (US region). Returns null if no data.
  Future<MovieStreamingAvailability?> getStreamingAvailability(int movieId) async {
    final cached = _movieAvailabilityCache[movieId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _availabilityCacheTtl) {
      return cached.value;
    }
    try {
      final providerIds = await _tmdb.getMovieWatchProviderIds(movieId, country: 'US');
      if (providerIds.isEmpty) return null;
      final platformIds = <String>{};
      for (final tmdbId in providerIds) {
        final ourId = _tmdbProviderIdToPlatformId[tmdbId];
        if (ourId != null && StreamingPlatform.getById(ourId) != null) {
          platformIds.add(ourId);
        }
      }
      if (platformIds.isEmpty) return null;
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

  /// Gets streaming availability for a TV series from TMDB (US region). Returns null if no data.
  Future<MovieStreamingAvailability?> getStreamingAvailabilityForTv(int seriesId) async {
    final cached = _tvAvailabilityCache[seriesId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _availabilityCacheTtl) {
      return cached.value;
    }
    try {
      final providerIds = await _tmdb.getTvWatchProviderIds(seriesId, country: 'US');
      if (providerIds.isEmpty) return null;
      final platformIds = <String>{};
      for (final tmdbId in providerIds) {
        final ourId = _tmdbProviderIdToPlatformId[tmdbId];
        if (ourId != null && StreamingPlatform.getById(ourId) != null) {
          platformIds.add(ourId);
        }
      }
      if (platformIds.isEmpty) return null;
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

  /// Gets movies available on any of the given platforms (uses TMDB data)
  Future<List<Movie>> getMoviesOnMultiplePlatforms(List<Movie> movies, List<String> platformIds) async {
    final List<Movie> filteredMovies = [];
    for (var i = 0; i < movies.length; i += _platformFilterBatchSize) {
      final batch = movies.skip(i).take(_platformFilterBatchSize).toList();
      final availabilities = await Future.wait(
        batch.map((movie) => getStreamingAvailability(movie.id)),
      );
      for (var j = 0; j < batch.length; j++) {
        final availability = availabilities[j];
        if (availability != null) {
          final onAny = platformIds.any((id) => availability.isAvailableOn(id));
          if (onAny) {
            filteredMovies
                .add(batch[j].copyWith(streamingAvailability: availability));
          }
        }
      }
    }
    return filteredMovies;
  }

  /// Gets TV shows available on any of the given platforms (uses TMDB watch providers for TV).
  Future<List<TvShow>> getShowsOnMultiplePlatforms(List<TvShow> shows, List<String> platformIds) async {
    final List<TvShow> filteredShows = [];
    for (var i = 0; i < shows.length; i += _platformFilterBatchSize) {
      final batch = shows.skip(i).take(_platformFilterBatchSize).toList();
      final availabilities = await Future.wait(
        batch.map((show) => getStreamingAvailabilityForTv(show.id)),
      );
      for (var j = 0; j < batch.length; j++) {
        final availability = availabilities[j];
        if (availability != null) {
          final onAny = platformIds.any((id) => availability.isAvailableOn(id));
          if (onAny) {
            filteredShows
                .add(batch[j].copyWith(streamingAvailability: availability));
          }
        }
      }
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