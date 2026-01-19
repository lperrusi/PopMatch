import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/mood.dart';
import '../models/user.dart';
import '../services/tmdb_service.dart';
import '../services/user_preference_analyzer.dart';
import '../services/streaming_service.dart';
import '../services/contextual_recommendation_service.dart';
import '../services/behavior_tracking_service.dart';
import '../services/movie_embedding_service.dart';
import '../services/collaborative_filtering_service.dart';
import '../services/deep_learning_service.dart';
import '../services/movie_cache_service.dart';
import '../services/adaptive_weighting_service.dart';
import '../services/recommendation_metrics_service.dart';

/// Provider class for managing movie data and filtering
class MovieProvider with ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final ContextualRecommendationService _contextualService = ContextualRecommendationService();
  final BehaviorTrackingService _behaviorService = BehaviorTrackingService();
  final MovieEmbeddingService _embeddingService = MovieEmbeddingService();
  final CollaborativeFilteringService _collaborativeService = CollaborativeFilteringService();
  final DeepLearningService _deepLearningService = DeepLearningService();
  final AdaptiveWeightingService _adaptiveWeighting = AdaptiveWeightingService();
  final RecommendationMetricsService _metricsService = RecommendationMetricsService();
  
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  Map<int, String> _genres = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Filter states
  int? _selectedGenreId;
  int? _selectedYear;
  String _searchQuery = '';
  Mood? _currentMood;
  
  // Swipe screen filter states
  List<Mood> _swipeMoods = []; // Changed to support multiple moods
  List<int> _swipeSelectedGenres = [];
  List<String> _swipeSelectedPlatforms = [];

  // Getters
  List<Movie> get movies => _movies;
  List<Movie> get filteredMovies => _filteredMovies;
  Map<int, String> get genres => _genres;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
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
    });
  }

  /// Loads popular movies from TMDB API
  Future<void> loadPopularMovies({bool refresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _movies.clear();
        _hasMorePages = true;
      }
      
      // Don't notify listeners here - wait until after the async operation
      final newMovies = await _tmdbService.getPopularMovies(page: _currentPage);
      
      if (refresh) {
        _movies = newMovies;
      } else {
        _movies.addAll(newMovies);
      }
      
      _hasMorePages = newMovies.isNotEmpty;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads a curated starter movie list designed to help the algorithm learn user preferences
  /// This list prioritizes both popularity and rating while maintaining genre diversity for optimal learning
  Future<void> loadCuratedStarterMovies({bool refresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _movies.clear();
        _hasMorePages = true;
      }

      final allMovies = <Movie>[];
      final seenMovieIds = <int>{};

      // Strategy 1: Get highly-rated popular movies (best of both worlds)
      // These are movies that are both well-known AND well-liked
      try {
        // Get top-rated movies that are also popular (min 100 votes for credibility)
        final topRatedPopular = await _tmdbService.discoverMovies(
          minRating: 7.0, // Good rating threshold
          sortBy: 'popularity.desc', // Prioritize popularity
          page: 1,
        );
        
        // Take top 25 highly-rated popular movies
        for (final movie in topRatedPopular.take(25)) {
          allMovies.add(movie);
          seenMovieIds.add(movie.id);
        }
      } catch (e) {
        debugPrint('Error loading top-rated popular movies: $e');
      }

      // Strategy 2: Get most popular movies (first page)
      // These are movies users are most likely to know
      try {
        final page1Popular = await _tmdbService.getPopularMovies(page: 1);
        
        for (final movie in page1Popular) {
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

      // Strategy 4: Ensure genre diversity with popular AND well-rated movies
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

      if (refresh) {
        _movies = shuffledMovies;
      } else {
        _movies.addAll(shuffledMovies);
      }
      
      _hasMorePages = shuffledMovies.isNotEmpty;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading curated starter movies: $e');
      // Fallback to regular popular movies if curated load fails
      await loadPopularMovies(refresh: refresh);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads more movies (pagination)
  Future<void> loadMoreMovies() async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await loadPopularMovies();
  }

  /// Loads genres from TMDB API
  Future<void> loadGenres() async {
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

  /// Loads personalized movie recommendations based on user preferences
  Future<void> loadPersonalizedRecommendations(User user, {bool refresh = false, bool insertAtFront = false, bool backgroundLoad = false}) async {
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
        _hasMorePages = true;
      }

      final analyzer = UserPreferenceAnalyzer();
      final preferences = await analyzer.analyzePreferences(user);
      
      final allRecommendations = <Movie>[];
      final seenMovieIds = <int>{};
      
      // Track already shown movies to avoid duplicates
      final currentMovieIds = _movies.map((m) => m.id).toSet();

      // Strategy 1: Discover movies based on user preferences
      // Use swipe filters if set, otherwise use user preferences
      final genresToUse = _swipeSelectedGenres.isNotEmpty 
          ? _swipeSelectedGenres 
          : preferences.topGenres.take(3).toList();
      
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
      
      if (finalGenres.isNotEmpty) {
        try {
          // Prefer recent movies (last 15 years) but don't restrict to specific years
          final currentYear = DateTime.now().year;
          final minYear = currentYear - 15;
          
          final discoveredMovies = await _tmdbService.discoverMovies(
            genres: finalGenres,
            minYear: minYear, // Prefer recent movies
            minRating: preferences.preferredMinRating,
            maxRating: preferences.preferredMaxRating,
            page: _currentPage,
          );
          
          for (final movie in discoveredMovies) {
            if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
              allRecommendations.add(movie);
              seenMovieIds.add(movie.id);
            }
          }
        } catch (e) {
          debugPrint('Error discovering movies: $e');
        }
      }

      // Strategy 2: Get recommendations based on liked movies (increased from 3 to 8)
      if (user.likedMovies.isNotEmpty) {
        // Get recommendations from top 8 liked movies (prioritize most recent)
        final likedMoviesToAnalyze = user.likedMovies.reversed.take(8).toList();
        for (final movieIdStr in likedMoviesToAnalyze) {
          try {
            final movieId = int.parse(movieIdStr);
            final similarMovies = await _tmdbService.getSimilarMovies(movieId);
            final recommendedMovies = await _tmdbService.getMovieRecommendations(movieId);
            
            // Combine similar and recommended movies
            final combinedMovies = <Movie>[];
            combinedMovies.addAll(similarMovies);
            combinedMovies.addAll(recommendedMovies);
            
            for (final movie in combinedMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie);
                seenMovieIds.add(movie.id);
              }
            }
          } catch (e) {
            // Continue with next movie
            continue;
          }
        }
      }

      // Strategy 3: Get movies by preferred actors and directors
      if (allRecommendations.length < 30) {
        // Get movies from top 5 preferred actors
        for (final actorName in preferences.preferredActors.take(5)) {
          try {
            final actorMovies = await _tmdbService.searchMoviesByActor(actorName, page: _currentPage);
            for (final movie in actorMovies) {
              if (!seenMovieIds.contains(movie.id) && !currentMovieIds.contains(movie.id)) {
                allRecommendations.add(movie);
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
                allRecommendations.add(movie);
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
                allRecommendations.add(movie);
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
              allRecommendations.add(movie);
              seenMovieIds.add(movie.id);
            }
          }
        } catch (e) {
          debugPrint('Error loading popular movies as fallback: $e');
        }
      }

      // Filter out disliked movies
      final dislikedIds = user.dislikedMovies.map((id) => int.parse(id)).toSet();
      allRecommendations.removeWhere((movie) => dislikedIds.contains(movie.id));

      // Filter out already liked movies (to show new recommendations)
      final likedIds = user.likedMovies.map((id) => int.parse(id)).toSet();
      allRecommendations.removeWhere((movie) => likedIds.contains(movie.id));

      // Filter out skipped movies (movies user swiped past without liking/disliking)
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      allRecommendations.removeWhere((movie) => skippedIds.contains(movie.id));

      // NEW: Quality filter - remove low-quality movies before scoring
      // This prevents bad movies from cluttering recommendations
      allRecommendations.removeWhere((movie) {
        // Require minimum rating (unless user explicitly likes low-rated movies)
        if (movie.voteAverage != null && movie.voteAverage! < 5.0) {
          // Only keep if it has significant popularity (might be controversial but popular)
          if (movie.voteCount == null || movie.voteCount! < 100) {
            return true; // Remove this movie
          }
        }
        // Require minimum vote count for credibility (unless very recent)
        if (movie.voteCount != null && movie.voteCount! < 10) {
          final movieYear = movie.year != null ? int.tryParse(movie.year!) : null;
          if (movieYear == null || DateTime.now().year - movieYear > 1) {
            return true; // Remove this movie - not recent enough to have low votes
          }
        }
        return false; // Keep this movie
      });

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
      if (_swipeSelectedPlatforms.isNotEmpty) {
        final streamingService = StreamingService.instance;
        platformFilteredMovies = await streamingService.getMoviesOnMultiplePlatforms(
          scoredMovies,
          _swipeSelectedPlatforms,
        );
        // If platform filtering removed too many movies, keep some without platform filter
        if (platformFilteredMovies.length < 10 && scoredMovies.length >= 10) {
          // Keep top 10 scored movies even if they don't match platform
          platformFilteredMovies = scoredMovies.take(10).toList();
        }
      }

      // Apply diversity filter to avoid clustering
      final diverseMovies = _applyDiversityFilter(platformFilteredMovies);

      if (refresh) {
        _movies = diverseMovies;
      } else if (insertAtFront && !backgroundLoad) {
        // Insert new recommendations at the front so they appear next
        // Only do this if not loading in background (to avoid disrupting current view)
        _movies.insertAll(0, diverseMovies);
      } else {
        // For background loads, always add to end so they appear behind current cards
        _movies.addAll(diverseMovies);
      }

      _hasMorePages = diverseMovies.isNotEmpty;
      _applyFilters();
      
      // Only notify listeners if not loading in background (to avoid UI disruption)
      // For background loads, we'll notify once at the end
      if (!backgroundLoad) {
        notifyListeners();
      }
      
    } catch (e) {
      _error = e.toString();
      // Fallback to popular movies on error
      if (_movies.isEmpty) {
        await loadPopularMovies(refresh: true);
      }
    } finally {
      if (!backgroundLoad) {
        _isLoading = false;
        notifyListeners();
      } else {
        // For background loads, notify once at the end to update the list
        // This happens after movies are added, so current card won't disappear
        notifyListeners();
      }
    }
  }

  /// Loads more personalized recommendations (pagination)
  Future<void> loadMorePersonalizedRecommendations(User user) async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await loadPersonalizedRecommendations(user);
  }

  /// Scores movies based on relevance to user preferences
  Future<List<Movie>> _scoreMovies(
    List<Movie> movies,
    UserPreferences preferences,
    User user,
  ) async {
    final scoredMovies = <_ScoredMovie>[];
    
    // Cache for credits to avoid repeated API calls
    final creditsCache = <int, Map<String, dynamic>>{};
    
    // Fetch credits in parallel for top movies (reduced limit for better performance)
    // Only fetch for top 20 movies instead of 50 to reduce API calls and improve speed
    final moviesToVerify = movies.take(20).toList();
    final creditFutures = moviesToVerify.map((movie) async {
      try {
        final credits = await _tmdbService.getMovieCredits(movie.id);
        creditsCache[movie.id] = credits;
      } catch (e) {
        // Skip if fetch fails
      }
    });
    
    // Wait for all credit fetches (with shorter timeout for better responsiveness)
    try {
      await Future.wait(creditFutures, eagerError: false).timeout(
        const Duration(seconds: 3), // Reduced from 5 to 3 seconds
      );
    } catch (e) {
      debugPrint('Credit fetch timeout - continuing with partial data');
    }
    
    // Get user's liked movies for collaborative filtering and embeddings
    // Use cache service to avoid redundant API calls
    final userLikedMovieIds = user.likedMovies.map((id) => int.parse(id)).toSet();
    final likedMovies = <Movie>[];
    final cacheService = MovieCacheService.instance;
    
    // Try cache first, then API if not cached
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

    // Get current context for contextual recommendations
    final currentTime = DateTime.now();
    final currentMoods = _swipeMoods;

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
      
      // IMPROVED: Recency scoring (normalized 0-1, then weighted 5%)
      if (movie.year != null) {
        final movieYear = int.tryParse(movie.year!);
        if (movieYear != null) {
          final currentYear = DateTime.now().year;
          final yearsAgo = currentYear - movieYear;
          if (yearsAgo <= 2) {
            recencyScore = 1.0;
          } else if (yearsAgo <= 5) {
            recencyScore = 0.8;
          } else if (yearsAgo <= 10) {
            recencyScore = 0.6;
          } else if (yearsAgo <= 15) {
            recencyScore = 0.4;
          } else {
            recencyScore = 0.2; // Still give some credit for older movies
          }
        }
      }
      
      // NEW: Quality score (normalized 0-1, then weighted 15%)
      // Rewards movies with good ratings AND popularity
      if (movie.voteAverage != null && movie.voteCount != null) {
        final rating = movie.voteAverage!;
        final voteCount = movie.voteCount!;
        // Normalize rating (0-10 scale) and vote count (log scale for popularity)
        final normalizedRating = (rating / 10.0).clamp(0.0, 1.0);
        final normalizedPopularity = (voteCount / 1000.0).clamp(0.0, 1.0).clamp(0.0, 1.0);
        // Combine: 70% rating, 30% popularity
        qualityScore = (normalizedRating * 0.7) + (normalizedPopularity * 0.3);
      } else if (movie.voteAverage != null) {
        qualityScore = (movie.voteAverage! / 10.0).clamp(0.0, 1.0);
      }
      
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
      
      // Deep Learning (0% weight for now - disabled until model is ready)
      // This was adding noise with fallback scoring
      
      scoredMovies.add(_ScoredMovie(movie: movie, score: score));
    }
    
    // Sort by score (highest first)
    scoredMovies.sort((a, b) => b.score.compareTo(a.score));
    
    final scoredMovieList = scoredMovies.map((sm) => sm.movie).toList();
    
    // Track metrics for evaluation (async, don't block)
    _trackRecommendationMetrics(scoredMovieList, user);
    
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

  /// Applies diversity filter to avoid clustering similar movies
  /// IMPROVED: Less aggressive, smarter diversity that preserves quality
  List<Movie> _applyDiversityFilter(List<Movie> movies) {
    if (movies.isEmpty) return movies;
    if (movies.length <= 15) return movies; // No need to diversify small lists
    
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
        if (recentOverlaps >= 3 && diverseMovies.length >= 3) {
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
}

/// Helper class for scoring movies
class _ScoredMovie {
  final Movie movie;
  final double score;
  
  _ScoredMovie({required this.movie, required this.score});
} 