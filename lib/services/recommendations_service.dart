import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../models/mood.dart';
import 'tmdb_service.dart';

/// Advanced service for generating personalized movie recommendations using ML techniques
class RecommendationsService {
  static RecommendationsService? _instance;
  static RecommendationsService get instance =>
      _instance ??= RecommendationsService._();

  RecommendationsService._();

  final TMDBService _tmdbService = TMDBService();

  // Enhanced recommendation weights for AI-powered approach
  static const double _userPreferenceWeight = 0.30;
  static const double _collaborativeWeight = 0.25;
  static const double _contentBasedWeight = 0.25;
  static const double _contextualWeight = 0.10;
  static const double _popularityWeight = 0.10;

  // AI-powered recommendation features
  final Map<String, double> _userBehaviorPatterns = {};
  final Map<String, double> _genreAffinities = {};
  final Map<String, double> _directorAffinities = {};
  final Map<String, double> _actorAffinities = {};
  final Set<int> _recentlySkippedMovieIds = <int>{};
  final Set<int> _recentlyLikedMovieIds = <int>{};

  /// Generates AI-powered personalized recommendations
  Future<List<Movie>> getPersonalizedRecommendations(User user,
      {int limit = 20}) async {
    try {
      // Update user behavior patterns
      await _updateUserBehaviorPatterns(user);

      // Get different types of AI-powered recommendations
      final userBasedRecs = await _getAIUserBasedRecommendations(user);
      final collaborativeRecs = await _getAICollaborativeRecommendations(user);
      final contentBasedRecs = await _getAIContentBasedRecommendations(user);
      final contextualRecs = await _getContextualRecommendations(user);
      final popularRecs = await _getPopularRecommendations();

      // Combine and weight recommendations with AI scoring
      final allRecs = <Movie>[];
      allRecs.addAll(userBasedRecs
          .map((m) => _addAIWeight(m, _userPreferenceWeight, user)));
      allRecs.addAll(collaborativeRecs
          .map((m) => _addAIWeight(m, _collaborativeWeight, user)));
      allRecs.addAll(contentBasedRecs
          .map((m) => _addAIWeight(m, _contentBasedWeight, user)));
      allRecs.addAll(
          contextualRecs.map((m) => _addAIWeight(m, _contextualWeight, user)));
      allRecs.addAll(
          popularRecs.map((m) => _addAIWeight(m, _popularityWeight, user)));

      // Remove duplicates and sort by AI-enhanced weight
      final uniqueRecs = _removeDuplicates(allRecs);
      uniqueRecs.sort((a, b) => (b.weight ?? 0).compareTo(a.weight ?? 0));

      // Filter out already liked/disliked movies
      final filteredRecs = _filterUserHistory(uniqueRecs, user);

      // Apply AI-powered diversity boost
      final diverseRecs = _applyAIDiversityBoost(filteredRecs, user);

      return diverseRecs.take(limit).toList();
    } catch (e) {
      // Fallback to popular movies
      return await _getPopularRecommendations();
    }
  }

  /// Updates user behavior patterns for AI analysis
  Future<void> _updateUserBehaviorPatterns(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactions = prefs.getStringList('user_interactions') ?? [];
      _recentlySkippedMovieIds.clear();
      _recentlyLikedMovieIds.clear();

      // Analyze recent interactions (last 30 days)
      final recentInteractions = interactions
          .map((interaction) => jsonDecode(interaction) as Map<String, dynamic>)
          .where((interaction) {
        final timestamp = DateTime.parse(interaction['timestamp']);
        return DateTime.now().difference(timestamp).inDays <= 30;
      }).toList();

      // Update behavior patterns
      for (final interaction in recentInteractions) {
        final movieId = interaction['movieId']?.toString();
        final type = interaction['type']?.toString();
        final parsedMovieId = int.tryParse(movieId ?? '');
        if (parsedMovieId != null) {
          if (type == 'like') {
            _recentlyLikedMovieIds.add(parsedMovieId);
          } else if (type == 'dislike' || type == 'skip') {
            _recentlySkippedMovieIds.add(parsedMovieId);
          }
        }

        if (movieId == null || movieId.isEmpty) {
          continue;
        }
        if (type == 'like') {
          _userBehaviorPatterns[movieId] =
              (_userBehaviorPatterns[movieId] ?? 0) + 1.0;
        } else if (type == 'dislike') {
          _userBehaviorPatterns[movieId] =
              (_userBehaviorPatterns[movieId] ?? 0) - 1.0;
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Gets AI-powered user-based recommendations
  Future<List<Movie>> _getAIUserBasedRecommendations(User user) async {
    final recommendations = <Movie>[];

    // Analyze user's liked movies with AI-enhanced preference extraction
    final userPreferences = await _analyzeAIUserPreferences(user);

    // Get movies similar to liked movies with AI similarity scoring
    for (final likedMovieId in user.likedMovies) {
      try {
        final movie =
            await _tmdbService.getMovieDetails(int.parse(likedMovieId));
        // Get similar movies using AI-enhanced similarity
        final similarMovies = await _tmdbService.getSimilarMovies(movie.id);
        final aiScoredMovies =
            await _applyAISimilarityScoring(similarMovies, movie);
        recommendations.addAll(aiScoredMovies);
      } catch (e) {
        // Continue with next movie
      }
    }

    // Get movies based on AI-analyzed preferred genres
    for (final genreId in userPreferences['preferredGenres'] ?? []) {
      try {
        final genreMovies = await _tmdbService.getMoviesByGenre(genreId);
        final aiScoredGenreMovies =
            await _applyAIGenreScoring(genreMovies, genreId, user);
        recommendations.addAll(aiScoredGenreMovies);
      } catch (e) {
        // Continue with next genre
      }
    }

    return recommendations;
  }

  /// Analyzes user preferences with AI-enhanced techniques
  Future<Map<String, dynamic>> _analyzeAIUserPreferences(User user) async {
    final preferences = <String, dynamic>{
      'preferredGenres': <int>[],
      'preferredYears': <int>[],
      'preferredActors': <String>[],
      'preferredDirectors': <String>[],
      'preferredLanguages': <String>[],
      'preferredRuntime': <int>[],
      'preferredRatings': <double>[],
    };

    final genreCounts = <int, int>{};
    final yearCounts = <int, int>{};
    final actorCounts = <String, int>{};
    final directorCounts = <String, int>{};
    final languageCounts = <String, int>{};
    final runtimeCounts = <int, int>{};
    final ratingCounts = <double, int>{};

    // Analyze each liked movie with AI-enhanced analysis
    for (final movieId in user.likedMovies) {
      try {
        final movie = await _tmdbService.getMovieDetails(int.parse(movieId));
        // Count genres with AI weighting
        if (movie.genreIds != null) {
          for (final genreId in movie.genreIds!) {
            genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
            _genreAffinities[genreId.toString()] =
                (_genreAffinities[genreId.toString()] ?? 0) + 1.0;
          }
        }

        // Count years with trend analysis
        if (movie.year != null) {
          final year = int.tryParse(movie.year!);
          if (year != null) {
            yearCounts[year] = (yearCounts[year] ?? 0) + 1;
          }
        }

        // Get movie credits for AI-enhanced actor/director analysis
        try {
          final credits = await _tmdbService.getMovieCredits(movie.id);
          final cast = credits['cast'] as List;
          final crew = credits['crew'] as List;

          // AI-enhanced actor analysis
          for (int i = 0; i < min(10, cast.length); i++) {
            final actor = cast[i]['name'] as String;
            actorCounts[actor] = (actorCounts[actor] ?? 0) + 1;
            _actorAffinities[actor] = (_actorAffinities[actor] ?? 0) + 1.0;
          }

          // AI-enhanced director analysis
          for (final person in crew) {
            if (person['job'] == 'Director') {
              final director = person['name'] as String;
              directorCounts[director] = (directorCounts[director] ?? 0) + 1;
              _directorAffinities[director] =
                  (_directorAffinities[director] ?? 0) + 1.0;
            }
          }
        } catch (e) {
          // Continue without credits
        }

        // Analyze additional movie attributes
        if (movie.originalLanguage != null) {
          languageCounts[movie.originalLanguage!] =
              (languageCounts[movie.originalLanguage!] ?? 0) + 1;
        }

        if (movie.runtime != null) {
          runtimeCounts[movie.runtime!] =
              (runtimeCounts[movie.runtime!] ?? 0) + 1;
        }

        if (movie.voteAverage != null) {
          ratingCounts[movie.voteAverage!] =
              (ratingCounts[movie.voteAverage!] ?? 0) + 1;
        }
      } catch (e) {
        // Continue with next movie
      }
    }

    // Get AI-enhanced top preferences
    preferences['preferredGenres'] = _getAITopItems(genreCounts, 8);
    preferences['preferredYears'] = _getAITopItems(yearCounts, 5);
    preferences['preferredActors'] = _getAITopItems(actorCounts, 8);
    preferences['preferredDirectors'] = _getAITopItems(directorCounts, 5);
    preferences['preferredLanguages'] = _getAITopItems(languageCounts, 3);
    preferences['preferredRuntime'] = _getAITopItems(runtimeCounts, 5);
    preferences['preferredRatings'] = _getAITopItems(ratingCounts, 5);

    return preferences;
  }

  /// Gets AI-enhanced top items with weighted scoring
  List<T> _getAITopItems<T>(Map<T, int> counts, int limit) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Applies AI similarity scoring to movies
  Future<List<Movie>> _applyAISimilarityScoring(
      List<Movie> movies, Movie referenceMovie) async {
    final scoredMovies = <Movie>[];

    for (final movie in movies) {
      double similarityScore = 0.0;

      // Genre similarity
      if (movie.genreIds != null && referenceMovie.genreIds != null) {
        final commonGenres = movie.genreIds!
            .toSet()
            .intersection(referenceMovie.genreIds!.toSet());
        similarityScore += commonGenres.length * 0.3;
      }

      // Year similarity
      if (movie.year != null && referenceMovie.year != null) {
        final movieYear = int.tryParse(movie.year!);
        final refYear = int.tryParse(referenceMovie.year!);
        if (movieYear != null && refYear != null) {
          final yearDiff = (movieYear - refYear).abs();
          similarityScore += (10 - yearDiff) * 0.1;
        }
      }

      // Rating similarity
      if (movie.voteAverage != null && referenceMovie.voteAverage != null) {
        final ratingDiff =
            (movie.voteAverage! - referenceMovie.voteAverage!).abs();
        similarityScore += (5 - ratingDiff) * 0.2;
      }

      // Apply similarity score as weight
      movie.weight = (movie.weight ?? 0) + similarityScore;
      scoredMovies.add(movie);
    }

    return scoredMovies;
  }

  /// Applies AI genre scoring to movies
  Future<List<Movie>> _applyAIGenreScoring(
      List<Movie> movies, int genreId, User user) async {
    final scoredMovies = <Movie>[];
    final genreAffinity = _genreAffinities[genreId.toString()] ?? 0.0;

    for (final movie in movies) {
      double genreScore = 0.0;

      // Base genre affinity
      genreScore += genreAffinity * 0.5;

      // Additional genre matches
      if (movie.genreIds != null) {
        for (final movieGenreId in movie.genreIds!) {
          final movieGenreAffinity =
              _genreAffinities[movieGenreId.toString()] ?? 0.0;
          genreScore += movieGenreAffinity * 0.2;
        }
      }

      // Apply genre score as weight
      movie.weight = (movie.weight ?? 0) + genreScore;
      scoredMovies.add(movie);
    }

    return scoredMovies;
  }

  /// Adds AI-enhanced weight to a movie
  Movie _addAIWeight(Movie movie, double baseWeight, User user) {
    double aiWeight = baseWeight;

    // Apply user behavior pattern weighting
    final behaviorScore = _userBehaviorPatterns[movie.id.toString()] ?? 0.0;
    aiWeight += behaviorScore * 0.1;

    // Apply genre affinity weighting
    if (movie.genreIds != null) {
      for (final genreId in movie.genreIds!) {
        final genreAffinity = _genreAffinities[genreId.toString()] ?? 0.0;
        aiWeight += genreAffinity * 0.05;
      }
    }

    movie.weight = (movie.weight ?? 0) + aiWeight;
    return movie;
  }

  /// Applies AI-powered diversity boost
  List<Movie> _applyAIDiversityBoost(List<Movie> movies, User user) {
    final diverseMovies = <Movie>[];
    final usedGenres = <int>{};
    final usedYears = <int>{};

    for (final movie in movies) {
      bool shouldAdd = true;

      // Genre diversity with AI weighting
      if (movie.genreIds != null) {
        int genreOverlap = 0;
        for (final genreId in movie.genreIds!) {
          if (usedGenres.contains(genreId)) {
            genreOverlap++;
          }
        }

        // Allow some genre overlap but encourage diversity
        if (genreOverlap > 2 && diverseMovies.length < 10) {
          shouldAdd = false;
        }
      }

      // Year diversity
      if (movie.year != null) {
        final year = int.tryParse(movie.year!);
        if (year != null && usedYears.contains(year) && usedYears.length < 5) {
          shouldAdd = false;
        }
      }

      if (shouldAdd) {
        diverseMovies.add(movie);

        // Update used sets
        if (movie.genreIds != null) {
          usedGenres.addAll(movie.genreIds!);
        }
        if (movie.year != null) {
          final year = int.tryParse(movie.year!);
          if (year != null) {
            usedYears.add(year);
          }
        }
      }
    }

    return diverseMovies;
  }

  /// Gets contextual recommendations based on time, mood, and other factors
  Future<List<Movie>> _getContextualRecommendations(User user) async {
    final recommendations = <Movie>[];
    final now = DateTime.now();

    // Time-based recommendations
    final hour = now.hour;
    if (hour >= 22 || hour <= 6) {
      // Night time - recommend relaxing, drama, or thriller movies
      final nightMovies = await _tmdbService.getMoviesByGenre(18); // Drama
      recommendations.addAll(nightMovies.take(5));
    } else if (hour >= 7 && hour <= 12) {
      // Morning - recommend light, comedy, or family movies
      final morningMovies = await _tmdbService.getMoviesByGenre(35); // Comedy
      recommendations.addAll(morningMovies.take(5));
    } else if (hour >= 13 && hour <= 17) {
      // Afternoon - recommend action, adventure, or sci-fi movies
      final afternoonMovies = await _tmdbService.getMoviesByGenre(28); // Action
      recommendations.addAll(afternoonMovies.take(5));
    } else {
      // Evening - recommend popular or trending movies
      final eveningMovies = await _tmdbService.getTrendingMovies();
      recommendations.addAll(eveningMovies.take(5));
    }

    return recommendations;
  }

  /// Gets AI-powered collaborative filtering recommendations
  Future<List<Movie>> _getAICollaborativeRecommendations(User user) async {
    // Simplified collaborative filtering based on user preferences
    // In a real app, this would use a backend service with user similarity analysis
    final recommendations = <Movie>[];

    try {
      // Get movies that are popular among users with similar tastes
      final popularMovies = await _tmdbService.getPopularMovies();

      // Apply AI-enhanced collaborative scoring
      for (final movie in popularMovies) {
        double collaborativeScore = 0.0;

        // Score based on user's genre preferences
        if (movie.genreIds != null) {
          for (final genreId in movie.genreIds!) {
            final genreAffinity = _genreAffinities[genreId.toString()] ?? 0.0;
            collaborativeScore += genreAffinity * 0.3;
          }
        }

        // Score based on user's preferred years
        if (movie.year != null) {
          final year = int.tryParse(movie.year!);
          if (year != null) {
            // Check if year is in user's preferred range
            final userPreferences = await _analyzeAIUserPreferences(user);
            final preferredYears =
                userPreferences['preferredYears'] as List<int>;
            if (preferredYears.contains(year)) {
              collaborativeScore += 0.5;
            }
          }
        }

        // Score based on user's preferred ratings
        if (movie.voteAverage != null) {
          final userPreferences = await _analyzeAIUserPreferences(user);
          final preferredRatings =
              userPreferences['preferredRatings'] as List<double>;
          for (final preferredRating in preferredRatings) {
            final ratingDiff = (movie.voteAverage! - preferredRating).abs();
            if (ratingDiff <= 1.0) {
              collaborativeScore += 0.3;
            }
          }
        }

        movie.weight = (movie.weight ?? 0) + collaborativeScore;
        recommendations.add(movie);
      }
    } catch (e) {
      // Fallback to popular movies
      return await _getPopularRecommendations();
    }

    return recommendations;
  }

  /// Gets AI-powered content-based filtering recommendations
  Future<List<Movie>> _getAIContentBasedRecommendations(User user) async {
    final recommendations = <Movie>[];

    try {
      // Get movies based on content similarity to liked movies
      for (final likedMovieId in user.likedMovies) {
        try {
          final likedMovie =
              await _tmdbService.getMovieDetails(int.parse(likedMovieId));
          // Get similar movies with AI-enhanced content analysis
          final similarMovies =
              await _tmdbService.getSimilarMovies(likedMovie.id);

          for (final movie in similarMovies) {
            double contentScore = 0.0;

            // Genre similarity scoring
            if (movie.genreIds != null && likedMovie.genreIds != null) {
              final commonGenres = movie.genreIds!
                  .toSet()
                  .intersection(likedMovie.genreIds!.toSet());
              contentScore += commonGenres.length * 0.4;
            }

            // Year similarity scoring
            if (movie.year != null && likedMovie.year != null) {
              final movieYear = int.tryParse(movie.year!);
              final likedYear = int.tryParse(likedMovie.year!);
              if (movieYear != null && likedYear != null) {
                final yearDiff = (movieYear - likedYear).abs();
                contentScore += (10 - yearDiff) * 0.2;
              }
            }

            // Rating similarity scoring
            if (movie.voteAverage != null && likedMovie.voteAverage != null) {
              final ratingDiff =
                  (movie.voteAverage! - likedMovie.voteAverage!).abs();
              contentScore += (5 - ratingDiff) * 0.3;
            }

            // Language similarity scoring
            if (movie.originalLanguage == likedMovie.originalLanguage) {
              contentScore += 0.2;
            }

            // Runtime similarity scoring
            if (movie.runtime != null && likedMovie.runtime != null) {
              final runtimeDiff = (movie.runtime! - likedMovie.runtime!).abs();
              contentScore += (30 - runtimeDiff) * 0.01;
            }

            movie.weight = (movie.weight ?? 0) + contentScore;
            recommendations.add(movie);
          }
        } catch (e) {
          // Continue with next movie
        }
      }
    } catch (e) {
      // Fallback to popular movies
      return await _getPopularRecommendations();
    }

    return recommendations;
  }

  /// Gets collaborative filtering recommendations (simplified)
  // ignore: unused_element
  Future<List<Movie>> _getCollaborativeRecommendations(User user) async {
    // In a real app, this would use a backend service with user data
    // For now, we'll simulate collaborative filtering based on similar user patterns

    final recommendations = <Movie>[];

    // Get movies that users with similar tastes liked
    final similarUserMovies = await _getSimilarUserRecommendations(user);
    recommendations.addAll(similarUserMovies);

    // Get trending movies in user's preferred genres
    final userPreferences = await _analyzeUserPreferences(user);
    for (final genreId in userPreferences['preferredGenres'] ?? []) {
      try {
        final trendingMovies = await _tmdbService.getMoviesByGenre(genreId);
        recommendations.addAll(trendingMovies.take(5));
      } catch (e) {
        // Continue with next genre
      }
    }

    return recommendations;
  }

  /// Simulates getting recommendations from similar users
  Future<List<Movie>> _getSimilarUserRecommendations(User user) async {
    // This is a simplified version - in a real app, you'd have a user similarity algorithm
    try {
      // Get trending movies as a proxy for what similar users might like
      final trendingMovies = await _tmdbService.getTrendingMovies();
      return trendingMovies.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets content-based filtering recommendations
  // ignore: unused_element
  Future<List<Movie>> _getContentBasedRecommendations(User user) async {
    final recommendations = <Movie>[];

    // Get movies similar to user's liked movies
    for (final likedMovieId in user.likedMovies) {
      try {
        final movie =
            await _tmdbService.getMovieDetails(int.parse(likedMovieId));
        // Get movies with similar characteristics
        final similarMovies = await _getMoviesWithSimilarCharacteristics(movie);
        recommendations.addAll(similarMovies);
      } catch (e) {
        // Continue with next movie
      }
    }

    return recommendations;
  }

  /// Gets movies with similar characteristics (genre, year, rating)
  Future<List<Movie>> _getMoviesWithSimilarCharacteristics(Movie movie) async {
    final similarMovies = <Movie>[];

    // Get movies in similar genres
    if (movie.genreIds != null) {
      for (final genreId in movie.genreIds!) {
        try {
          final genreMovies = await _tmdbService.getMoviesByGenre(genreId);
          similarMovies.addAll(genreMovies.take(3));
        } catch (e) {
          // Continue with next genre
        }
      }
    }

    // Get movies from similar years
    if (movie.year != null) {
      final year = int.tryParse(movie.year!);
      if (year != null) {
        try {
          final yearMovies = await _tmdbService.getMoviesByYear(year);
          similarMovies.addAll(yearMovies.take(3));
        } catch (e) {
          // Continue without year filter
        }
      }
    }

    return similarMovies;
  }

  /// Gets popular movie recommendations
  Future<List<Movie>> _getPopularRecommendations() async {
    try {
      final popularMovies = await _tmdbService.getPopularMovies();
      final trendingMovies = await _tmdbService.getTrendingMovies();
      final topRatedMovies = await _tmdbService.getTopRatedMovies();

      final allMovies = <Movie>[];
      allMovies.addAll(popularMovies);
      allMovies.addAll(trendingMovies);
      allMovies.addAll(topRatedMovies);

      return _removeDuplicates(allMovies);
    } catch (e) {
      return [];
    }
  }

  /// Gets popular movie recommendations (public method)
  Future<List<Movie>> getPopularRecommendations() async {
    return await _getPopularRecommendations();
  }

  /// Removes duplicate movies based on ID
  List<Movie> _removeDuplicates(List<Movie> movies) {
    final seenIds = <int>{};
    return movies.where((movie) {
      if (seenIds.contains(movie.id)) {
        return false;
      }
      seenIds.add(movie.id);
      return true;
    }).toList();
  }

  /// Filters out movies the user has already interacted with
  List<Movie> _filterUserHistory(List<Movie> movies, User user) {
    final likedIds =
        user.likedMovies.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final dislikedIds = user.dislikedMovies
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    // Also check for recently skipped and liked movies from SharedPreferences
    final recentlySkippedIds = _getRecentlySkippedMovies();
    final recentlyLikedIds = _getRecentlyLikedMovies();

    return movies.where((movie) {
      // Don't show movies that user has liked, disliked, or recently interacted with
      return !likedIds.contains(movie.id) &&
          !dislikedIds.contains(movie.id) &&
          !recentlySkippedIds.contains(movie.id) &&
          !recentlyLikedIds.contains(movie.id);
    }).toList();
  }

  /// Gets recently skipped movies from SharedPreferences
  Set<int> _getRecentlySkippedMovies() {
    return _recentlySkippedMovieIds;
  }

  /// Gets recently liked movies from SharedPreferences
  Set<int> _getRecentlyLikedMovies() {
    return _recentlyLikedMovieIds;
  }

  /// Gets "Because you liked X" recommendations
  Future<List<Movie>> getBecauseYouLikedRecommendations(String movieId) async {
    try {
      final movie = await _tmdbService.getMovieDetails(int.parse(movieId));
      return await _tmdbService.getSimilarMovies(movie.id);
    } catch (e) {
      return [];
    }
  }

  /// Gets trending recommendations
  Future<List<Movie>> getTrendingRecommendations() async {
    try {
      return await _tmdbService.getTrendingMovies();
    } catch (e) {
      return [];
    }
  }

  /// Gets recommendations for a specific mood
  Future<List<Movie>> getMoodRecommendations(Mood mood) async {
    final recommendations = <Movie>[];

    // Get movies for each preferred genre of the mood
    for (final genreId in mood.preferredGenres) {
      try {
        final genreMovies = await _tmdbService.getMoviesByGenre(genreId);
        recommendations.addAll(genreMovies);
      } catch (e) {
        // Continue with next genre
      }
    }

    return recommendations;
  }

  /// Gets genre-specific recommendations
  Future<List<Movie>> getGenreRecommendations(int genreId) async {
    try {
      return await _tmdbService.getMoviesByGenre(genreId);
    } catch (e) {
      return [];
    }
  }

  /// Gets year-specific recommendations
  Future<List<Movie>> getYearRecommendations(int year) async {
    try {
      return await _tmdbService.getMoviesByYear(year);
    } catch (e) {
      return [];
    }
  }

  /// Saves user interaction for improving recommendations
  Future<void> saveUserInteraction(
      String movieId, String interactionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactions = prefs.getStringList('user_interactions') ?? [];

      final interaction = {
        'movieId': movieId,
        'type': interactionType, // 'like', 'dislike', 'view', 'watchlist'
        'timestamp': DateTime.now().toIso8601String(),
      };

      interactions.add(jsonEncode(interaction));

      // Keep only last 100 interactions
      if (interactions.length > 100) {
        interactions.removeRange(0, interactions.length - 100);
      }

      await prefs.setStringList('user_interactions', interactions);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Gets user interaction history
  Future<List<Map<String, dynamic>>> getUserInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactions = prefs.getStringList('user_interactions') ?? [];

      return interactions.map((interaction) {
        return jsonDecode(interaction) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets hybrid recommendations (combining multiple approaches)
  Future<List<Movie>> getHybridRecommendations(User user) async {
    return await getPersonalizedRecommendations(user);
  }

  /// Calculates movie similarity score between two movies
  // ignore: unused_element
  double _calculateMovieSimilarity(Movie movie1, Movie movie2) {
    double similarity = 0.0;

    // Genre similarity
    if (movie1.genreIds != null && movie2.genreIds != null) {
      final commonGenres =
          movie1.genreIds!.toSet().intersection(movie2.genreIds!.toSet());
      final totalGenres =
          movie1.genreIds!.toSet().union(movie2.genreIds!.toSet());
      similarity += (commonGenres.length / totalGenres.length) * 0.4;
    }

    // Year similarity
    if (movie1.year != null && movie2.year != null) {
      final year1 = int.tryParse(movie1.year!);
      final year2 = int.tryParse(movie2.year!);
      if (year1 != null && year2 != null) {
        final yearDiff = (year1 - year2).abs();
        similarity += (1.0 / (1.0 + yearDiff / 10.0)) * 0.3;
      }
    }

    // Rating similarity
    if (movie1.voteAverage != null && movie2.voteAverage != null) {
      final ratingDiff = (movie1.voteAverage! - movie2.voteAverage!).abs();
      similarity += (1.0 / (1.0 + ratingDiff / 2.0)) * 0.3;
    }

    return similarity;
  }

  /// Analyzes user preferences based on their liked movies
  Future<Map<String, dynamic>> _analyzeUserPreferences(User user) async {
    final preferences = <String, dynamic>{
      'preferredGenres': <int>[],
      'preferredYears': <int>[],
      'preferredRatings': <double>[],
      'preferredRuntimes': <int>[],
    };

    if (user.likedMovies.isEmpty) {
      // Return default preferences if no liked movies
      return {
        'preferredGenres': [28, 12, 35], // Action, Adventure, Comedy
        'preferredYears': [2020, 2021, 2022],
        'preferredRatings': [7.0, 8.0, 9.0],
        'preferredRuntimes': [90, 120, 150],
      };
    }

    // Analyze liked movies to determine preferences
    for (final movieId in user.likedMovies) {
      try {
        final movie = await _tmdbService.getMovieDetails(int.parse(movieId));
        // Add genres
        if (movie.genreIds != null) {
          preferences['preferredGenres'].addAll(movie.genreIds!);
        }

        // Add year
        if (movie.year != null) {
          final year = int.tryParse(movie.year!);
          if (year != null) {
            preferences['preferredYears'].add(year);
          }
        }

        // Add rating
        if (movie.voteAverage != null) {
          preferences['preferredRatings'].add(movie.voteAverage!);
        }

        // Add runtime
        if (movie.runtime != null) {
          preferences['preferredRuntimes'].add(movie.runtime!);
        }
      } catch (e) {
        // Continue with next movie
      }
    }

    // Get most common preferences
    final genreCounts = <int, int>{};
    for (final genre in preferences['preferredGenres']) {
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }

    final yearCounts = <int, int>{};
    for (final year in preferences['preferredYears']) {
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedYears = yearCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'preferredGenres': sortedGenres.take(5).map((e) => e.key).toList(),
      'preferredYears': sortedYears.take(5).map((e) => e.key).toList(),
      'preferredRatings': preferences['preferredRatings'],
      'preferredRuntimes': preferences['preferredRuntimes'],
    };
  }
}
