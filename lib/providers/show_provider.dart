import 'package:flutter/foundation.dart';
import '../models/tv_show.dart';
import '../models/mood.dart';
import '../models/user.dart';
import '../services/tmdb_service.dart';
import '../services/behavior_tracking_service.dart';

/// Provider class for managing TV show data and filtering
class ShowProvider with ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final BehaviorTrackingService _behaviorService = BehaviorTrackingService();
  
  List<TvShow> _shows = [];
  List<TvShow> _filteredShows = [];
  Map<int, String> _genres = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Swipe screen filter states
  List<Mood> _swipeMoods = [];
  List<int> _swipeSelectedGenres = [];
  List<String> _swipeSelectedPlatforms = [];

  // Getters
  List<TvShow> get shows => _shows;
  List<TvShow> get filteredShows => _filteredShows;
  Map<int, String> get genres => _genres;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
  
  // Swipe screen filter getters
  List<Mood> get swipeMoods => _swipeMoods;
  List<int> get swipeSelectedGenres => _swipeSelectedGenres;
  List<String> get swipeSelectedPlatforms => _swipeSelectedPlatforms;

  /// Loads popular shows from TMDB API
  Future<void> loadPopularShows({bool refresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _hasMorePages = true;
      }
      
      final newShows = await _tmdbService.getPopularShows(page: _currentPage);
      
      if (refresh) {
        _shows = newShows;
      } else {
        _shows.addAll(newShows);
      }
      
      _hasMorePages = newShows.isNotEmpty;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads personalized show recommendations based on user preferences
  Future<void> loadPersonalizedRecommendations(User user, {bool refresh = false, bool insertAtFront = false, bool backgroundLoad = false}) async {
    try {
      if (!backgroundLoad) {
        _isLoading = true;
        notifyListeners();
      }
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _hasMorePages = true;
      }

      final allRecommendations = <TvShow>[];
      final seenShowIds = <int>{};
      
      // Track already shown shows to avoid duplicates
      final currentShowIds = _shows.map((s) => s.id).toSet();

      // Strategy 1: Discover shows based on user preferences
      final genresToUse = _swipeSelectedGenres.isNotEmpty 
          ? _swipeSelectedGenres 
          : [18, 35, 16]; // Default: Drama, Comedy, Animation
      
      // If mood filters are set, combine genres from all selected moods
      List<int> finalGenres;
      if (_swipeMoods.isNotEmpty) {
        final moodGenres = <int>{};
        for (final mood in _swipeMoods) {
          moodGenres.addAll(mood.preferredGenres);
        }
        finalGenres = moodGenres.toList();
      } else {
        finalGenres = genresToUse.isNotEmpty ? genresToUse : [18, 35, 16];
      }
      
      if (finalGenres.isNotEmpty) {
        try {
          final currentYear = DateTime.now().year;
          final minYear = currentYear - 15;
          
          final discoveredShows = await _tmdbService.discoverShows(
            genres: finalGenres,
            minYear: minYear,
            minRating: 6.0,
            page: _currentPage,
          );
          
          for (final show in discoveredShows) {
            if (!seenShowIds.contains(show.id) && !currentShowIds.contains(show.id)) {
              // Filter out skipped shows
              final skippedIds = _behaviorService.getSkippedMovies(user.id);
              if (!skippedIds.contains(show.id)) {
                allRecommendations.add(show);
                seenShowIds.add(show.id);
              }
            }
          }
        } catch (e) {
          debugPrint('Error discovering shows: $e');
        }
      }

      // Strategy 2: Get popular shows as fallback
      if (allRecommendations.length < 20) {
        try {
          final popularShows = await _tmdbService.getPopularShows(page: _currentPage);
          for (final show in popularShows) {
            if (!seenShowIds.contains(show.id) && !currentShowIds.contains(show.id)) {
              final skippedIds = _behaviorService.getSkippedMovies(user.id);
              if (!skippedIds.contains(show.id)) {
                allRecommendations.add(show);
                seenShowIds.add(show.id);
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading popular shows: $e');
        }
      }

      // Filter out liked and disliked shows
      final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      
      allRecommendations.removeWhere((show) => 
        likedShowIds.contains(show.id) || dislikedShowIds.contains(show.id)
      );

      // Limit to 20 shows per load
      final showsToAdd = allRecommendations.take(20).toList();
      
      if (insertAtFront) {
        _shows.insertAll(0, showsToAdd);
      } else {
        _shows.addAll(showsToAdd);
      }
      
      _hasMorePages = showsToAdd.length >= 20;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading personalized show recommendations: $e');
    } finally {
      if (!backgroundLoad) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// Loads curated starter shows for new users
  Future<void> loadCuratedStarterShows({bool refresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _hasMorePages = true;
      }
      
      // Load popular shows for new users
      final newShows = await _tmdbService.getPopularShows(page: _currentPage);
      
      if (refresh) {
        _shows = newShows;
      } else {
        _shows.addAll(newShows);
      }
      
      _hasMorePages = newShows.isNotEmpty;
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads TV show genres
  Future<void> loadGenres() async {
    try {
      _genres = await _tmdbService.getTvGenres();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Applies current filters to shows
  void _applyFilters() {
    _filteredShows = List.from(_shows);
    
    // Apply genre filter
    if (_swipeSelectedGenres.isNotEmpty) {
      _filteredShows = _filteredShows.where((show) {
        final showGenres = show.genreIds ?? [];
        return _swipeSelectedGenres.any((genreId) => showGenres.contains(genreId));
      }).toList();
    }
    
    notifyListeners();
  }

  /// Sets swipe moods filter
  void setSwipeMoods(List<Mood> moods) {
    _swipeMoods = moods;
    _applyFilters();
    notifyListeners();
  }

  /// Sets swipe genres filter
  void setSwipeGenres(List<int> genres) {
    _swipeSelectedGenres = genres;
    _applyFilters();
    notifyListeners();
  }

  /// Sets swipe platforms filter
  void setSwipePlatforms(List<String> platforms) {
    _swipeSelectedPlatforms = platforms;
    _applyFilters();
    notifyListeners();
  }

  /// Clears all swipe filters
  void clearSwipeFilters() {
    _swipeMoods = [];
    _swipeSelectedGenres = [];
    _swipeSelectedPlatforms = [];
    _applyFilters();
    notifyListeners();
  }

  /// Loads more shows (pagination)
  Future<void> loadMoreShows(User user) async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await loadPersonalizedRecommendations(user);
  }
}
