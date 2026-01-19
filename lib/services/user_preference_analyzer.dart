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

    // Analyze each liked movie (up to 30 for better preference extraction)
    int analyzedCount = 0;
    for (final movieId in user.likedMovies) {
      try {
        final movie = await _tmdbService.getMovieDetails(int.parse(movieId));
        analyzedCount++;
        
        // Count genres
        if (movie.genreIds != null) {
          for (final genreId in movie.genreIds!) {
            genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
          }
        }

        // Collect ratings
        if (movie.voteAverage != null) {
          ratingValues.add(movie.voteAverage!);
        }

        // Fetch credits to extract actors and directors
        try {
          final credits = await _tmdbService.getMovieCredits(movie.id);
          final cast = credits['cast'] as List;
          final crew = credits['crew'] as List;
          
          // Extract top 10 actors (main cast)
          for (int i = 0; i < cast.length && i < 10; i++) {
            final actorName = cast[i]['name'] as String?;
            if (actorName != null && actorName.isNotEmpty) {
              actorCounts[actorName] = (actorCounts[actorName] ?? 0) + 1;
            }
          }
          
          // Extract directors
          for (final person in crew) {
            if (person['job'] == 'Director') {
              final directorName = person['name'] as String?;
              if (directorName != null && directorName.isNotEmpty) {
                directorCounts[directorName] = (directorCounts[directorName] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          // Continue without credits if fetch fails
          continue;
        }
      } catch (e) {
        // Continue with next movie
        continue;
      }

      // Limit analysis to first 30 movies for performance
      if (analyzedCount >= 30) break;
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

  /// Checks if user has enough data for personalized recommendations
  bool hasEnoughData(User user) {
    // Need at least 3 liked movies for meaningful recommendations
    return user.likedMovies.length >= 3;
  }
}

