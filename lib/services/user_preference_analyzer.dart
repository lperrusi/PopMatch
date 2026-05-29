import 'dart:async';
import '../models/user.dart';
import 'tmdb_service.dart';

/// User preferences extracted from liked movies
class UserPreferences {
  final List<int> topGenres; // Top 3-5 genres
  final List<int> preferredYears; // Preferred release years
  final double? preferredMinRating; // Minimum rating preference
  final double? preferredMaxRating; // Maximum rating preference
  final List<String> preferredActors; // Top actors
  final List<String> preferredDirectors; // Top directors

  UserPreferences({
    required this.topGenres,
    required this.preferredYears,
    this.preferredMinRating,
    this.preferredMaxRating,
    this.preferredActors = const [],
    this.preferredDirectors = const [],
  });
}

/// Analyzes user preferences from liked movies to generate personalized recommendations
class UserPreferenceAnalyzer {
  final TMDBService _tmdbService = TMDBService();

  /// Analyzes user's liked movies to extract preferences
  Future<UserPreferences> analyzePreferences(User user) async {
    if (user.likedMovies.isEmpty) {
      // Return default preferences based on onboarding if available
      return _getDefaultPreferences(user);
    }

    final genreCounts = <int, int>{};
    final ratingValues = <double>[];
    final actorCounts = <String, int>{};
    final directorCounts = <String, int>{};

    // Fetch details + credits for up to 30 liked movies in parallel
    final moviesToAnalyze = user.likedMovies.take(30).toList();
    final results = await Future.wait(
      moviesToAnalyze.map((movieIdStr) async {
        final id = int.tryParse(movieIdStr);
        if (id == null) return null;
        try {
          final detailsFuture = _tmdbService.getMovieDetails(id);
          final creditsFuture = _tmdbService.getMovieCredits(id);
          final pair = await Future.wait([detailsFuture, creditsFuture]);
          return pair;
        } catch (_) {
          return null;
        }
      }),
      eagerError: false,
    );

    for (final pair in results) {
      if (pair == null) continue;
      final movie = pair[0] as dynamic;
      final credits = pair[1] as Map<String, dynamic>;

      if (movie.genreIds != null) {
        for (final genreId in movie.genreIds as List<int>) {
          genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
        }
      }
      if (movie.voteAverage != null) {
        ratingValues.add(movie.voteAverage as double);
      }

      final cast = credits['cast'] as List? ?? [];
      for (int i = 0; i < cast.length && i < 10; i++) {
        final actorName = cast[i]['name'] as String?;
        if (actorName != null && actorName.isNotEmpty) {
          actorCounts[actorName] = (actorCounts[actorName] ?? 0) + 1;
        }
      }
      final crew = credits['crew'] as List? ?? [];
      for (final person in crew) {
        if (person['job'] == 'Director') {
          final directorName = person['name'] as String?;
          if (directorName != null && directorName.isNotEmpty) {
            directorCounts[directorName] = (directorCounts[directorName] ?? 0) + 1;
          }
        }
      }
    }

    // Extract top genres (top 5)
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(5).map((e) => e.key).toList();

    // Extract top actors (top 10)
    final sortedActors = actorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topActors = sortedActors.take(10).map((e) => e.key).toList();

    // Extract top directors (top 5)
    final sortedDirectors = directorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDirectors = sortedDirectors.take(5).map((e) => e.key).toList();

    // Calculate rating preferences
    double? minRating, maxRating;
    if (ratingValues.isNotEmpty) {
      ratingValues.sort();
      // Use 25th percentile as min, 75th percentile as max
      final minIndex = (ratingValues.length * 0.25).floor();
      final maxIndex = (ratingValues.length * 0.75).floor();
      minRating = ratingValues[minIndex];
      maxRating = ratingValues[maxIndex];
    }

    // If no preferences found, use defaults
    if (topGenres.isEmpty) {
      return _getDefaultPreferences(user);
    }

    return UserPreferences(
      topGenres: topGenres,
      preferredYears: [], // No longer using year preferences
      preferredMinRating: minRating,
      preferredMaxRating: maxRating,
      preferredActors: topActors,
      preferredDirectors: topDirectors,
    );
  }

  /// Gets default preferences from onboarding data
  UserPreferences _getDefaultPreferences(User user) {
    // Try to get genres from onboarding preferences
    final onboardingGenres = user.preferences['selectedGenres'] as List<dynamic>?;
    final genreIds = onboardingGenres?.map((g) => g as int).toList() ?? [];

    return UserPreferences(
      topGenres: genreIds.isNotEmpty ? genreIds : [28, 35, 18], // Action, Comedy, Drama as defaults
      preferredYears: [],
      preferredMinRating: 6.0, // Default minimum rating
      preferredMaxRating: 10.0,
    );
  }

  /// Checks if user has enough data for personalized recommendations.
  /// Threshold lowered to 1 so the first like triggers blended personalization.
  bool hasEnoughData(User user) {
    return user.likedMovies.isNotEmpty;
  }

  /// Returns a 0.0–1.0 blend weight for mixing curated and personalized results.
  /// 0.0 = fully curated (no likes), 1.0 = fully personalized (3+ likes).
  /// Use this to progressively personalize the feed as likes accumulate.
  double blendWeight(User user) {
    return (user.likedMovies.length / 3.0).clamp(0.0, 1.0);
  }
}

