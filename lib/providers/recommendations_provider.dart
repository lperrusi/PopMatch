import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../models/mood.dart';
import '../services/recommendations_service.dart';

/// Provider for managing movie recommendations and user preferences
class RecommendationsProvider with ChangeNotifier {
  final RecommendationsService _recommendationsService = RecommendationsService.instance;
  
  List<Movie> _recommendations = [];
  List<Movie> _trendingRecommendations = [];
  List<Movie> _moodRecommendations = [];
  List<Movie> _becauseYouLikedRecommendations = [];
  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  DateTime? _lastRecommendationsLoad;
  static const Duration _cacheExpiration = Duration(minutes: 30); // Cache for 30 minutes
  
  // Cache of recently skipped movies to prevent them from reappearing
  final Set<int> _recentlySkippedMovies = {};
  
  // Cache of recently liked movies to prevent them from reappearing
  final Set<int> _recentlyLikedMovies = {};

  // Getters
  List<Movie> get recommendations => _filterOutRecentlyInteracted(_recommendations);
  List<Movie> get trendingRecommendations => _filterOutRecentlyInteracted(_trendingRecommendations);
  List<Movie> get moodRecommendations => _filterOutRecentlyInteracted(_moodRecommendations);
  List<Movie> get becauseYouLikedRecommendations => _filterOutRecentlyInteracted(_becauseYouLikedRecommendations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Filters out recently interacted movies (liked or skipped) from a list
  List<Movie> _filterOutRecentlyInteracted(List<Movie> movies) {
    return movies.where((movie) => 
      !_recentlySkippedMovies.contains(movie.id) && 
      !_recentlyLikedMovies.contains(movie.id)
    ).toList();
  }

  /// Adds a movie to the recently skipped cache
  void _addToRecentlySkipped(int movieId) {
    _recentlySkippedMovies.add(movieId);
    
    // Remove from cache after 24 hours to allow for fresh recommendations
    Future.delayed(const Duration(hours: 24), () {
      _recentlySkippedMovies.remove(movieId);
    });
  }

  /// Adds a movie to the recently liked cache
  void _addToRecentlyLiked(int movieId) {
    _recentlyLikedMovies.add(movieId);
    
    // Remove from cache after 24 hours to allow for fresh recommendations
    Future.delayed(const Duration(hours: 24), () {
      _recentlyLikedMovies.remove(movieId);
    });
  }

  /// Clears the recently skipped movies cache
  void clearRecentlySkippedCache() {
    _recentlySkippedMovies.clear();
    notifyListeners();
  }

  /// Clears the recently liked movies cache
  void clearRecentlyLikedCache() {
    _recentlyLikedMovies.clear();
    notifyListeners();
  }

  /// Clears all recently interacted movies cache
  void clearAllRecentlyInteractedCache() {
    _recentlySkippedMovies.clear();
    _recentlyLikedMovies.clear();
    notifyListeners();
  }

  /// Gets the count of recently skipped movies
  int get recentlySkippedCount => _recentlySkippedMovies.length;

  /// Gets the count of recently liked movies
  int get recentlyLikedCount => _recentlyLikedMovies.length;

  /// Gets the total count of recently interacted movies
  int get recentlyInteractedCount => _recentlySkippedMovies.length + _recentlyLikedMovies.length;

  /// Checks if a movie is in the recently skipped cache
  bool isRecentlySkipped(int movieId) {
    return _recentlySkippedMovies.contains(movieId);
  }

  /// Checks if a movie is in the recently liked cache
  bool isRecentlyLiked(int movieId) {
    return _recentlyLikedMovies.contains(movieId);
  }

  /// Checks if a movie has been recently interacted with (liked or skipped)
  bool isRecentlyInteracted(int movieId) {
    return _recentlySkippedMovies.contains(movieId) || _recentlyLikedMovies.contains(movieId);
  }

  /// Sets the current user for personalized recommendations
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Initializes the recommendations provider
  Future<void> initialize() async {
    await loadTrendingRecommendations();
  }

  /// Loads personalized recommendations for the current user
  Future<void> loadPersonalizedRecommendations({bool refresh = false}) async {
    if (_currentUser == null) return;

    // Check if we have cached recommendations that are still fresh
    final now = DateTime.now();
    final cacheValid = _lastRecommendationsLoad != null &&
        _recommendations.isNotEmpty &&
        now.difference(_lastRecommendationsLoad!) < _cacheExpiration;

    // If cache is valid and not refreshing, don't reload
    if (!refresh && cacheValid) {
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final recommendations = await _recommendationsService.getPersonalizedRecommendations(
        _currentUser!,
        limit: 20,
      );

      // Filter out recently interacted movies
      final filteredRecommendations = _filterOutRecentlyInteracted(recommendations);

      if (refresh) {
        _recommendations = filteredRecommendations;
      } else {
        _recommendations.addAll(filteredRecommendations);
      }

      _lastRecommendationsLoad = DateTime.now();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads trending recommendations
  Future<void> loadTrendingRecommendations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final trendingMovies = await _recommendationsService.getTrendingRecommendations();
      
      // Filter out recently interacted movies
      _trendingRecommendations = _filterOutRecentlyInteracted(trendingMovies);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads mood-based recommendations
  Future<void> loadMoodRecommendations(Mood mood) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final moodMovies = await _recommendationsService.getMoodRecommendations(mood);
      
      // Filter out recently interacted movies
      _moodRecommendations = _filterOutRecentlyInteracted(moodMovies);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads "Because you liked X" recommendations
  Future<void> loadBecauseYouLikedRecommendations(String movieId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final becauseYouLikedMovies = await _recommendationsService.getBecauseYouLikedRecommendations(movieId);
      
      // Filter out recently interacted movies
      _becauseYouLikedRecommendations = _filterOutRecentlyInteracted(becauseYouLikedMovies);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves user interaction (like/dislike) for improving recommendations
  Future<void> saveUserInteraction(String movieId, String interactionType) async {
    try {
      await _recommendationsService.saveUserInteraction(movieId, interactionType);
      
      // Only refresh recommendations if it's a like action
      // For dislikes, we'll remove the movie from current lists instead
      if (interactionType == 'like' && _currentUser != null) {
        await loadPersonalizedRecommendations(refresh: true);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Removes a movie from the personalized recommendations list
  void removeFromPersonalizedRecommendations(int movieId) {
    _recommendations.removeWhere((movie) => movie.id == movieId);
    notifyListeners();
  }

  /// Removes a movie from the trending recommendations list
  void removeFromTrendingRecommendations(int movieId) {
    _trendingRecommendations.removeWhere((movie) => movie.id == movieId);
    notifyListeners();
  }

  /// Removes a movie from the mood recommendations list
  void removeFromMoodRecommendations(int movieId) {
    _moodRecommendations.removeWhere((movie) => movie.id == movieId);
    notifyListeners();
  }

  /// Removes a movie from the "because you liked" recommendations list
  void removeFromBecauseYouLikedRecommendations(int movieId) {
    _becauseYouLikedRecommendations.removeWhere((movie) => movie.id == movieId);
    notifyListeners();
  }

  /// Removes a movie from all recommendation lists
  void removeMovieFromAllLists(int movieId) {
    removeFromPersonalizedRecommendations(movieId);
    removeFromTrendingRecommendations(movieId);
    removeFromMoodRecommendations(movieId);
    removeFromBecauseYouLikedRecommendations(movieId);
  }

  /// Handles movie skip/dislike with immediate UI update
  Future<void> handleMovieSkip(Movie movie) async {
    // Save the interaction in the background
    await saveUserInteraction(movie.id.toString(), 'dislike');
    
    // Immediately remove from all lists for instant UI feedback
    removeMovieFromAllLists(movie.id);
    _addToRecentlySkipped(movie.id); // Add to cache
  }

  /// Handles movie like with immediate UI update
  Future<void> handleMovieLike(Movie movie) async {
    // Save the interaction in the background
    await saveUserInteraction(movie.id.toString(), 'like');
    
    // Remove from current lists to avoid showing it again
    removeMovieFromAllLists(movie.id);
    _addToRecentlyLiked(movie.id); // Add to cache
  }

  /// Loads more recommendations if the current list is getting short
  Future<void> loadMoreRecommendationsIfNeeded() async {
    // If any list has less than 5 items, load more
    if (_recommendations.length < 5 && _currentUser != null) {
      await loadPersonalizedRecommendations();
    }
    
    if (_trendingRecommendations.length < 5) {
      await loadTrendingRecommendations();
    }
    
    if (_moodRecommendations.length < 5) {
      await loadMoodRecommendations(Mood.getById('happy') ?? Mood.getRandom());
    }
    
    // Ensure all lists are filtered after loading
    _recommendations = _filterOutRecentlyInteracted(_recommendations);
    _trendingRecommendations = _filterOutRecentlyInteracted(_trendingRecommendations);
    _moodRecommendations = _filterOutRecentlyInteracted(_moodRecommendations);
    _becauseYouLikedRecommendations = _filterOutRecentlyInteracted(_becauseYouLikedRecommendations);
    
    notifyListeners();
  }

  /// Gets genre-specific recommendations
  Future<List<Movie>> getGenreRecommendations(int genreId) async {
    try {
      return await _recommendationsService.getGenreRecommendations(genreId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets year-specific recommendations
  Future<List<Movie>> getYearRecommendations(int year) async {
    try {
      return await _recommendationsService.getYearRecommendations(year);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets hybrid recommendations (combining multiple approaches)
  Future<List<Movie>> getHybridRecommendations() async {
    if (_currentUser == null) return [];

    try {
      return await _recommendationsService.getHybridRecommendations(_currentUser!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets user interaction history
  Future<List<Map<String, dynamic>>> getUserInteractions() async {
    try {
      return await _recommendationsService.getUserInteractions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Refreshes all recommendations
  Future<void> refreshRecommendations() async {
    await Future.wait([
      loadPersonalizedRecommendations(refresh: true),
      loadTrendingRecommendations(),
    ]);
  }

  /// Clears the current error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Gets recommendations based on user's liked movies
  Future<List<Movie>> getRecommendationsBasedOnLikedMovies() async {
    if (_currentUser == null || _currentUser!.likedMovies.isEmpty) return [];

    try {
      final recommendations = <Movie>[];
      
      for (final movieId in _currentUser!.likedMovies) {
        final becauseYouLiked = await _recommendationsService.getBecauseYouLikedRecommendations(movieId);
        recommendations.addAll(becauseYouLiked);
      }
      
      // Remove duplicates and limit results
      final uniqueRecommendations = <Movie>{};
      uniqueRecommendations.addAll(recommendations);
      
      return uniqueRecommendations.take(10).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets recommendations that avoid user's disliked movies
  Future<List<Movie>> getRecommendationsAvoidingDislikedMovies() async {
    if (_currentUser == null) return [];

    try {
      // Get personalized recommendations (which already filter out disliked movies)
      return await _recommendationsService.getPersonalizedRecommendations(_currentUser!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets diverse recommendations (different genres, years, etc.)
  Future<List<Movie>> getDiverseRecommendations() async {
    if (_currentUser == null) return [];

    try {
      final recommendations = await _recommendationsService.getPersonalizedRecommendations(_currentUser!);
      
      // Apply additional diversity filtering
      final diverseRecommendations = <Movie>[];
      final usedGenres = <int>{};
      final usedYears = <int>{};
      
      for (final movie in recommendations) {
        bool shouldAdd = true;
        
        // Check genre diversity
        if (movie.genreIds != null) {
          for (final genreId in movie.genreIds!) {
            if (usedGenres.contains(genreId) && usedGenres.length < 8) {
              shouldAdd = false;
              break;
            }
          }
        }
        
        // Check year diversity
        if (movie.year != null) {
          final year = int.tryParse(movie.year!);
          if (year != null && usedYears.contains(year) && usedYears.length < 5) {
            shouldAdd = false;
          }
        }
        
        if (shouldAdd) {
          diverseRecommendations.add(movie);
          
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
      
      return diverseRecommendations;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Gets recommendations for new users (popular + trending)
  Future<List<Movie>> getRecommendationsForNewUser() async {
    try {
      final popularMovies = await _recommendationsService.getPopularRecommendations();
      final trendingMovies = await _recommendationsService.getTrendingRecommendations();
      
      final allMovies = <Movie>[];
      allMovies.addAll(popularMovies);
      allMovies.addAll(trendingMovies);
      
      // Remove duplicates and shuffle for variety
      final uniqueMovies = <Movie>{};
      uniqueMovies.addAll(allMovies);
      final shuffledMovies = uniqueMovies.toList()..shuffle();
      
      return shuffledMovies.take(20).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Updates user preferences and refreshes recommendations
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (_currentUser == null) return;

    try {
      // Update user preferences (this would typically be done through a user service)
      // For now, we'll just refresh recommendations
      await loadPersonalizedRecommendations(refresh: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 