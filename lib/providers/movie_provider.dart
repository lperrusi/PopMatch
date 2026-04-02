import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../models/user.dart';
import '../services/tmdb_service.dart';
import '../services/user_preference_analyzer.dart';
import '../services/user_preferences_session_cache.dart';
import '../services/streaming_service.dart';
import '../services/contextual_recommendation_service.dart';
import '../services/behavior_tracking_service.dart';
import '../services/movie_embedding_service.dart';
import '../services/collaborative_filtering_service.dart';
import '../services/movie_cache_service.dart';
import '../services/adaptive_weighting_service.dart';
import '../services/recommendation_metrics_service.dart';
import '../services/matrix_factorization_service.dart';
import '../services/online_learning_service.dart';
import '../services/ab_testing_service.dart';
import '../services/omdb_service.dart';
import '../services/movie_discovery_service.dart';
import '../models/streaming_platform.dart';

Set<int> _movieIdsFromUserStrings(Iterable<String> raw) {
  final out = <int>{};
  for (final id in raw) {
    final v = int.tryParse(id);
    if (v != null) out.add(v);
  }
  return out;
}

/// Provider class for managing movie data and filtering
class MovieProvider with ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final ContextualRecommendationService _contextualService = ContextualRecommendationService();
  final BehaviorTrackingService _behaviorService = BehaviorTrackingService();
  final MovieEmbeddingService _embeddingService = MovieEmbeddingService();
  final CollaborativeFilteringService _collaborativeService = CollaborativeFilteringService();
  final AdaptiveWeightingService _adaptiveWeighting = AdaptiveWeightingService();
  final RecommendationMetricsService _metricsService = RecommendationMetricsService();
  final MatrixFactorizationService _mfService = MatrixFactorizationService();
  final OnlineLearningService _onlineLearningService = OnlineLearningService();
  final ABTestingService _abTestingService = ABTestingService();
  final OMDbService _omdbService = OMDbService.instance;
  
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  Map<int, String> _genres = {};
  bool _skipLoadGenresForTest = false;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  
  // INFINITE SWIPE: Buffer management for seamless experience
  static const int _minBufferSize = 30; // Target minimum titles in the feed
  static const int _preloadThreshold = 20; // Start preloading when this many remain (earlier = less “empty”)
  static const int _maxTmdbPages = 400; // Stop paging after this (TMDB caps ~500)
  static const int _minLengthToDeferBackgroundAdds = 3;
  static const int _flushPendingWhenVisibleAtMost = 8;
  bool _isPreloading = false; // Track if we're currently preloading
  DateTime? _lastPreloadTime; // Rate limit preloading
  final List<Movie> _pendingMovies = [];

  // Filter states
  int? _selectedGenreId;
  int? _selectedYear;
  String _searchQuery = '';
  Mood? _currentMood;
  
  // Swipe screen filter states
  List<Mood> _swipeMoods = []; // Changed to support multiple moods
  List<int> _swipeSelectedGenres = [];
  List<String> _swipeSelectedPlatforms = [];

  // Production recs: recalc feed after every 5 swipes
  int _swipeCountSinceRecalc = 0;

  // Getters
  List<Movie> get movies => _movies;
  List<Movie> get filteredMovies => _filteredMovies;
  Map<int, String> get genres => _genres;
  bool get isLoading => _isLoading;
  /// True while fetching the next page for infinite swipe.
  bool get isPreloading => _isPreloading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
  int get remainingMoviesCount => _filteredMovies.length;
  int get pendingMoviesCount => _pendingMovies.length;

  /// After the first Discover fetch completes, tab-return refills use [refresh: false]
  /// so TMDB pagination continues instead of resetting to page 1 (which replays old cards).
  bool _discoverBootstrapComplete = false;
  bool get discoverBootstrapComplete => _discoverBootstrapComplete;

  final Map<int, Map<String, dynamic>> _movieCreditsSessionCache = {};
  final Map<int, List<Movie>> _movieSimilarSessionCache = {};
  final Map<int, List<Movie>> _movieRecommendationsSessionCache = {};
  final UserPreferencesSessionCache _prefsCache = UserPreferencesSessionCache();

  /// Called when the user swipes away the last card — clears the deck and shows loading
  /// before [refillSwipeDeckAfterEnd] network work (avoids a blank non-empty stack).
  void beginDiscoverRefillLoading() {
    _isLoading = true;
    _movies.clear();
    _pendingMovies.clear();
    _applyFilters();
    notifyListeners();
  }

  void _logPerf(String label, Stopwatch sw) {
    if (!kDebugMode) return;
    debugPrint('MovieProvider perf [$label]: ${sw.elapsedMilliseconds}ms');
  }

  bool get needsPreload => _filteredMovies.length < _preloadThreshold && _hasMorePages && !_isLoading && !_isPreloading;
  int? get selectedGenreId => _selectedGenreId;
  int? get selectedYear => _selectedYear;
  String get searchQuery => _searchQuery;
  Mood? get currentMood => _currentMood;
  
  // Swipe screen filter getters
  List<Mood> get swipeMoods => _swipeMoods;
  List<int> get swipeSelectedGenres => _swipeSelectedGenres;
  List<String> get swipeSelectedPlatforms => _swipeSelectedPlatforms;

  /// Initializes the movie provider and loads initial data
  Future<void> initialize() async {
    // Use microtask to ensure this runs after the build phase
    // Only load genres here - let individual screens decide which movies to load
    // (curated starter movies for new users, personalized for existing users)
    await Future.microtask(() async {
      await loadGenres();
      // NEW: Initialize matrix factorization and online learning services
      await _mfService.loadFromStorage();
      await _onlineLearningService.loadUpdateHistory();
    });
  }

  /// Loads popular movies from TMDB API.
  /// When [user] is set (Discover), excludes liked/disliked/skipped/watchlist.
  Future<void> loadPopularMovies({bool refresh = false, User? user}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _movies.clear();
        _pendingMovies.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      }
      
      // Don't notify listeners here - wait until after the async operation
      var newMovies = await _tmdbService.getPopularMovies(page: _currentPage);
      if (user != null) {
        final likedIds = _movieIdsFromUserStrings(user.likedMovies);
        final dislikedIds = _movieIdsFromUserStrings(user.dislikedMovies);
        final skippedIds = _behaviorService.getSkippedMovies(user.id);
        final watchlistIds = _movieIdsFromUserStrings(user.watchlist);
        newMovies = newMovies
            .where(
              (m) =>
                  !likedIds.contains(m.id) &&
                  !dislikedIds.contains(m.id) &&
                  !skippedIds.contains(m.id) &&
                  !watchlistIds.contains(m.id),
            )
            .toList();
      }

      if (refresh) {
        _movies = newMovies;
      } else {
        _movies.addAll(newMovies);
      }
      
      _hasMorePages = newMovies.isNotEmpty;
      if (user != null) {
        refreshFilters(user);
      } else {
        _applyFilters();
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (user != null) {
        _discoverBootstrapComplete = true;
      }
      notifyListeners();
    }
  }

  /// Loads a curated starter movie list designed to help the algorithm learn user preferences
  /// This list prioritizes both popularity and rating while maintaining genre diversity for optimal learning.
  /// If [user] is provided, filters out already liked, disliked, skipped, and watchlist movies.
  Future<void> loadCuratedStarterMovies({bool refresh = false, User? user}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _movies.clear();
        _pendingMovies.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      } else {
        // When loading more (not refreshing), increment page for pagination
        _currentPage++;
      }

      final allMovies = <Movie>[];
      final seenMovieIds = <int>{};

      // Strategy 1: Get highly-rated popular movies (best of both worlds)
      // These are movies that are both well-known AND well-liked
      try {
        // Get top-rated movies that are also popular (min 100 votes for credibility)
        // Use currentPage for pagination when loading more
        final topRatedPopular = await _tmdbService.discoverMovies(
          minRating: 7.0, // Good rating threshold
          sortBy: 'popularity.desc', // Prioritize popularity
          page: refresh ? 1 : _currentPage,
        );
        
        // Take top 25 highly-rated popular movies
        for (final movie in topRatedPopular.take(25)) {
          allMovies.add(movie);
          seenMovieIds.add(movie.id);
        }
      } catch (e) {
        debugPrint('Error loading top-rated popular movies: $e');
      }

      // Strategy 2: Get most popular movies
      // These are movies users are most likely to know
      try {
        // Use currentPage for pagination when loading more
        final pagePopular = await _tmdbService.getPopularMovies(page: refresh ? 1 : _currentPage);
        
        for (final movie in pagePopular) {
          if (!seenMovieIds.contains(movie.id)) {
            allMovies.add(movie);
            seenMovieIds.add(movie.id);
          }
        }
      } catch (e) {
        debugPrint('Error loading popular movies: $e');
      }

      // Strategy 3: Get top-rated movies (sorted by rating)
      // These are critically acclaimed movies users should know
      try {
        final topRated = await _tmdbService.discoverMovies(
          minRating: 7.5, // High rating threshold
          sortBy: 'vote_average.desc', // Sort by rating
          page: 1,
        );
        
        // Add top 15 highest-rated movies
        for (final movie in topRated.take(15)) {
          if (!seenMovieIds.contains(movie.id)) {
            allMovies.add(movie);
            seenMovieIds.add(movie.id);
          }
        }
      } catch (e) {
        debugPrint('Error loading top-rated movies: $e');
      }

      // Strategy 5: Ensure genre diversity with popular AND well-rated movies
      final keyGenres = [
        28,  // Action
        18,  // Drama
        35,  // Comedy
        27,  // Horror
        878, // Science Fiction
        10749, // Romance
        53,  // Thriller
        16,  // Animation
        80,  // Crime
        14,  // Fantasy
      ];

      // Count movies per genre in our current list
      final genreCounts = <int, int>{};
      for (final movie in allMovies) {
        if (movie.genreIds != null) {
          for (final genreId in movie.genreIds!) {
            genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
          }
        }
      }

      // For each key genre, if we have less than 3 movies, add popular AND well-rated ones
      for (final genreId in keyGenres) {
        final currentCount = genreCounts[genreId] ?? 0;
        if (currentCount < 3) {
          try {
            // Get movies from this genre that are both popular and well-rated
            final genreMovies = await _tmdbService.discoverMovies(
              genres: [genreId],
              minRating: 6.5, // Decent rating
              sortBy: 'popularity.desc', // Prioritize popularity
              page: 1,
            );
            
            int added = 0;
            final targetCount = 3 - currentCount;
            for (final movie in genreMovies) {
              if (added >= targetCount) break;
              if (!seenMovieIds.contains(movie.id)) {
                allMovies.add(movie);
                seenMovieIds.add(movie.id);
                // Update genre counts
                if (movie.genreIds != null) {
                  for (final gId in movie.genreIds!) {
                    genreCounts[gId] = (genreCounts[gId] ?? 0) + 1;
                  }
                }
                added++;
              }
            }
          } catch (e) {
            debugPrint('Error loading movies for genre $genreId: $e');
            continue;
          }
        }
      }

      // Sort by a combination of popularity and rating
      // Movies with both high popularity and high rating should come first
      allMovies.sort((a, b) {
        // Calculate a combined score: (rating * 0.6) + (normalized popularity * 0.4)
        // Normalize popularity (typically 0-1000+) to 0-10 scale
        final popularityA = (a.popularity ?? 0.0) / 100.0; // Normalize to 0-10 scale
        final popularityB = (b.popularity ?? 0.0) / 100.0;
        
        final ratingA = a.voteAverage ?? 0.0;
        final ratingB = b.voteAverage ?? 0.0;
        
        // Combined score: 60% rating, 40% popularity
        final scoreA = (ratingA * 0.6) + (popularityA.clamp(0.0, 10.0) * 0.4);
        final scoreB = (ratingB * 0.6) + (popularityB.clamp(0.0, 10.0) * 0.4);
        
        return scoreB.compareTo(scoreA); // Descending order
      });

      // Limit to ~50 movies for optimal starter set
      // These are now sorted by combined popularity + rating score
      final curatedMovies = allMovies.take(50).toList();

      // Shuffle slightly to avoid perfect ordering, but keep mostly sorted
      // This maintains quality while adding some variety
      final shuffledMovies = <Movie>[];
      for (int i = 0; i < curatedMovies.length; i += 5) {
        final chunk = curatedMovies.skip(i).take(5).toList();
        chunk.shuffle();
        shuffledMovies.addAll(chunk);
      }

      // If user is provided, filter out already interacted / watchlist movies so they don't repeat
      List<Movie> finalCurated = shuffledMovies;
      if (user != null) {
        final likedIds = _movieIdsFromUserStrings(user.likedMovies);
        final dislikedIds = _movieIdsFromUserStrings(user.dislikedMovies);
        final skippedIds = _behaviorService.getSkippedMovies(user.id);
        final watchlistIds = _movieIdsFromUserStrings(user.watchlist);
        finalCurated = shuffledMovies.where((movie) =>
          !likedIds.contains(movie.id) &&
          !dislikedIds.contains(movie.id) &&
          !skippedIds.contains(movie.id) &&
          !watchlistIds.contains(movie.id),
        ).toList();
      }

      // When user has selected mood(s) or genre(s), keep only movies that match (mood takes precedence when both are set)
      if (_swipeMoods.isNotEmpty) {
        final moodGenreIds = <int>{};
        for (final mood in _swipeMoods) {
          moodGenreIds.addAll(mood.preferredGenres);
        }
        finalCurated = finalCurated.where((movie) {
          if (movie.genreIds == null || movie.genreIds!.isEmpty) return false;
          return movie.genreIds!.any((id) => moodGenreIds.contains(id));
        }).toList();
      } else if (_swipeSelectedGenres.isNotEmpty) {
        final selectedSet = _swipeSelectedGenres.toSet();
        finalCurated = finalCurated.where((movie) {
          if (movie.genreIds == null || movie.genreIds!.isEmpty) return false;
          return movie.genreIds!.any((id) => selectedSet.contains(id));
        }).toList();
      }

      if (refresh) {
        _movies = finalCurated;
      } else {
        _movies.addAll(finalCurated);
      }
      
      _hasMorePages = finalCurated.isNotEmpty;
      if (user != null) {
        refreshFilters(user);
      } else {
        _applyFilters();
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading curated starter movies: $e');
      // Fallback to regular popular movies if curated load fails
      await loadPopularMovies(refresh: refresh, user: user);
    } finally {
      _isLoading = false;
      _discoverBootstrapComplete = true;
      notifyListeners();
    }
  }

  /// Loads more movies (pagination)
  Future<void> loadMoreMovies({User? user}) async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await loadPopularMovies(user: user);
  }

  /// For testing only: preload genres so the real TMDB API is not called.
  @visibleForTesting
  void setTestGenres(Map<int, String> genres) {
    _genres = Map.from(genres);
    _skipLoadGenresForTest = true;
    notifyListeners();
  }

  bool _integrationTestDeckSeeded = false;

  /// When true, [SwipeScreen] skips its initial TMDB load (e.g. after [replaceSwipeDeckForTest]).
  bool get shouldSkipDiscoverSwipeLoad => _integrationTestDeckSeeded;

  /// Seeds the swipe deck without network calls.
  @visibleForTesting
  void replaceSwipeDeckForTest(List<Movie> movies) {
    _movies = List<Movie>.from(movies);
    _pendingMovies.clear();
    _filteredMovies = List<Movie>.from(_movies);
    _hasMorePages = false;
    _isLoading = false;
    _isPreloading = false;
    _discoverBootstrapComplete = true;
    _error = null;
    _integrationTestDeckSeeded = true;
    notifyListeners();
  }

  /// Loads genres from TMDB API
  Future<void> loadGenres() async {
    if (_skipLoadGenresForTest) return;
    try {
      _genres = await _tmdbService.getGenres();
      // Only notify if we're not in the middle of a build
      if (!_isLoading) {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      // Only notify if we're not in the middle of a build
      if (!_isLoading) {
        notifyListeners();
      }
    }
  }

  /// Searches for movies by query with advanced filtering
  Future<void> searchMovies(String query, {
    int? genreId,
    int? year,
    String sortBy = 'relevance',
    bool showOnlyAvailable = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _searchQuery = query;
      _selectedGenreId = genreId;
      _selectedYear = year;
      // Don't notify listeners here - wait until after the async operation

      if (query.isEmpty) {
        _filteredMovies = _movies;
      } else {
        final searchResults = await _tmdbService.searchMovies(query);
        _filteredMovies = _applyAdvancedFilters(searchResults, genreId, year, sortBy);
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Applies advanced filters to search results
  List<Movie> _applyAdvancedFilters(
    List<Movie> movies,
    int? genreId,
    int? year,
    String sortBy,
  ) {
    var filteredMovies = movies;

    // Filter by genre
    if (genreId != null) {
      filteredMovies = filteredMovies.where((movie) {
        return movie.genreIds != null && movie.genreIds!.contains(genreId);
      }).toList();
    }

    // Filter by year
    if (year != null) {
      filteredMovies = filteredMovies.where((movie) {
        if (movie.year == null) return false;
        final movieYear = int.tryParse(movie.year!);
        return movieYear == year;
      }).toList();
    }

    // Sort results
    switch (sortBy) {
      case 'rating':
        filteredMovies.sort((a, b) {
          final ratingA = a.voteAverage ?? 0.0;
          final ratingB = b.voteAverage ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'year':
        filteredMovies.sort((a, b) {
          final yearA = int.tryParse(a.year ?? '0') ?? 0;
          final yearB = int.tryParse(b.year ?? '0') ?? 0;
          return yearB.compareTo(yearA);
        });
        break;
      case 'title':
        filteredMovies.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'relevance':
      default:
        // Keep original order for relevance
        break;
    }

    return filteredMovies;
  }

  /// Filters movies by genre
  Future<void> filterByGenre(int? genreId) async {
    _selectedGenreId = genreId;
    
    if (genreId == null) {
      _applyFilters();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final genreMovies = await _tmdbService.getMoviesByGenre(genreId);
      _filteredMovies = genreMovies;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filters movies by year
  Future<void> filterByYear(int? year) async {
    _selectedYear = year;
    
    if (year == null) {
      _applyFilters();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final yearMovies = await _tmdbService.getMoviesByYear(year);
      _filteredMovies = yearMovies;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears all filters
  void clearFilters() {
    _selectedGenreId = null;
    _selectedYear = null;
    _searchQuery = '';
    _filteredMovies = _movies;
    notifyListeners();
  }

  /// Applies current filters to the movie list
  void _applyFilters() {
    _filteredMovies = _movies.where((movie) {
      // Filter by genre
      if (_selectedGenreId != null) {
        if (movie.genreIds == null || !movie.genreIds!.contains(_selectedGenreId)) {
          return false;
        }
      }
      
      // Filter by year
      if (_selectedYear != null) {
        final movieYear = movie.year;
        if (movieYear == null || int.tryParse(movieYear) != _selectedYear) {
          return false;
        }
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (movie.overview?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }
      
      return true;
    }).toList();
    
    // Only notify if we're not in the middle of a build
    if (!_isLoading) {
      notifyListeners();
    }
  }

  /// Gets movie details by ID
  Future<Movie?> getMovieDetails(int movieId) async {
    try {
      return await _tmdbService.getMovieDetails(movieId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Loads trending movies
  Future<void> loadTrendingMovies() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final trendingMovies = await _tmdbService.getTrendingMovies();
      _movies = trendingMovies;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the current mood for mood-based recommendations
  void setCurrentMood(Mood mood) {
    _currentMood = mood;
    notifyListeners();
  }

  /// Gets mood-based movie recommendations
  Future<void> getMoodBasedRecommendations() async {
    if (_currentMood == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final recommendations = await _tmdbService.getMoodBasedRecommendations(_currentMood!);
      _filteredMovies = recommendations;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles movie like status
  void toggleMovieLike(Movie movie) {
    // Implementation for liking/disliking movies
    notifyListeners();
  }

  /// Gets similar movies for a given movie
  Future<List<Movie>> getSimilarMovies(int movieId) async {
    try {
      return await _tmdbService.getSimilarMovies(movieId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets movie recommendations based on a movie
  Future<List<Movie>> getMovieRecommendations(int movieId) async {
    try {
      return await _tmdbService.getMovieRecommendations(movieId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Refreshes all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Clears the current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Resolves user preferences selectedPlatforms (names or ids) to platform ids for discovery.
  List<String> _platformIdsFromUserPreferences(User user) {
    final raw = user.preferences['selectedPlatforms'];
    if (raw == null || raw is! List) return [];
    final ids = <String>[];
    for (final item in raw) {
      final s = item?.toString().trim();
      if (s == null || s.isEmpty) continue;
      if (StreamingPlatform.getById(s) != null) {
        ids.add(s);
      } else {
        final byName = StreamingPlatform.availablePlatforms
            .where((p) => p.name.toLowerCase() == s.toLowerCase())
            .map((p) => p.id);
        ids.addAll(byName);
      }
    }
    return ids.toSet().toList();
  }

  /// Resolves user preferences selectedGenres to integer TMDB genre ids.
  List<int> _genreIdsFromUserPreferences(User user) {
    final raw = user.preferences['selectedGenres'];
    if (raw == null || raw is! List) return [];
    return raw
        .map((g) => g is int ? g : int.tryParse(g.toString()))
        .whereType<int>()
        .toSet()
        .toList();
  }

  @visibleForTesting
  List<String> platformIdsFromUserPreferencesForTest(User user) =>
      _platformIdsFromUserPreferences(user);

  @visibleForTesting
  List<int> genreIdsFromUserPreferencesForTest(User user) =>
      _genreIdsFromUserPreferences(user);

  /// Gets genre name by ID
  String? getGenreName(int genreId) {
    return _genres[genreId];
  }

  /// Gets all available years from current movies
  List<int> getAvailableYears() {
    final years = <int>{};
    for (final movie in _movies) {
      if (movie.year != null) {
        years.add(int.parse(movie.year!));
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Loads movies based on mood
  Future<void> loadMoviesByMood(dynamic mood) async {
    try {
      _isLoading = true;
      _error = null;
      _currentMood = mood;
      notifyListeners();

      // Load movies for each preferred genre of the mood
      List<Movie> moodMovies = [];
      for (final genreId in mood.preferredGenres) {
        try {
          final genreMovies = await _tmdbService.getMoviesByGenre(genreId);
          moodMovies.addAll(genreMovies);
        } catch (e) {
          debugPrint('Failed to load movies for genre $genreId: $e');
        }
      }

      // Remove duplicates and shuffle for variety
      final uniqueMovies = <Movie>{};
      uniqueMovies.addAll(moodMovies);
      _movies = uniqueMovies.toList()..shuffle();
      
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call after each swipe; every 5 swipes triggers a background refresh
  /// using the same hybrid personalized strategy as the main movie feed.
  void recordSwipeForRecalc(User? user) {
    if (user == null) return;
    _swipeCountSinceRecalc++;
    if (_swipeCountSinceRecalc >= 5) {
      _swipeCountSinceRecalc = 0;
      Future.microtask(() async {
        await loadPersonalizedRecommendations(
          user,
          refresh: false,
          insertAtFront: false,
          backgroundLoad: true,
        );
      });
    }
  }

  /// Loads personalized movie recommendations based on user preferences
  Future<void> loadPersonalizedRecommendations(User user, {bool refresh = false, bool insertAtFront = false, bool backgroundLoad = false}) async {
    final swTotal = Stopwatch();
    try {
      // Only set loading state if not loading in background (to avoid UI disruption)
      if (!backgroundLoad) {
        _isLoading = true;
        notifyListeners();
      }
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _movies.clear();
        _pendingMovies.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      }

      // NEW: A/B Testing - Get user's algorithm variant
      swTotal.start();
      final swVariantAndPrefs = Stopwatch()..start();
      final variant = await _abTestingService.getUserVariant(user.id);
      debugPrint('A/B Test: User ${user.id} assigned to variant: $variant');
      
      final preferences = await _prefsCache.getOrCompute(
        user,
        forceRefresh: refresh,
      );
      swVariantAndPrefs.stop();
      _logPerf('variant+analyzePreferences', swVariantAndPrefs);
      
      final allRecommendations = <Movie>[];
      final seenMovieIds = <int>{};
      
      // Track already shown movies to avoid duplicates
      final currentMovieIds = _movies.map((m) => m.id).toSet();
      void addCandidates(Iterable<Movie> movies, {required String strategy}) {
        for (final movie in movies) {
          if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
            allRecommendations.add(movie.copyWith(recommendationStrategy: strategy));
            seenMovieIds.add(movie.id);
          }
        }
      }
      
      // NEW: For embedding_focused variant, ensure MF service is loaded
      if (variant == ABTestingService.variantC) {
        // Load MF service data first (if not already loaded)
        await _mfService.loadFromStorage();
        // Note: MF recommendations will be integrated during scoring
      }

      final preferredGenresFromProfile = _genreIdsFromUserPreferences(user);
      final effectivePlatformIds = _swipeSelectedPlatforms.isNotEmpty
          ? _swipeSelectedPlatforms
          : _platformIdsFromUserPreferences(user);

      // Strategy 2: Discover movies based on user preferences
      // Priority: swipe genres > explicit profile selected genres > inferred top genres.
      final genresToUse = _swipeSelectedGenres.isNotEmpty
          ? _swipeSelectedGenres
          : (preferredGenresFromProfile.isNotEmpty
              ? preferredGenresFromProfile.take(3).toList()
              : preferences.topGenres.take(3).toList());
      
      // If mood filters are set, combine genres from all selected moods
      List<int> finalGenres;
      if (_swipeMoods.isNotEmpty) {
        // Combine genres from all selected moods
        final moodGenres = <int>{};
        for (final mood in _swipeMoods) {
          moodGenres.addAll(mood.preferredGenres);
        }
        finalGenres = moodGenres.toList();
      } else {
        finalGenres = genresToUse.isNotEmpty ? genresToUse : preferences.topGenres.take(3).toList();
      }
      // Strategy 1/2/3 in parallel to reduce first-batch latency.
      final currentYear = DateTime.now().year;
      final minYear = currentYear - 15;
      final swParallelPrimary = Stopwatch()..start();
      final primaryResults = await Future.wait([
        () async {
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.getTrendingMovies(page: _currentPage);
            sw.stop();
            _logPerf('strategy.trending', sw);
            return data;
          } catch (e) {
            debugPrint('Error loading trending movies: $e');
            return <Movie>[];
          }
        }(),
        () async {
          if (finalGenres.isEmpty) return <Movie>[];
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.discoverMovies(
              genres: finalGenres,
              minYear: minYear,
              minRating: preferences.preferredMinRating,
              maxRating: preferences.preferredMaxRating,
              page: _currentPage,
            );
            sw.stop();
            _logPerf('strategy.discoverMovies', sw);
            return data;
          } catch (e) {
            debugPrint('Error discovering movies: $e');
            return <Movie>[];
          }
        }(),
        () async {
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.getTopRatedMovies(page: _currentPage);
            sw.stop();
            _logPerf('strategy.topRatedMovies', sw);
            return data;
          } catch (e) {
            debugPrint('Error loading top-rated movies: $e');
            return <Movie>[];
          }
        }(),
      ]);
      swParallelPrimary.stop();
      _logPerf('strategy.primaryParallelBatch', swParallelPrimary);
      addCandidates(primaryResults[0], strategy: 'contentBased');
      addCandidates(primaryResults[1], strategy: 'contentBased');
      addCandidates(primaryResults[2], strategy: 'contentBased');

      // Strategy 2b: Advanced discovery with TF-style genre vectors + cosine similarity (24h cache, mood mapping)
      if (!backgroundLoad) {
        try {
        final moodId = _swipeMoods.isNotEmpty ? _swipeMoods.first.id : user.currentMood;
        final discoveryPrefs = UserDiscoveryPrefs(
          likedGenres: preferences.topGenres,
          dislikedGenres: const [],
          streamingServices: effectivePlatformIds,
          mood: moodId,
          releaseYear: null,
        );
        final swContentSimilarity = Stopwatch()..start();
        final discoveryMovies = await MovieDiscoveryService.instance.getDiscoverMoviesBySimilarity(
          userId: user.id,
          userPrefs: discoveryPrefs,
          limit: 30,
        );
        swContentSimilarity.stop();
        _logPerf('strategy.contentSimilarityDiscovery', swContentSimilarity);
        for (final movie in discoveryMovies) {
          if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
            allRecommendations.add(movie.copyWith(recommendationStrategy: 'contentBased'));
            seenMovieIds.add(movie.id);
          }
        }
        if (discoveryMovies.isNotEmpty) {
          debugPrint('MovieProvider: Added ${discoveryMovies.length} movies from content-similarity discovery');
        }
        } catch (e) {
          debugPrint('Error in content-similarity discovery: $e');
        }
      }

      // Strategy 4: Get recommendations based on liked movies (embedding/similar) (increased from 3 to 8)
      if (user.likedMovies.isNotEmpty) {
        final swEmbeddingBlock = Stopwatch()..start();
        // Get recommendations from top 8 liked movies (prioritize most recent)
        final likedMoviesToAnalyze = user.likedMovies.reversed.take(8).toList();
        for (final movieIdStr in likedMoviesToAnalyze) {
          try {
            final movieId = int.tryParse(movieIdStr);
            if (movieId == null) continue;

            final cachedSimilar = _movieSimilarSessionCache[movieId];
            final cachedRecommendations =
                _movieRecommendationsSessionCache[movieId];

            List<Movie> similarMovies;
            List<Movie> recommendedMovies;

            if (cachedSimilar != null && cachedRecommendations != null) {
              similarMovies = cachedSimilar;
              recommendedMovies = cachedRecommendations;
            } else {
              // Start both requests concurrently; await typed results.
              final similarFuture = cachedSimilar != null
                  ? Future.value(cachedSimilar)
                  : _tmdbService.getSimilarMovies(movieId);
              final recommendationsFuture = cachedRecommendations != null
                  ? Future.value(cachedRecommendations)
                  : _tmdbService.getMovieRecommendations(movieId);

              similarMovies = await similarFuture;
              recommendedMovies = await recommendationsFuture;

              // Cache both (including empty lists) to prevent repeated calls
              _movieSimilarSessionCache[movieId] = similarMovies;
              _movieRecommendationsSessionCache[movieId] = recommendedMovies;
            }
            
            // Combine similar and recommended movies
            final combinedMovies = <Movie>[];
            combinedMovies.addAll(similarMovies);
            combinedMovies.addAll(recommendedMovies);
            
            for (final movie in combinedMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie.copyWith(recommendationStrategy: 'embedding'));
                seenMovieIds.add(movie.id);
              }
            }
          } catch (e) {
            // Continue with next movie
            continue;
          }
        }
        swEmbeddingBlock.stop();
        _logPerf('strategy.embeddingBasedFromLikedMovies', swEmbeddingBlock);
      }

      // Strategy 5: Get movies by preferred actors and directors
      if (!backgroundLoad && allRecommendations.length < 30) {
        // Get movies from top 5 preferred actors
        for (final actorName in preferences.preferredActors.take(5)) {
          try {
            final actorMovies = await _tmdbService.searchMoviesByActor(actorName, page: _currentPage);
            for (final movie in actorMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie.copyWith(recommendationStrategy: 'contentBased'));
                seenMovieIds.add(movie.id);
              }
              // Limit to avoid too many movies from one actor
              if (seenMovieIds.length >= 50) break;
            }
          } catch (e) {
            continue;
          }
        }
        
        // Get movies from top 3 preferred directors
        for (final directorName in preferences.preferredDirectors.take(3)) {
          try {
            final directorMovies = await _tmdbService.searchMoviesByActor(directorName, page: _currentPage);
            for (final movie in directorMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie.copyWith(recommendationStrategy: 'contentBased'));
                seenMovieIds.add(movie.id);
              }
              // Limit to avoid too many movies from one director
              if (seenMovieIds.length >= 50) break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Strategy 4: Get movies from preferred genres (if not enough recommendations)
      // Use swipe genre filters if set, otherwise use user preferences
      final genresForStrategy4 = _swipeSelectedGenres.isNotEmpty
          ? _swipeSelectedGenres.take(2).toList()
          : (preferences.topGenres.isNotEmpty ? preferences.topGenres.take(2).toList() : []);
      
      if (allRecommendations.length < 20 && genresForStrategy4.isNotEmpty) {
        final currentYear = DateTime.now().year;
        for (final genreId in genresForStrategy4) {
          try {
            // Use discoverMovies with minYear to prefer recent movies
            final genreMovies = await _tmdbService.discoverMovies(
              genres: [genreId],
              minYear: currentYear - 15, // Prefer movies from last 15 years
              sortBy: 'popularity.desc',
              page: _currentPage,
            );
            for (final movie in genreMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie.copyWith(recommendationStrategy: 'contentBased'));
                seenMovieIds.add(movie.id);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Fallback: If still not enough, add popular movies
      if (allRecommendations.length < 10) {
        try {
          final popularMovies = await _tmdbService.getPopularMovies(page: _currentPage);
          for (final movie in popularMovies) {
            if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
              allRecommendations.add(movie.copyWith(recommendationStrategy: 'contentBased'));
              seenMovieIds.add(movie.id);
            }
          }
        } catch (e) {
          debugPrint('Error loading popular movies as fallback: $e');
        }
      }

      // Single-pass candidate filter (interactions + mood/genre/profile + quality).
      final dislikedIds = _movieIdsFromUserStrings(user.dislikedMovies);
      final likedIds = _movieIdsFromUserStrings(user.likedMovies);
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      final watchlistIds = _movieIdsFromUserStrings(user.watchlist);
      Set<int>? requiredGenreIds;
      if (_swipeMoods.isNotEmpty) {
        requiredGenreIds = <int>{};
        for (final mood in _swipeMoods) {
          requiredGenreIds.addAll(mood.preferredGenres);
        }
      } else if (_swipeSelectedGenres.isNotEmpty) {
        requiredGenreIds = _swipeSelectedGenres.toSet();
      } else if (preferredGenresFromProfile.isNotEmpty) {
        requiredGenreIds = preferredGenresFromProfile.toSet();
      }

      final filteredRecommendations = <Movie>[];
      for (final movie in allRecommendations) {
        if (dislikedIds.contains(movie.id) ||
            likedIds.contains(movie.id) ||
            skippedIds.contains(movie.id) ||
            watchlistIds.contains(movie.id)) {
          continue;
        }
        if (requiredGenreIds != null) {
          final genres = movie.genreIds;
          if (genres == null ||
              genres.isEmpty ||
              !genres.any((id) => requiredGenreIds!.contains(id))) {
            continue;
          }
        }
        if (movie.voteAverage != null &&
            movie.voteAverage! < 5.0 &&
            (movie.voteCount == null || movie.voteCount! < 100)) {
          continue;
        }
        if (movie.voteCount != null && movie.voteCount! < 10) {
          final movieYear = movie.year != null ? int.tryParse(movie.year!) : null;
          if (movieYear == null || DateTime.now().year - movieYear > 1) {
            continue;
          }
        }
        filteredRecommendations.add(movie);
      }
      allRecommendations
        ..clear()
        ..addAll(filteredRecommendations);

      // Filter by selected platforms if any are selected
      if (_swipeSelectedPlatforms.isNotEmpty) {
        // Note: Platform filtering requires checking streaming availability
        // This is done asynchronously, so we'll filter after scoring
        // For now, we'll apply platform filter after getting recommendations
      }

      // Score and rank movies by relevance
      final scoredMovies = await _scoreMovies(
        allRecommendations,
        preferences,
        user,
      );

      // Apply platform filter if platforms are selected
      List<Movie> platformFilteredMovies = scoredMovies;
      if (effectivePlatformIds.isNotEmpty) {
        final streamingService = StreamingService.instance;
        platformFilteredMovies = await streamingService.getMoviesOnMultiplePlatforms(
          scoredMovies,
          effectivePlatformIds,
        );
      }

      // Apply diversity filter to avoid clustering
      final diverseMovies = _applyDiversityFilter(platformFilteredMovies);
      
      // ENSURE: Always return at least some movies, even if diversity filter is aggressive
      // If diversity filter removed everything, use the scored movies instead
      final finalMovies = diverseMovies.isNotEmpty 
          ? diverseMovies 
          : (platformFilteredMovies.isNotEmpty 
              ? platformFilteredMovies.take(20).toList() 
              : scoredMovies.take(20).toList());

      // Never append IDs already in the deck or pending queue (fixes “seen again” + wasted work)
      final mergedExistingIds = <int>{
        ..._movies.map((m) => m.id),
        ..._pendingMovies.map((m) => m.id),
      };
      final uniqueNewMovies =
          finalMovies.where((m) => !mergedExistingIds.contains(m.id)).toList();

      var appendedToVisibleDeck = false;
      if (refresh) {
        _movies = uniqueNewMovies;
      } else if (insertAtFront && !backgroundLoad) {
        // Insert new recommendations at the front so they appear next
        // Only do this if not loading in background (to avoid disrupting current view)
        _movies.insertAll(0, uniqueNewMovies);
      } else {
        if (backgroundLoad &&
            _filteredMovies.length >= _minLengthToDeferBackgroundAdds) {
          final existingIds = _movies.map((m) => m.id).toSet()
            ..addAll(_pendingMovies.map((m) => m.id));
          _pendingMovies.addAll(
            uniqueNewMovies.where((movie) => !existingIds.contains(movie.id)),
          );
        } else {
          // For foreground loads (or when stack is critically low), add to end.
          _movies.addAll(uniqueNewMovies);
          appendedToVisibleDeck = true;
        }
      }

      // Advance TMDB page after each successful fetch so the next preload isn’t “page 1” again.
      if (_currentPage < _maxTmdbPages) {
        _currentPage++;
      }

      // Keep trying while we’re under the page cap; “no new unique rows” is OK for one round.
      _hasMorePages = _currentPage < _maxTmdbPages &&
          (uniqueNewMovies.isNotEmpty || allRecommendations.length >= 8);
      if (!backgroundLoad) {
        refreshFilters(user);
      } else {
        // Keep active swipe deck stable during background preloads.
        // Only sanitize pending and append to filtered tail when we had to add directly.
        _removeInteractedFromPending(user);
        if (appendedToVisibleDeck && uniqueNewMovies.isNotEmpty) {
          final filteredIds = _filteredMovies.map((m) => m.id).toSet();
          _filteredMovies.addAll(
            uniqueNewMovies.where((m) => !filteredIds.contains(m.id)),
          );
        }
      }
      swTotal.stop();
      _logPerf('loadPersonalizedRecommendations total', swTotal);

      // INFINITE SWIPE: After adding movies, check if we need to preload more
      if (backgroundLoad) {
        _isPreloading = false;
        _lastPreloadTime = DateTime.now();
      }
      
      // Only notify listeners if not loading in background (to avoid UI disruption)
      // For background loads, we'll notify once at the end
      if (!backgroundLoad) {
        notifyListeners();
      } else {
        // For background loads, notify once at the end to update the list
        // This happens after movies are added, so current card won't disappear
        _flushPendingMoviesIfLow();
        notifyListeners();
      }
      
      // INFINITE SWIPE: Trigger additional preload if buffer is still low
      if (backgroundLoad && _filteredMovies.length < _minBufferSize && _hasMorePages) {
        _ensureBufferFilled(user);
      }
    } catch (e) {
      swTotal.stop();
      _logPerf('loadPersonalizedRecommendations total (error)', swTotal);
      _error = e.toString();
      _isPreloading = false;
      // Fallback to popular movies on error
      if (_movies.isEmpty) {
        await loadPopularMovies(refresh: true, user: user);
      }
    } finally {
      _discoverBootstrapComplete = true;
      if (!backgroundLoad) {
        _isLoading = false;
        notifyListeners();
      } else {
        // For background loads, notify once at the end to update the list
        // This happens after movies are added, so current card won't disappear
        _flushPendingMoviesIfLow();
        notifyListeners();
      }
    }
  }
  
  /// INFINITE SWIPE: Ensures buffer is filled with enough movies for seamless swiping
  /// This method continuously preloads content in the background
  Future<void> _ensureBufferFilled(
    User? user, {
    bool allowAppendWhileDeckLarge = false,
  }) async {
    // Rate limit: avoid hammering TMDB while still refilling faster than before
    if (_lastPreloadTime != null) {
      final timeSinceLastPreload = DateTime.now().difference(_lastPreloadTime!);
      if (timeSinceLastPreload.inMilliseconds < 850) {
        return;
      }
    }
    
    // Don't preload if already loading or preloading
    if (_isLoading || _isPreloading || !_hasMorePages) {
      return;
    }
    
    // List length stays high while the swiper index advances; allow fetch anyway when
    // [allowAppendWhileDeckLarge] is true (driven by estimated remaining cards).
    if (!allowAppendWhileDeckLarge && _filteredMovies.length >= _minBufferSize) {
      return; // Buffer is full enough
    }
    
    _isPreloading = true;

    try {
      if (user != null) {
        final analyzer = UserPreferenceAnalyzer();
        if (analyzer.hasEnoughData(user)) {
          // Load personalized recommendations in background
          await loadPersonalizedRecommendations(
            user,
            refresh: false,
            insertAtFront: false,
            backgroundLoad: true,
          );
        } else {
          await loadMoreMovies(user: user);
        }
      } else {
        await loadMoreMovies(user: null);
      }
    } catch (e) {
      debugPrint('Error preloading movies for buffer: $e');
    } finally {
      _isPreloading = false;
      _lastPreloadTime = DateTime.now();
      _flushPendingMoviesIfLow();
    }
  }
  
  /// INFINITE SWIPE: Public method to check and preload if needed
  /// Called from swipe screen to maintain buffer.
  ///
  /// [estimatedRemaining] is `filteredMovies.length - swiperCurrentIndex` from the
  /// CardSwiper callback. The deck’s list length does not shrink as the user swipes,
  /// so without this we never preload until the list is nearly empty.
  Future<void> checkAndPreload(User? user, {int? estimatedRemaining}) async {
    _flushPendingMoviesIfLow();
    // Start the next TMDB fetch slightly *before* we hit the hard preload
    // cutoff, so the user doesn't encounter an empty stack.
    const int targetRemaining = _preloadThreshold + 5;
    final lowRemaining = estimatedRemaining != null &&
        estimatedRemaining <= targetRemaining &&
        estimatedRemaining >= 0;
    if (needsPreload || lowRemaining) {
      await _ensureBufferFilled(
        user,
        allowAppendWhileDeckLarge: lowRemaining,
      );
    }
  }

  /// Drops all cards so the Discover tab can show the real empty state (the swiper
  /// keeps a null index after the last swipe while the backing list is still full).
  void clearSwipeFeedStack() {
    _movies.clear();
    _pendingMovies.clear();
    _applyFilters();
    notifyListeners();
  }

  /// Called when the user swipes past the last card ([CardSwiper.onEnd]).
  /// Clears the stale list and fetches the next page so the swiper can restart.
  Future<void> refillSwipeDeckAfterEnd(User? user) async {
    _isLoading = true;
    _error = null;
    _movies.clear();
    _pendingMovies.clear();
    notifyListeners();
    try {
      if (user == null) {
        await loadCuratedStarterMovies(refresh: false, user: null);
      } else {
        final analyzer = UserPreferenceAnalyzer();
        if (analyzer.hasEnoughData(user)) {
          await loadPersonalizedRecommendations(user, refresh: false);
        } else {
          await loadCuratedStarterMovies(refresh: false, user: user);
        }
      }
    } catch (e, st) {
      debugPrint('MovieProvider.refillSwipeDeckAfterEnd: $e\n$st');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Flush deferred background movies into the visible feed when stack is low.
  void _flushPendingMoviesIfLow() {
    if (_pendingMovies.isEmpty) return;
    if (_filteredMovies.length > _flushPendingWhenVisibleAtMost) return;

    final existingIds = _movies.map((m) => m.id).toSet();
    final toAppend =
        _pendingMovies.where((movie) => !existingIds.contains(movie.id)).toList();
    _pendingMovies.clear();
    if (toAppend.isEmpty) return;

    _movies.addAll(toAppend);
    _applyFilters();
  }

  void _removeInteractedFromPending(User user) {
    final likedIds = _movieIdsFromUserStrings(user.likedMovies);
    final dislikedIds = _movieIdsFromUserStrings(user.dislikedMovies);
    final skippedIds = _behaviorService.getSkippedMovies(user.id);
    final watchlistIds = _movieIdsFromUserStrings(user.watchlist);

    _pendingMovies.removeWhere(
      (movie) =>
          likedIds.contains(movie.id) ||
          dislikedIds.contains(movie.id) ||
          skippedIds.contains(movie.id) ||
          watchlistIds.contains(movie.id),
    );
  }

  /// ENHANCED: Fetches external ratings (IMDb, Rotten Tomatoes) for movies
  /// This is done in background to enhance movie quality scores
  // ignore: unused_element
  Future<void> _enhanceMoviesWithExternalRatings(List<Movie> movies) async {
    // Load OMDb API key if not already loaded
    await _omdbService.loadApiKey();
    
    // Process movies in batches to avoid overwhelming the API
    for (final movie in movies) {
      // Skip if we already have external ratings
      if (movie.imdbRating != null || movie.rottenTomatoesTomatometer != null) {
        continue;
      }
      
      // Skip if no IMDb ID available (we need it to fetch from OMDb)
      if (movie.imdbId == null || movie.imdbId!.isEmpty) {
        // Try to fetch IMDb ID from TMDB
        try {
          final externalIds = await _tmdbService.getMovieExternalIds(movie.id);
          final imdbId = externalIds['imdb_id'];
          if (imdbId == null || imdbId.isEmpty) {
            continue; // No IMDb ID available
          }
          
          // Update movie with IMDb ID
          final movieIndex = _movies.indexWhere((m) => m.id == movie.id);
          if (movieIndex >= 0) {
            _movies[movieIndex] = movie.copyWith(imdbId: imdbId);
          }
          
          // Fetch ratings from OMDb
          final ratings = await _omdbService.getRatingsByImdbId(imdbId);
          if (ratings != null) {
            // Update movie with external ratings
            if (movieIndex >= 0) {
              _movies[movieIndex] = _movies[movieIndex].copyWith(
                imdbRating: ratings.imdbRating,
                imdbVotes: ratings.imdbVotes,
                rottenTomatoesTomatometer: ratings.rottenTomatoesTomatometer,
                rottenTomatoesAudienceScore: ratings.rottenTomatoesAudienceScore,
              );
            }
          }
        } catch (e) {
          // Silently fail - external ratings are optional
          debugPrint('Error fetching external ratings for movie ${movie.id}: $e');
        }
      } else {
        // We have IMDb ID, fetch ratings directly
        try {
          final ratings = await _omdbService.getRatingsByImdbId(movie.imdbId!);
          if (ratings != null) {
            final movieIndex = _movies.indexWhere((m) => m.id == movie.id);
            if (movieIndex >= 0) {
              _movies[movieIndex] = _movies[movieIndex].copyWith(
                imdbRating: ratings.imdbRating,
                imdbVotes: ratings.imdbVotes,
                rottenTomatoesTomatometer: ratings.rottenTomatoesTomatometer,
                rottenTomatoesAudienceScore: ratings.rottenTomatoesAudienceScore,
              );
            }
          }
        } catch (e) {
          // Silently fail - external ratings are optional
          debugPrint('Error fetching external ratings for movie ${movie.id}: $e');
        }
      }
      
      // Rate limit: small delay between requests to avoid overwhelming OMDb API
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Notify listeners after updating ratings
    notifyListeners();
  }

  /// Loads more personalized recommendations (pagination)
  Future<void> loadMorePersonalizedRecommendations(User user) async {
    if (_isLoading || !_hasMorePages) return;
    await loadPersonalizedRecommendations(user);
  }

  /// Scores movies based on relevance to user preferences
  Future<List<Movie>> _scoreMovies(
    List<Movie> movies,
    UserPreferences preferences,
    User user,
  ) async {
    final swScoreTotal = Stopwatch()..start();
    final scoredMovies = <_ScoredMovie>[];
    
    // Cache for credits to avoid repeated API calls
    final creditsCache = <int, Map<String, dynamic>>{};
    
    // Fetch credits in parallel for top movies (reduced limit for better performance)
    // Only fetch for top 20 movies instead of 50 to reduce API calls and improve speed.
    // Use a session cache so repeated preloads don't re-fetch credits for the same IDs.
    final moviesToVerify = movies.take(20).toList();
    final creditFutures = <Future<void>>[];
    for (final movie in moviesToVerify) {
      final cachedCredits = _movieCreditsSessionCache[movie.id];
      if (cachedCredits != null) {
        creditsCache[movie.id] = cachedCredits;
      } else {
        creditFutures.add(() async {
          try {
            final credits = await _tmdbService.getMovieCredits(movie.id);
            _movieCreditsSessionCache[movie.id] = credits;
            creditsCache[movie.id] = credits;
          } catch (e) {
            // Skip if fetch fails
          }
        }());
      }
    }
    
    // Wait for all credit fetches (with shorter timeout for better responsiveness)
    try {
      final swCreditsFetch = Stopwatch()..start();
      await Future.wait(creditFutures, eagerError: false).timeout(
        const Duration(seconds: 3), // Reduced from 5 to 3 seconds
      );
      swCreditsFetch.stop();
      _logPerf('creditsFetch(20)', swCreditsFetch);
    } catch (e) {
      debugPrint('Credit fetch timeout - continuing with partial data');
    }
    
    // Get user's liked movies for collaborative filtering and embeddings
    // Use cache service to avoid redundant API calls
    final userLikedMovieIds = _movieIdsFromUserStrings(user.likedMovies);
    final likedMovies = <Movie>[];
    final cacheService = MovieCacheService.instance;
    
    // Try cache first, then API if not cached
    final swLikedMoviesEnrich = Stopwatch()..start();
    for (final movieId in userLikedMovieIds.take(10)) {
      try {
        // Check cache first for instant access
        final cachedMovie = cacheService.getCachedMovie(movieId);
        if (cachedMovie != null) {
          likedMovies.add(cachedMovie);
        } else {
          // Load from API and cache it
          final movie = await cacheService.getMovieDetails(movieId);
          likedMovies.add(movie);
        }
      } catch (e) {
        continue;
      }
    }
    swLikedMoviesEnrich.stop();
    _logPerf('likedMoviesEnrich(10)', swLikedMoviesEnrich);

    // Get current context for contextual recommendations
    final currentTime = DateTime.now();
    final currentMoods = _swipeMoods;
    
    // NEW: Get A/B test variant once (before loop for performance)
    final variant = await _abTestingService.getUserVariant(user.id);
    double mfWeightMultiplier = 0.15; // Default weight
    if (variant == ABTestingService.variantC) {
      mfWeightMultiplier = 0.25; // embedding_focused: Higher MF weight
    } else if (variant == ABTestingService.variantB) {
      mfWeightMultiplier = 0.20; // enhanced: Moderate MF weight
    }

    final swScoringLoop = Stopwatch()..start();
    for (final movie in movies) {
      double score = 0.0;
      
      // ENHANCED: Base scoring with advanced feature engineering
      // Each component contributes independently, then we normalize
      double genreScore = 0.0;
      double actorScore = 0.0;
      double directorScore = 0.0;
      double ratingScore = 0.0;
      double recencyScore = 0.0;
      double qualityScore = 0.0;
      double temporalScore = 0.0; // NEW: Temporal features
      double crossFeatureScore = 0.0; // NEW: Cross-feature interactions
      
      // Genre match scoring (normalized 0-1, then weighted 30%)
      if (movie.genreIds != null && preferences.topGenres.isNotEmpty) {
        final matchingGenres = movie.genreIds!
            .where((id) => preferences.topGenres.contains(id))
            .length;
        genreScore = (matchingGenres / preferences.topGenres.length).clamp(0.0, 1.0);
      }
      
      // Actor match scoring (normalized 0-1, then weighted 20%) - verify actors actually appear
      if (preferences.preferredActors.isNotEmpty && creditsCache.containsKey(movie.id)) {
        try {
          final credits = creditsCache[movie.id]!;
          final cast = credits['cast'] as List;
          final castNames = cast.take(10).map((c) => c['name'] as String? ?? '').toSet();
          
          final matchingActors = preferences.preferredActors
              .where((actor) => castNames.contains(actor))
              .length;
          if (matchingActors > 0) {
            actorScore = (matchingActors / preferences.preferredActors.length).clamp(0.0, 1.0);
          }
        } catch (e) {
          // Skip actor scoring if error
        }
      }
      
      // Director match scoring (normalized 0-1, then weighted 15%) - verify directors actually appear
      if (preferences.preferredDirectors.isNotEmpty && creditsCache.containsKey(movie.id)) {
        try {
          final credits = creditsCache[movie.id]!;
          final crew = credits['crew'] as List;
          final directors = crew
              .where((p) => p['job'] == 'Director')
              .map((p) => p['name'] as String? ?? '')
              .toSet();
          
          final matchingDirectors = preferences.preferredDirectors
              .where((director) => directors.contains(director))
              .length;
          if (matchingDirectors > 0) {
            directorScore = (matchingDirectors / preferences.preferredDirectors.length).clamp(0.0, 1.0);
          }
        } catch (e) {
          // Skip director scoring if error
        }
      }
      
      // IMPROVED: Rating match scoring (normalized 0-1, then weighted 15%)
      if (movie.voteAverage != null) {
        if (preferences.preferredMinRating != null && preferences.preferredMaxRating != null) {
          final rating = movie.voteAverage!;
          final range = preferences.preferredMaxRating! - preferences.preferredMinRating!;
          if (range > 0) {
            if (rating >= preferences.preferredMinRating! && rating <= preferences.preferredMaxRating!) {
              ratingScore = 1.0; // Perfect match
            } else {
              // Partial credit for close ratings (smooth falloff)
              final distance = rating < preferences.preferredMinRating!
                  ? preferences.preferredMinRating! - rating
                  : rating - preferences.preferredMaxRating!;
              ratingScore = (1.0 - (distance / range).clamp(0.0, 1.0)).clamp(0.0, 1.0);
            }
          }
        } else {
          // If no rating preference, reward higher ratings
          ratingScore = ((movie.voteAverage! - 5.0) / 5.0).clamp(0.0, 1.0);
        }
      }
      
      // ENHANCED: Recency scoring (normalized 0-1, then weighted 5%)
      // Prioritizes latest releases and trending content
      if (movie.year != null) {
        final movieYear = int.tryParse(movie.year!);
        if (movieYear != null) {
          final currentYear = DateTime.now().year;
          final yearsAgo = currentYear - movieYear;
          
          // ENHANCED: Much stronger boost for very recent releases (last 2 years)
          if (yearsAgo == 0) {
            recencyScore = 1.0; // Current year releases get maximum boost
          } else if (yearsAgo == 1) {
            recencyScore = 0.95; // Last year - almost maximum
          } else if (yearsAgo == 2) {
            recencyScore = 0.85; // Two years ago - still very high
          } else if (yearsAgo <= 5) {
            recencyScore = 0.7; // 3-5 years - good recency
          } else if (yearsAgo <= 10) {
            recencyScore = 0.5; // 6-10 years - moderate
          } else if (yearsAgo <= 15) {
            recencyScore = 0.3; // 11-15 years - lower
          } else {
            recencyScore = 0.1; // Older movies - minimal boost
          }
        }
      }
      
      // ENHANCED: Additional boost for movies with high popularity (trending indicator)
      // Popularity score from TMDB indicates what's currently trending
      if (movie.popularity != null && movie.popularity! > 0) {
        // Normalize popularity (typically 0-1000+) and add to recency score
        // This gives extra boost to trending movies regardless of release year
        final normalizedPopularity = (movie.popularity! / 100.0).clamp(0.0, 1.0);
        recencyScore = (recencyScore * 0.7) + (normalizedPopularity * 0.3); // 70% recency, 30% trending
        recencyScore = recencyScore.clamp(0.0, 1.0);
      }
      
      // ENHANCED: Quality score (normalized 0-1, then weighted 15%)
      // Rewards movies with good ratings (TMDB scores), high vote counts (credibility), and popularity
      // Note: TMDB voteAverage is based on TMDB user ratings (similar to IMDb scale 0-10)
      if (movie.voteAverage != null && movie.voteCount != null) {
        final rating = movie.voteAverage!;
        final voteCount = movie.voteCount!;
        
        // ENHANCED: Better normalization for ratings
        // TMDB ratings are 0-10 scale, similar to IMDb
        final normalizedRating = (rating / 10.0).clamp(0.0, 1.0);
        
        // ENHANCED: Use logarithmic scale for vote count (more realistic)
        // Movies with 1000+ votes are highly credible, 10000+ are blockbusters
        final logVoteCount = voteCount > 0 ? (math.log(voteCount + 1) / math.log(10000)) : 0.0;
        final normalizedVoteCount = logVoteCount.clamp(0.0, 1.0);
        
        // ENHANCED: Combine rating (60%), vote count credibility (25%), and popularity (15%)
        final normalizedPopularity = movie.popularity != null 
            ? (movie.popularity! / 200.0).clamp(0.0, 1.0) 
            : 0.0;
        
        qualityScore = (normalizedRating * 0.60) + 
                      (normalizedVoteCount * 0.25) + 
                      (normalizedPopularity * 0.15);
      } else if (movie.voteAverage != null) {
        qualityScore = (movie.voteAverage! / 10.0).clamp(0.0, 1.0);
      }
      
      // Note: Rotten Tomatoes and IMDb scores are not directly available from TMDB API
      // TMDB provides voteAverage which is their own user rating system (similar to IMDb)
      // To get actual IMDb/Rotten Tomatoes scores, we would need OMDb API integration
      
      // ENHANCED: Temporal features (time-based scoring)
      final now = DateTime.now();
      final hour = now.hour;
      final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
      final month = now.month;
      
      // Time of day preferences (e.g., lighter content in morning, darker at night)
      if (hour >= 6 && hour < 12) {
        // Morning: Prefer lighter genres (comedy, family, animation)
        if (movie.genreIds != null) {
          final lightGenres = [35, 10751, 16]; // Comedy, Family, Animation
          if (movie.genreIds!.any((id) => lightGenres.contains(id))) {
            temporalScore += 0.3;
          }
        }
      } else if (hour >= 18 || hour < 6) {
        // Evening/Night: Prefer darker genres (horror, thriller, drama)
        if (movie.genreIds != null) {
          final darkGenres = [27, 53, 18]; // Horror, Thriller, Drama
          if (movie.genreIds!.any((id) => darkGenres.contains(id))) {
            temporalScore += 0.3;
          }
        }
      }
      
      // Weekend vs weekday preferences
      if (dayOfWeek >= 6) { // Weekend
        // Prefer action, adventure, blockbusters on weekends
        if (movie.genreIds != null) {
          final weekendGenres = [28, 12, 878]; // Action, Adventure, Sci-Fi
          if (movie.genreIds!.any((id) => weekendGenres.contains(id))) {
            temporalScore += 0.2;
          }
        }
      }
      
      // Seasonal preferences (e.g., horror in October, romance in February)
      if (month == 10) { // October - Halloween
        if (movie.genreIds != null && movie.genreIds!.contains(27)) { // Horror
          temporalScore += 0.3;
        }
      } else if (month == 2) { // February - Valentine's
        if (movie.genreIds != null && movie.genreIds!.contains(10749)) { // Romance
          temporalScore += 0.3;
        }
      } else if (month >= 11 || month <= 1) { // Holiday season
        if (movie.genreIds != null) {
          final holidayGenres = [10751, 35]; // Family, Comedy
          if (movie.genreIds!.any((id) => holidayGenres.contains(id))) {
            temporalScore += 0.2;
          }
        }
      }
      
      temporalScore = temporalScore.clamp(0.0, 1.0);
      
      // ENHANCED: Cross-feature interactions
      // Genre × Year interaction (e.g., recent sci-fi vs old sci-fi)
      if (movie.genreIds != null && movie.year != null) {
        final movieYear = int.tryParse(movie.year!);
        if (movieYear != null) {
          final yearsAgo = DateTime.now().year - movieYear;
          // Some genres benefit from being recent (sci-fi, action)
          final recentBenefitGenres = [878, 28, 12]; // Sci-Fi, Action, Adventure
          if (movie.genreIds!.any((id) => recentBenefitGenres.contains(id)) && yearsAgo <= 5) {
            crossFeatureScore += 0.2;
          }
          // Some genres are timeless (drama, comedy)
          final timelessGenres = [18, 35]; // Drama, Comedy
          if (movie.genreIds!.any((id) => timelessGenres.contains(id))) {
            crossFeatureScore += 0.1; // Small boost for timeless genres
          }
        }
      }
      
      // Rating × Popularity interaction (high rating + high popularity = quality)
      if (movie.voteAverage != null && movie.voteCount != null) {
        if (movie.voteAverage! >= 7.5 && movie.voteCount! >= 1000) {
          crossFeatureScore += 0.3; // High quality indicator
        }
      }
      
      // Genre × Rating interaction (some genres have different rating expectations)
      if (movie.genreIds != null && movie.voteAverage != null) {
        // Animation and family movies often have higher ratings
        final highRatingGenres = [16, 10751]; // Animation, Family
        if (movie.genreIds!.any((id) => highRatingGenres.contains(id)) && movie.voteAverage! >= 7.0) {
          crossFeatureScore += 0.2;
        }
      }
      
      crossFeatureScore = crossFeatureScore.clamp(0.0, 1.0);
      
      // Calculate base score from normalized components (adjusted weights)
      final baseScore = (genreScore * 0.25) +
                       (actorScore * 0.18) +
                       (directorScore * 0.12) +
                       (ratingScore * 0.12) +
                       (recencyScore * 0.05) +
                       (qualityScore * 0.12) +
                       (temporalScore * 0.08) + // NEW: Temporal features
                       (crossFeatureScore * 0.08); // NEW: Cross-features
      
      // ENHANCED: Use adaptive weights that learn from user feedback
      final adaptiveWeights = _adaptiveWeighting.getContextualWeights(
        user: user,
        likedMoviesCount: user.likedMovies.length,
        hasRecentActivity: _behaviorService.getInterestScore(movie.id) > 0,
      );
      
      // Content-based score (genre, actor, director)
      score = baseScore * adaptiveWeights['contentBased']!;
      
      // Contextual Recommendations - adaptive weight
      final contextualWeight = _contextualService.getContextualWeight(
        movie,
        currentMoods: currentMoods,
        currentTime: currentTime,
      );
      score += adaptiveWeights['contextual']! * contextualWeight;
      
      // Real-Time Learning from Behavior - adaptive weight
      final behaviorWeight = _behaviorService.getBehaviorWeight(movie.id);
      score += adaptiveWeights['behavior']! * behaviorWeight;
      
      // Embedding-Based Similarity - adaptive weight
      if (likedMovies.isNotEmpty) {
        final embeddingWeight = _embeddingService.getEmbeddingWeight(movie, likedMovies);
        score += adaptiveWeights['embedding']! * embeddingWeight;
      } else {
        score += adaptiveWeights['embedding']!; // Neutral if no liked movies
      }
      
      // Collaborative Filtering - adaptive weight
      final collaborativeWeight = _collaborativeService.getCollaborativeWeight(
        movie.id,
        userLikedMovieIds,
      );
      score += adaptiveWeights['collaborative']! * collaborativeWeight;
      
      // NEW: Matrix Factorization - learns latent factors from user interactions
      // A/B Testing: Adjust MF weight based on variant (already calculated above)
      final mfWeight = _mfService.getMatrixFactorizationWeight(user.id, movie.id);
      score += mfWeightMultiplier * mfWeight;
      
      // Deep Learning (0% weight for now - disabled until model is ready)
      // This was adding noise with fallback scoring
      
      scoredMovies.add(_ScoredMovie(movie: movie, score: score));
    }
    swScoringLoop.stop();
    _logPerf('scoreMoviesLoop(${movies.length})', swScoringLoop);
    
    // Sort by score (highest first)
    scoredMovies.sort((a, b) => b.score.compareTo(a.score));
    
    final scoredMovieList = scoredMovies.map((sm) => sm.movie).toList();
    
    // Track metrics for evaluation (async, don't block)
    _trackRecommendationMetrics(scoredMovieList, user);
    
    // NEW: Track A/B test metrics (async, don't block)
    _trackABTestMetrics(scoredMovieList, user);
    
    swScoreTotal.stop();
    _logPerf('scoreMovies total', swScoreTotal);
    return scoredMovieList;
  }
  
  /// Tracks recommendation metrics for evaluation
  void _trackRecommendationMetrics(List<Movie> recommendations, User user) {
    // Run asynchronously to not block recommendation generation
    Future.microtask(() async {
      try {
        final shownMovieIds = recommendations.map((m) => m.id).toSet();
        await _metricsService.evaluateRecommendations(
          recommendations: recommendations,
          user: user,
          shownMovieIds: shownMovieIds,
          k: 10,
        );
      } catch (e) {
        // Silently fail - metrics are not critical
        debugPrint('Error tracking metrics: $e');
      }
    });
  }

  /// Tracks A/B test metrics for variant comparison
  void _trackABTestMetrics(List<Movie> recommendations, User user) {
    // Run asynchronously to not block recommendation generation
    Future.microtask(() async {
      try {
        final variant = await _abTestingService.getUserVariant(user.id);
        
        // Track recommendation count as a simple metric
        // In production, track actual engagement (likes, views, etc.)
        final metric = recommendations.length.toDouble();
        await _abTestingService.recordMetric(variant, metric);
      } catch (e) {
        // Silently fail - A/B testing is not critical
        debugPrint('Error tracking A/B test metrics: $e');
      }
    });
  }

  /// Applies diversity filter to avoid clustering similar movies
  /// IMPROVED: Less aggressive, smarter diversity that preserves quality
  /// ENSURE: Always returns at least some movies (minimum 10)
  List<Movie> _applyDiversityFilter(List<Movie> movies) {
    if (movies.isEmpty) return movies;
    if (movies.length <= 15) return movies; // No need to diversify small lists
    
    // ENSURE: Always keep at least 10 movies, even if diversity filter is aggressive
    const minMoviesToKeep = 10;
    
    final diverseMovies = <Movie>[];
    final genreCounts = <int, int>{}; // Track how many times each genre appears
    final recentGenres = <List<int>>[]; // Track genres of last N movies
    
    for (final movie in movies) {
      bool shouldAdd = true;
      
      // IMPROVED: Check genre diversity more intelligently
      if (movie.genreIds != null && diverseMovies.length >= 3) {
        final movieGenres = movie.genreIds!.toSet();
        
        // Count how many recent movies share genres with this one
        int recentOverlaps = 0;
        for (final recentGenreList in recentGenres) {
          final recentGenres = recentGenreList.toSet();
          final overlap = movieGenres.intersection(recentGenres).length;
          if (overlap >= 2) {
            recentOverlaps++;
          }
        }
        
        // Only skip if last 3 movies all had significant genre overlap
        // This is less aggressive - allows some clustering but prevents too much
        // ENSURE: Never skip if we're below minimum threshold
        if (recentOverlaps >= 3 && diverseMovies.length >= 3 && diverseMovies.length >= minMoviesToKeep) {
          // Check if this movie is significantly better scored than what we have
          // If it's in top 20%, always include it
          final movieIndex = movies.indexOf(movie);
          if (movieIndex > movies.length * 0.2) {
            shouldAdd = false; // Lower ranked, can skip for diversity
          }
        }
      }
      
      if (shouldAdd) {
        diverseMovies.add(movie);
        
        // Track genres for diversity checking
        if (movie.genreIds != null) {
          final movieGenres = movie.genreIds!.toList();
          recentGenres.add(movieGenres);
          
          // Keep only last 5 movies for diversity checking
          if (recentGenres.length > 5) {
            recentGenres.removeAt(0);
          }
          
          // Update genre counts
          for (final genreId in movie.genreIds!) {
            genreCounts[genreId] = (genreCounts[genreId] ?? 0) + 1;
          }
        }
      }
      
      // If we have enough diverse movies, add remaining without strict filtering
      if (diverseMovies.length >= 30) {
        // Add remaining movies
        final remaining = movies.where((m) => !diverseMovies.contains(m)).toList();
        diverseMovies.addAll(remaining);
        break;
      }
    }
    
    // If we didn't get enough, add remaining movies
    if (diverseMovies.length < movies.length) {
      final remaining = movies.where((m) => !diverseMovies.contains(m)).toList();
      diverseMovies.addAll(remaining);
    }
    
    // ENSURE: Always return at least minMoviesToKeep movies (or all if less than that)
    if (diverseMovies.length < minMoviesToKeep && movies.length >= minMoviesToKeep) {
      // If diversity filter was too aggressive, take top minMoviesToKeep from original list
      return movies.take(minMoviesToKeep).toList();
    }
    
    return diverseMovies;
  }

  /// Sets swipe screen mood filters (supports multiple moods)
  void setSwipeMoods(List<Mood> moods) {
    _swipeMoods = moods;
    notifyListeners();
  }

  /// Sets swipe screen genre filters
  void setSwipeGenres(List<int> genres) {
    _swipeSelectedGenres = genres;
    notifyListeners();
  }

  /// Sets swipe screen platform filters
  void setSwipePlatforms(List<String> platforms) {
    _swipeSelectedPlatforms = platforms;
    notifyListeners();
  }

  /// Clears all swipe screen filters
  void clearSwipeFilters() {
    _swipeMoods = [];
    _swipeSelectedGenres = [];
    _swipeSelectedPlatforms = [];
    notifyListeners();
  }

  /// Immediately removes a movie from swipe/deck lists after interaction.
  void removeMovie(int movieId, {User? user}) {
    final beforeCount = _movies.length;
    _movies.removeWhere((movie) => movie.id == movieId);
    final removed = beforeCount - _movies.length;
    if (removed > 0) {
      refreshFilters(user);
      notifyListeners();
      debugPrint('MovieProvider: Removed movie $movieId from list');
    }
  }

  /// Refreshes the currently loaded lists by removing movies that are now
  /// liked/disliked/skipped/watchlisted by [user].
  ///
  /// This is primarily used by the detail screens so the swipe feed doesn't
  /// keep showing items that the user just interacted with.
  void refreshFilters(User? user) {
    if (user != null) {
      final likedIds = _movieIdsFromUserStrings(user.likedMovies);
      final dislikedIds = _movieIdsFromUserStrings(user.dislikedMovies);
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      final watchlistIds = _movieIdsFromUserStrings(user.watchlist);

      _movies.removeWhere((movie) =>
          likedIds.contains(movie.id) ||
          dislikedIds.contains(movie.id) ||
          skippedIds.contains(movie.id) ||
          watchlistIds.contains(movie.id));
      _pendingMovies.removeWhere((movie) =>
          likedIds.contains(movie.id) ||
          dislikedIds.contains(movie.id) ||
          skippedIds.contains(movie.id) ||
          watchlistIds.contains(movie.id));
    }

    // Swipe feed expects `filteredMovies` to reflect the latest `_movies` list.
    _filteredMovies = List.from(_movies);
    _flushPendingMoviesIfLow();
    _applyFilters();
  }
}

/// Helper class for scoring movies
class _ScoredMovie {
  final Movie movie;
  final double score;
  
  _ScoredMovie({required this.movie, required this.score});
} 