import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/tv_show.dart';
import '../models/mood.dart';
import '../models/user.dart';
import '../models/streaming_platform.dart';
import '../services/tmdb_service.dart';
import '../services/streaming_service.dart';
import '../services/behavior_tracking_service.dart';
import '../services/user_preference_analyzer.dart';
import '../services/user_preferences_session_cache.dart';
import '../services/collaborative_filtering_service.dart';
import '../services/adaptive_weighting_service.dart';
import '../services/matrix_factorization_service.dart';
import '../services/ab_testing_service.dart';
import '../services/omdb_service.dart';
import '../utils/recommendation_item_id_utils.dart';
import '../services/discover_movie_list_cache.dart';

/// Helper class for scored shows
class _ScoredShow {
  final TvShow show;
  final double score;
  
  _ScoredShow({required this.show, required this.score});
}

/// Provider class for managing TV show data and filtering
class ShowProvider with ChangeNotifier {
  final TMDBService _tmdbService = TMDBService();
  final BehaviorTrackingService _behaviorService = BehaviorTrackingService();
  final CollaborativeFilteringService _collaborativeService = CollaborativeFilteringService();
  final AdaptiveWeightingService _adaptiveWeighting = AdaptiveWeightingService();
  final MatrixFactorizationService _mfService = MatrixFactorizationService();
  final ABTestingService _abTestingService = ABTestingService();
  final OMDbService _omdbService = OMDbService.instance;

  // Maps a recommended show id → the strategy that contributed most to its
  // score, for training adaptive weights on a later swipe. Session-only.
  final Map<int, String> _itemDominantStrategy = {};
  // Guards loadWeights so persisted adaptive weights load once per user/session.
  String? _weightsLoadedForUserId;

  /// Session-scoped cache for show credits (cleared on app restart, same pattern as movies)
  final Map<int, Map<String, dynamic>> _showCreditsSessionCache = {};

  List<TvShow> _shows = [];
  List<TvShow> _filteredShows = [];
  Map<int, String> _genres = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  
  // INFINITE SWIPE: Buffer management for seamless experience
  static const int _minBufferSize = 30;
  static const int _preloadThreshold = 30; // Start preloading earlier to avoid empty-deck flash
  static const int _maxTmdbPages = 400;
  /// Minimum cards so that newly loaded ones are added "behind" the visible stack (0,1,2).
  static const int _minLengthToAddBehind = 3;
  bool _isPreloading = false; // Track if we're currently preloading
  DateTime? _lastPreloadTime; // Rate limit preloading

  /// Shows loaded in background when visible count was < 3; merged when list becomes empty so user never sees them "pop in".
  final List<TvShow> _pendingShows = [];

  // Swipe screen filter states
  List<Mood> _swipeMoods = [];
  List<int> _swipeSelectedGenres = [];
  List<String> _swipeSelectedPlatforms = [];

  // Getters
  List<TvShow> get shows => _shows;
  List<TvShow> get filteredShows => _filteredShows;
  Map<int, String> get genres => _genres;
  bool get isLoading => _isLoading;
  /// True while fetching the next page for infinite swipe.
  bool get isPreloading => _isPreloading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;
  int get remainingShowsCount => _filteredShows.length;
  bool get needsPreload => _filteredShows.length < _preloadThreshold && _hasMorePages && !_isLoading && !_isPreloading;

  bool _discoverBootstrapComplete = false;
  bool get discoverBootstrapComplete => _discoverBootstrapComplete;

  // Shared in-memory cache so tab switching doesn't recompute user preferences twice.
  final UserPreferencesSessionCache _prefsCache = UserPreferencesSessionCache();

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

  bool _integrationTestDeckSeeded = false;

  /// When true, [SwipeScreen] can skip its initial TMDB load for shows.
  bool get shouldSkipDiscoverSwipeLoad => _integrationTestDeckSeeded;

  /// Seeds the show swipe deck without network calls (mirrors [MovieProvider.replaceSwipeDeckForTest]).
  @visibleForTesting
  void replaceSwipeDeckForTest(List<TvShow> shows) {
    _shows = List<TvShow>.from(shows);
    _pendingShows.clear();
    _filteredShows = List<TvShow>.from(_shows);
    _hasMorePages = false;
    _isLoading = false;
    _isPreloading = false;
    _discoverBootstrapComplete = true;
    _error = null;
    _integrationTestDeckSeeded = true;
    notifyListeners();
  }

  /// See [MovieProvider.beginDiscoverRefillLoading].
  void beginDiscoverRefillLoading() {
    _isLoading = true;
    _shows.clear();
    _pendingShows.clear();
    _applyFilters(user: null);
    notifyListeners();
  }

  void _logPerf(String label, Stopwatch sw) {
    if (!kDebugMode) return;
    debugPrint('ShowProvider perf [$label]: ${sw.elapsedMilliseconds}ms');
  }
  
  // Swipe screen filter getters
  List<Mood> get swipeMoods => _swipeMoods;
  List<int> get swipeSelectedGenres => _swipeSelectedGenres;
  List<String> get swipeSelectedPlatforms => _swipeSelectedPlatforms;

  /// Loads popular shows from TMDB API
  Future<void> loadPopularShows({bool refresh = false, User? user}) async {
    try {
      _isLoading = true;
      _error = null;
      
      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      }
      
      final newShows = await _tmdbService.getPopularShows(page: _currentPage);
      
      // Filter out already liked/disliked/skipped/watchlist shows
      List<TvShow> filteredNewShows = newShows;
      if (user != null) {
        final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final skippedIds = _behaviorService.getSkippedMovies(user.id);
        final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final currentShowIds = _shows.map((s) => s.id).toSet();
        
        filteredNewShows = newShows.where((show) => 
          !likedShowIds.contains(show.id) && 
          !dislikedShowIds.contains(show.id) && 
          !skippedIds.contains(showItemId(show.id)) &&
          !watchlistShowIds.contains(show.id) &&
          !currentShowIds.contains(show.id)
        ).toList();
        
        debugPrint('ShowProvider: Filtered popular shows from ${newShows.length} to ${filteredNewShows.length}');
      }
      
      if (refresh) {
        _shows = filteredNewShows;
      } else {
        _shows.addAll(filteredNewShows);
      }
      
      _hasMorePages = filteredNewShows.isNotEmpty;
      
      // CRITICAL: Final safety filter
      if (user != null) {
        _filterOutInteractedShows(user);
      }
      
      // Apply filters with user data to ensure proper filtering
      _applyFilters(user: user);
      
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

  /// Loads personalized show recommendations based on user preferences
  Future<void> loadPersonalizedRecommendations(User user, {bool refresh = false, bool insertAtFront = false, bool backgroundLoad = false}) async {
    final swTotal = Stopwatch();
    try {
      debugPrint('ShowProvider: Starting loadPersonalizedRecommendations (refresh: $refresh, backgroundLoad: $backgroundLoad)');
      if (!backgroundLoad) {
        _isLoading = true;
        notifyListeners();
      }
      _error = null;

      // Restore this user's persisted adaptive weights once per session.
      if (_weightsLoadedForUserId != user.id) {
        await _adaptiveWeighting.loadWeights(user.id);
        _weightsLoadedForUserId = user.id;
      }

      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _pendingShows.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      }

      // NEW: A/B Testing - Get user's algorithm variant
      swTotal.start();
      final swVariantAndPrefs = Stopwatch()..start();
      final variant = await _abTestingService.getUserVariant(user.id);
      debugPrint('A/B Test (Shows): User ${user.id} assigned to variant: $variant');

      // NEW: Analyze user preferences from liked shows (similar to movies)
      final preferences = await _prefsCache.getOrCompute(
        user,
        forceRefresh: refresh,
      );
      final preferredGenresFromProfile = _genreIdsFromUserPreferences(user);
      final effectivePlatformIds = _swipeSelectedPlatforms.isNotEmpty
          ? _swipeSelectedPlatforms
          : _platformIdsFromUserPreferences(user);
      debugPrint('ShowProvider: Analyzed preferences, top genres: ${preferences.topGenres.take(3).toList()}');
      swVariantAndPrefs.stop();
      _logPerf('variant+analyzePreferences', swVariantAndPrefs);

      final allRecommendations = <TvShow>[];
      final seenShowIds = <int>{};
      
      // Track deck + pending so TMDB batches don’t re-fetch the same IDs
      final currentShowIds = <int>{
        ..._shows.map((s) => s.id),
        ..._pendingShows.map((s) => s.id),
      };
      void addCandidates(Iterable<TvShow> shows, {required String strategy}) {
        for (final show in shows) {
          if (!seenShowIds.contains(show.id) && !currentShowIds.contains(show.id)) {
            allRecommendations.add(show.copyWith(recommendationStrategy: strategy));
            seenShowIds.add(show.id);
          }
        }
      }

      // Strategy 3: Discover shows based on user preferences
      final genresToUse = _swipeSelectedGenres.isNotEmpty
          ? _swipeSelectedGenres
          : (preferredGenresFromProfile.isNotEmpty
              ? preferredGenresFromProfile.take(3).toList()
              : (preferences.topGenres.isNotEmpty
                  ? preferences.topGenres.take(3).toList()
                  : [18, 35, 16]));
      
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
      
      final currentYear = DateTime.now().year;
      final minYear = currentYear - 15;
      final swParallelPrimary = Stopwatch()..start();
      final primaryResults = await Future.wait([
        () async {
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.getTrendingShows(page: _currentPage);
            sw.stop();
            _logPerf('strategy.trending', sw);
            return data;
          } catch (e) {
            debugPrint('Error loading trending shows: $e');
            return <TvShow>[];
          }
        }(),
        () async {
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.getTopRatedShows(page: _currentPage);
            sw.stop();
            _logPerf('strategy.topRatedShows', sw);
            return data;
          } catch (e) {
            debugPrint('Error loading top-rated shows: $e');
            return <TvShow>[];
          }
        }(),
        () async {
          if (finalGenres.isEmpty) return <TvShow>[];
          try {
            final sw = Stopwatch()..start();
            final data = await _tmdbService.discoverShows(
              genres: finalGenres,
              minYear: minYear,
              minRating: preferences.preferredMinRating ?? 6.0,
              page: _currentPage,
            );
            sw.stop();
            _logPerf('strategy.discoverShows', sw);
            return data;
          } catch (e) {
            debugPrint('Error discovering shows: $e');
            return <TvShow>[];
          }
        }(),
      ]);
      swParallelPrimary.stop();
      _logPerf('strategy.primaryParallelBatch', swParallelPrimary);
      addCandidates(primaryResults[0], strategy: 'contentBased');
      addCandidates(primaryResults[1], strategy: 'contentBased');
      addCandidates(primaryResults[2], strategy: 'contentBased');

      // Strategy 5: Similar + recommended shows from user's top liked shows
      // (mirrors movie strategy that fetches /movie/{id}/similar and /recommendations)
      if (!backgroundLoad) {
        final likedShowIdsForSimilar = user.likedShows
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .take(3)
            .toList();
        if (likedShowIdsForSimilar.isNotEmpty) {
          try {
            final swSimilar = Stopwatch()..start();
            final similarFutures = likedShowIdsForSimilar.expand((id) => [
              _tmdbService.getSimilarShows(id),
              _tmdbService.getShowRecommendations(id),
            ]).toList();
            final similarResults = await Future.wait(similarFutures, eagerError: false)
                .timeout(const Duration(seconds: 4));
            swSimilar.stop();
            _logPerf('strategy.similarShows', swSimilar);
            for (final batch in similarResults) {
              addCandidates(batch, strategy: 'contentBased');
            }
          } catch (e) {
            debugPrint('ShowProvider: Error loading similar/recommended shows: $e');
          }
        }
      }

      // Strategy 6: Actor-based show discovery from user's top preferred actors
      // (mirrors movie strategy that calls searchMoviesByActor)
      if (!backgroundLoad && allRecommendations.length < 30) {
        try {
          final swActors = Stopwatch()..start();
          for (final actorName in preferences.preferredActors.take(3)) {
            try {
              final actorShows = await _tmdbService.searchShowsByActor(actorName);
              addCandidates(actorShows.take(10), strategy: 'contentBased');
              if (seenShowIds.length >= 60) break;
            } catch (_) {
              continue;
            }
          }
          swActors.stop();
          _logPerf('strategy.actorShows', swActors);
        } catch (e) {
          debugPrint('ShowProvider: Error loading actor-based shows: $e');
        }
      }

      // Strategy 4: Get popular shows as fallback
      if (allRecommendations.length < 20) {
        try {
          debugPrint('ShowProvider: Loading popular shows as fallback (current count: ${allRecommendations.length})');
          final swPopularFallback = Stopwatch()..start();
          final popularShows = await _tmdbService.getPopularShows(page: _currentPage);
          swPopularFallback.stop();
          _logPerf('strategy.popularFallbackShows', swPopularFallback);
          debugPrint('ShowProvider: Loaded ${popularShows.length} popular shows');
          for (final show in popularShows) {
            if (!seenShowIds.contains(show.id) && !currentShowIds.contains(show.id)) {
              allRecommendations.add(show.copyWith(recommendationStrategy: 'contentBased'));
              seenShowIds.add(show.id);
            }
          }
          debugPrint('ShowProvider: After adding popular shows, total: ${allRecommendations.length}');
        } catch (e) {
          debugPrint('Error loading popular shows: $e');
        }
      }
      
      // ENSURE: If we still have no recommendations, force load popular shows
      if (allRecommendations.isEmpty) {
        debugPrint('ShowProvider: No recommendations found, forcing popular shows load');
        try {
          final popularShows = await _tmdbService.getPopularShows(page: 1);
          // Filter forced load results before adding
          final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
          final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
          final skippedIds = _behaviorService.getSkippedMovies(user.id);
          final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
          
          final filteredPopularShows = popularShows.where((show) => 
            !likedShowIds.contains(show.id) && 
            !dislikedShowIds.contains(show.id) && 
            !skippedIds.contains(showItemId(show.id)) &&
            !watchlistShowIds.contains(show.id) &&
            !currentShowIds.contains(show.id)
          ).map((show) => show.copyWith(recommendationStrategy: 'contentBased')).toList();
          
          allRecommendations.addAll(filteredPopularShows);
          debugPrint('ShowProvider: Forced load added ${filteredPopularShows.length} shows (filtered from ${popularShows.length})');
        } catch (e) {
          debugPrint('ShowProvider: Error in forced popular shows load: $e');
        }
      }

      // Filter out liked, disliked, and watchlist shows (do this AFTER forced load too)
      final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
      
      debugPrint('ShowProvider: Filtering shows - liked: ${likedShowIds.length}, disliked: ${dislikedShowIds.length}, watchlist: ${watchlistShowIds.length}, current: ${currentShowIds.length}');
      
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      Set<int>? requiredGenreIds;
      if (_swipeMoods.isNotEmpty) {
        final moodGenreIds = <int>{};
        for (final mood in _swipeMoods) {
          moodGenreIds.addAll(mood.preferredGenres);
        }
        requiredGenreIds = moodGenreIds;
      } else if (_swipeSelectedGenres.isNotEmpty) {
        requiredGenreIds = _swipeSelectedGenres.toSet();
      } else if (preferredGenresFromProfile.isNotEmpty) {
        requiredGenreIds = preferredGenresFromProfile.toSet();
      }
      final filteredRecommendations = <TvShow>[];
      for (final show in allRecommendations) {
        if (likedShowIds.contains(show.id) ||
            dislikedShowIds.contains(show.id) ||
            watchlistShowIds.contains(show.id) ||
            currentShowIds.contains(show.id) ||
            skippedIds.contains(showItemId(show.id))) {
          continue;
        }
        if (requiredGenreIds != null) {
          final showGenres = show.genreIds ?? const <int>[];
          if (showGenres.isEmpty ||
              !showGenres.any((id) => requiredGenreIds!.contains(id))) {
            continue;
          }
        }
        if (show.voteAverage != null &&
            show.voteAverage! < 5.0 &&
            (show.voteCount == null || show.voteCount! < 50)) {
          continue;
        }
        if (show.voteCount != null && show.voteCount! < 10) {
          final showYear = show.year != null ? int.tryParse(show.year!) : null;
          if (showYear == null || DateTime.now().year - showYear > 1) {
            continue;
          }
        }
        filteredRecommendations.add(show);
      }
      allRecommendations
        ..clear()
        ..addAll(filteredRecommendations);

      // NEW: Score and rank shows by relevance
      final swScoreShows = Stopwatch()..start();
      final scoredShows = await _scoreShows(
        allRecommendations,
        preferences,
        user,
        variant,
      );
      swScoreShows.stop();
      _logPerf('scoreShows', swScoreShows);

      // ENHANCED: Fetch external ratings (IMDb, Rotten Tomatoes) for top shows
      // This is done in background (fire and forget) to enhance quality scoring without blocking
      // Don't await - let it run in background without blocking the main flow
      if (!backgroundLoad) {
        _enhanceShowsWithExternalRatings(scoredShows.take(8).toList()).catchError((e) {
          debugPrint('Error enhancing shows with external ratings: $e');
        });
      }

      // Apply diversity filter
      final diverseShows = _applyDiversityFilter(scoredShows);
      
      // ENSURE: Always return at least some shows, even if diversity filter is aggressive
      // If diversity filter removed everything, use the scored shows instead
      List<TvShow> candidateShows = diverseShows.isNotEmpty
          ? diverseShows
          : (scoredShows.isNotEmpty
              ? scoredShows.take(20).toList()
              : allRecommendations.take(20).toList());

      // Apply platform filter when user has selected platforms (same as movies).
      // Limit to top 80 candidates — we only show 50 cards, checking all is wasteful.
      List<TvShow> finalShows;
      if (effectivePlatformIds.isNotEmpty) {
        final streamingService = StreamingService.instance;
        final platformFilteredShows = await streamingService.getShowsOnMultiplePlatforms(
          candidateShows.take(80).toList(),
          effectivePlatformIds,
        );
        if (platformFilteredShows.isNotEmpty) {
          finalShows = platformFilteredShows;
        } else {
          // Avoid starvation loops when provider data is temporarily missing.
          final fallbackCount = backgroundLoad ? 8 : 12;
          finalShows = candidateShows.take(fallbackCount).toList();
          debugPrint(
            'ShowProvider: Platform filter returned 0; using $fallbackCount candidate fallback shows',
          );
        }
      } else {
        finalShows = candidateShows;
      }
      
      debugPrint('ShowProvider: Final shows count: ${finalShows.length} (diverse: ${diverseShows.length}, scored: ${scoredShows.length}, all: ${allRecommendations.length})');
      
      if (finalShows.isEmpty) {
        debugPrint('ShowProvider: WARNING - No shows to add! This should not happen.');
        // Last resort: try to load popular shows directly
        try {
          final emergencyShows = await _tmdbService.getPopularShows(page: 1);
          if (emergencyShows.isNotEmpty) {
            // CRITICAL: Filter emergency shows before adding
            final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
            final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
            final skippedIds = _behaviorService.getSkippedMovies(user.id);
            final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
            final deckShowIds = <int>{
              ..._shows.map((s) => s.id),
              ..._pendingShows.map((s) => s.id),
            };

            final filteredEmergencyShows = emergencyShows.where((show) =>
              !likedShowIds.contains(show.id) &&
              !dislikedShowIds.contains(show.id) &&
              !skippedIds.contains(showItemId(show.id)) &&
              !watchlistShowIds.contains(show.id) &&
              !deckShowIds.contains(show.id)
            ).toList();

            debugPrint('ShowProvider: Emergency load filtered from ${emergencyShows.length} to ${filteredEmergencyShows.length} shows');

            if (filteredEmergencyShows.isNotEmpty) {
              if (insertAtFront) {
                _shows.insertAll(0, filteredEmergencyShows);
              } else {
                _shows.addAll(filteredEmergencyShows);
              }
              if (_currentPage < _maxTmdbPages) {
                _currentPage++;
              }
              _hasMorePages = _currentPage < _maxTmdbPages;
              // Final safety filter after adding
              _filterOutInteractedShows(user);
              // Apply filters with user data to ensure proper filtering
              _applyFilters(user: user);
              if (!backgroundLoad) {
                _isLoading = false;
              }
              notifyListeners();
              return;
            }
          }
        } catch (e) {
          debugPrint('ShowProvider: Emergency load also failed: $e');
        }
      }
      
      final mergedShowIds = <int>{
        ..._shows.map((s) => s.id),
        ..._pendingShows.map((s) => s.id),
      };
      final uniqueNewShows =
          finalShows.where((s) => !mergedShowIds.contains(s.id)).toList();

      var appendedToVisibleDeck = false;
      if (insertAtFront) {
        _shows.insertAll(0, uniqueNewShows);
      } else if (refresh) {
        // Initial load or refresh: we cleared _shows above, so always show the loaded result (don't defer to pending).
        _shows.addAll(uniqueNewShows);
      } else {
        // Background add-to-end: only add when visible count >= 3 so new cards sit *behind* the stack and don't "pop in".
        if (_filteredShows.length >= _minLengthToAddBehind) {
          _shows.addAll(uniqueNewShows);
          appendedToVisibleDeck = true;
        } else {
          _pendingShows.addAll(uniqueNewShows);
          debugPrint('ShowProvider: Deferred ${uniqueNewShows.length} shows to pending (visible count ${_filteredShows.length} < $_minLengthToAddBehind)');
        }
      }

      if (_currentPage < _maxTmdbPages) {
        _currentPage++;
      }
      _hasMorePages = _currentPage < _maxTmdbPages &&
          (uniqueNewShows.isNotEmpty || allRecommendations.length >= 8);
      
      if (!backgroundLoad) {
        // Foreground loads can fully reconcile deck + pending with latest interactions.
        _filterOutInteractedShows(user);
        _applyFilters(user: user);
      } else {
        // Keep active swipe deck stable during background preloads.
        // Only sanitize pending and append to filtered tail when direct append happened.
        _removeInteractedFromPending(user);
        if (appendedToVisibleDeck && uniqueNewShows.isNotEmpty) {
          final filteredIds = _filteredShows.map((s) => s.id).toSet();
          _filteredShows.addAll(
            uniqueNewShows.where((s) => !filteredIds.contains(s.id)),
          );
        }
      }
      swTotal.stop();
      _logPerf('loadPersonalizedRecommendations total', swTotal);

      // Persist deck so next cold open shows cards instantly (skip on background preloads)
      if (!backgroundLoad && refresh) {
        final showsToCache = _shows.take(50).toList();
        unawaited(DiscoverMovieListCache.instance.saveShows(
            DiscoverMovieListCache.keyShowsPersonalized, showsToCache));
      }

      debugPrint('ShowProvider: Shows loaded successfully. Total shows: ${_shows.length}, filtered: ${_filteredShows.length}, pending: ${_pendingShows.length}');

      // INFINITE SWIPE: After adding shows, check if we need to preload more
      if (backgroundLoad) {
        _isPreloading = false;
        _lastPreloadTime = DateTime.now();
      }
      
      // INFINITE SWIPE: Trigger additional preload if buffer is still low
      if (backgroundLoad && _filteredShows.length < _minBufferSize && _hasMorePages) {
        _ensureBufferFilled(user);
      }
      
    } catch (e, stackTrace) {
      swTotal.stop();
      _logPerf('loadPersonalizedRecommendations total (error)', swTotal);
      _error = e.toString();
      _isPreloading = false;
      debugPrint('ShowProvider: ERROR loading personalized show recommendations: $e');
      debugPrint('ShowProvider: Stack trace: $stackTrace');
      
      // Fallback: Try to load popular shows on error
      if (_shows.isEmpty) {
        debugPrint('ShowProvider: Attempting fallback to popular shows');
        try {
          await loadPopularShows(refresh: true, user: user);
        } catch (fallbackError) {
          debugPrint('ShowProvider: Fallback also failed: $fallbackError');
        }
      }
    } finally {
      _discoverBootstrapComplete = true;
      if (!backgroundLoad) {
        _isLoading = false;
      }
      notifyListeners();
      debugPrint('ShowProvider: loadPersonalizedRecommendations completed. isLoading: $_isLoading, shows count: ${_shows.length}');
    }
  }
  
  /// INFINITE SWIPE: Ensures buffer is filled with enough shows for seamless swiping
  /// This method continuously preloads content in the background
  Future<void> _ensureBufferFilled(
    User? user, {
    bool allowAppendWhileDeckLarge = false,
  }) async {
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
    
    if (!allowAppendWhileDeckLarge && _filteredShows.length >= _minBufferSize) {
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
          // Load more popular shows (with user for filtering)
          await loadMorePopularShows(user: user);
        }
      } else {
        // No user, load more popular shows
        await loadMorePopularShows(user: null);
      }
    } catch (e) {
      debugPrint('Error preloading shows for buffer: $e');
    } finally {
      _isPreloading = false;
      _lastPreloadTime = DateTime.now();
    }
  }
  
  /// INFINITE SWIPE: Public method to check and preload if needed
  /// Called from swipe screen to maintain buffer.
  ///
  /// See [MovieProvider.checkAndPreload] for [estimatedRemaining].
  Future<void> checkAndPreload(User? user, {int? estimatedRemaining}) async {
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

  void clearSwipeFeedStack({User? user}) {
    _shows.clear();
    _pendingShows.clear();
    _applyFilters(user: user);
    notifyListeners();
  }

  /// When the user swipes past the last show — clear and load the next page.
  Future<void> refillSwipeDeckAfterEnd(User? user) async {
    _isLoading = true;
    _error = null;
    _shows.clear();
    _pendingShows.clear();
    notifyListeners();
    try {
      if (user == null) {
        await loadCuratedStarterShows(refresh: false, user: null);
      } else {
        final analyzer = UserPreferenceAnalyzer();
        if (analyzer.hasEnoughData(user)) {
          await loadPersonalizedRecommendations(user, refresh: false);
        } else {
          await loadCuratedStarterShows(refresh: false, user: user);
        }
      }
    } catch (e, st) {
      debugPrint('ShowProvider.refillSwipeDeckAfterEnd: $e\n$st');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads previously-persisted shows from disk and populates the swipe deck instantly.
  Future<bool> loadCachedShowsInstant({
    required String cacheKey,
    User? user,
  }) async {
    final cached = await DiscoverMovieListCache.instance.loadShows(cacheKey);
    if (cached == null || cached.isEmpty) return false;

    List<TvShow> filtered = cached;
    if (user != null) {
      final likedIds =
          user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final dislikedIds = user.dislikedShows
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toSet();
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      final watchlistIds = user.watchlistShowsOrEmpty
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toSet();
      filtered = cached
          .where((s) =>
              !likedIds.contains(s.id) &&
              !dislikedIds.contains(s.id) &&
              !skippedIds.contains(showItemId(s.id)) &&
              !watchlistIds.contains(s.id))
          .toList();
    }
    if (filtered.isEmpty) return false;

    _shows = filtered;
    _applyFilters(user: user);
    notifyListeners();
    return true;
  }

  /// Loads curated starter shows for new users
  Future<void> loadCuratedStarterShows({bool refresh = false, User? user}) async {
    try {
      debugPrint('ShowProvider: Starting loadCuratedStarterShows (refresh: $refresh, user: ${user?.id ?? "null"})');
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      if (refresh) {
        _currentPage = 1;
        _shows.clear();
        _hasMorePages = true;
        _discoverBootstrapComplete = false;
      } else {
        // When loading more curated shows, just use popular shows with pagination
        // Curated starter is designed as a one-time curated set
        await loadMorePopularShows(user: user);
        return;
      }
      
      // Gather user onboarding genre preferences for curated ranking
      final onboardingGenreRaw = user?.preferences['selectedGenres'] as List<dynamic>?;
      final userOnboardingGenreIds = onboardingGenreRaw?.map((g) => g as int).toList() ?? [];
      final keyGenres = userOnboardingGenreIds.isNotEmpty
          ? userOnboardingGenreIds
          : [18, 35, 16, 878, 28, 53, 80, 27, 10749, 10759]; // Drama, Comedy, Animation, Sci-Fi…

      final allShows = <TvShow>[];
      final seenShowIds = <int>{};

      // Batch 1: Popular shows
      debugPrint('ShowProvider: Loading popular shows page $_currentPage');
      try {
        final popular = await _tmdbService.getPopularShows(page: 1);
        for (final s in popular) {
          allShows.add(s.copyWith(recommendationStrategy: 'popular'));
          seenShowIds.add(s.id);
        }
        debugPrint('ShowProvider: Loaded ${popular.length} popular shows');
      } catch (e) {
        debugPrint('ShowProvider: Error loading popular shows: $e');
      }

      // Batch 2: Top-rated shows
      try {
        final topRated = await _tmdbService.getTopRatedShows(page: 1);
        for (final s in topRated) {
          if (!seenShowIds.contains(s.id)) {
            allShows.add(s.copyWith(recommendationStrategy: 'top_rated'));
            seenShowIds.add(s.id);
          }
        }
      } catch (e) {
        debugPrint('ShowProvider: Error loading top-rated shows: $e');
      }

      // Batch 3: Genre-specific shows — fetch all in parallel
      final genreShowBatches = await Future.wait(
        keyGenres.take(5).map((genreId) async {
          try {
            return await _tmdbService.discoverShows(
              genres: [genreId],
              minRating: 6.5,
              sortBy: 'popularity.desc',
              page: 1,
            );
          } catch (e) {
            debugPrint('ShowProvider: Error loading genre $genreId shows: $e');
            return <TvShow>[];
          }
        }),
      );
      for (final batch in genreShowBatches) {
        for (final s in batch.take(5)) {
          if (!seenShowIds.contains(s.id)) {
            allShows.add(s.copyWith(recommendationStrategy: 'genre_match'));
            seenShowIds.add(s.id);
          }
        }
      }

      // Sort by popularity + rating, with a boost for user's onboarding genres
      allShows.sort((a, b) {
        final popA = (a.popularity ?? 0.0) / 100.0;
        final popB = (b.popularity ?? 0.0) / 100.0;
        final ratingA = a.voteAverage ?? 0.0;
        final ratingB = b.voteAverage ?? 0.0;
        final boostA = (userOnboardingGenreIds.isNotEmpty &&
                (a.genreIds?.any((g) => userOnboardingGenreIds.contains(g)) ?? false))
            ? 0.15
            : 0.0;
        final boostB = (userOnboardingGenreIds.isNotEmpty &&
                (b.genreIds?.any((g) => userOnboardingGenreIds.contains(g)) ?? false))
            ? 0.15
            : 0.0;
        final scoreA = (ratingA * 0.6) + (popA.clamp(0.0, 10.0) * 0.4) + boostA;
        final scoreB = (ratingB * 0.6) + (popB.clamp(0.0, 10.0) * 0.4) + boostB;
        return scoreB.compareTo(scoreA);
      });

      List<TvShow> newShows = allShows.take(60).toList();

      // Filter out already liked/disliked/skipped/watchlist shows even for curated starter
      List<TvShow> filteredNewShows = newShows;
      if (user != null) {
        final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final skippedIds = _behaviorService.getSkippedMovies(user.id);
        final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
        final currentShowIds = _shows.map((s) => s.id).toSet();

        filteredNewShows = newShows.where((show) =>
          !likedShowIds.contains(show.id) &&
          !dislikedShowIds.contains(show.id) &&
          !skippedIds.contains(showItemId(show.id)) &&
          !watchlistShowIds.contains(show.id) &&
          !currentShowIds.contains(show.id)
        ).toList();

        debugPrint('ShowProvider: Filtered curated shows from ${newShows.length} to ${filteredNewShows.length}');
      }

      // Apply platform filter when user has selected platforms
      List<TvShow> showsToAdd = filteredNewShows;
      final effectivePlatformIds = user == null
          ? _swipeSelectedPlatforms
          : (_swipeSelectedPlatforms.isNotEmpty
              ? _swipeSelectedPlatforms
              : _platformIdsFromUserPreferences(user));
      if (effectivePlatformIds.isNotEmpty) {
        final streamingService = StreamingService.instance;
        final platformFiltered = await streamingService.getShowsOnMultiplePlatforms(
          filteredNewShows,
          effectivePlatformIds,
        );
        if (platformFiltered.isNotEmpty) {
          showsToAdd = platformFiltered;
        } else {
          // Platform data is temporarily unavailable — use unfiltered candidates
          // so the deck is never starved. _hasMorePages stays true so a later
          // preload can retry with fresh provider data.
          debugPrint('ShowProvider: Platform filter returned 0 curated shows; using unfiltered fallback');
        }
      }

      if (refresh) {
        _shows = showsToAdd;
      } else {
        _shows.addAll(showsToAdd);
      }

      _hasMorePages = showsToAdd.isNotEmpty;
      
      // CRITICAL: Final safety filter
      if (user != null) {
        _filterOutInteractedShows(user);
      }
      
      // Apply filters with user data to ensure proper filtering
      _applyFilters(user: user);

      // Persist deck so next cold open can show shows instantly
      unawaited(DiscoverMovieListCache.instance
          .saveShows(DiscoverMovieListCache.keyShowsCurated, showsToAdd.take(50).toList()));

      debugPrint('ShowProvider: Curated starter shows loaded. Total: ${_shows.length}, filtered: ${_filteredShows.length}');

    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('ShowProvider: ERROR in loadCuratedStarterShows: $e');
      debugPrint('ShowProvider: Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      _discoverBootstrapComplete = true;
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
  void _applyFilters({User? user}) {
    _filteredShows = List.from(_shows);
    
    // CRITICAL: First filter out liked/disliked/skipped/watchlist shows if user is provided
    if (user != null) {
      final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
      final skippedIds = _behaviorService.getSkippedMovies(user.id);
      final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
      
      _filteredShows.removeWhere((show) => 
        likedShowIds.contains(show.id) || 
        dislikedShowIds.contains(show.id) || 
        skippedIds.contains(showItemId(show.id)) ||
        watchlistShowIds.contains(show.id)
      );
    }
    
    // Apply mood or genre filter (mood takes precedence when both are set)
    if (_swipeMoods.isNotEmpty) {
      final moodGenreIds = <int>{};
      for (final mood in _swipeMoods) {
        moodGenreIds.addAll(mood.preferredGenres);
      }
      _filteredShows = _filteredShows.where((show) {
        final showGenres = show.genreIds ?? [];
        return showGenres.isNotEmpty && showGenres.any((id) => moodGenreIds.contains(id));
      }).toList();
    } else if (_swipeSelectedGenres.isNotEmpty) {
      _filteredShows = _filteredShows.where((show) {
        final showGenres = show.genreIds ?? [];
        return _swipeSelectedGenres.any((genreId) => showGenres.contains(genreId));
      }).toList();
    }

    // Apply platform filter (client-side, uses cached streaming data).
    // Three-way logic mirrors StreamingService.getShowsOnMultiplePlatforms:
    //   null            → API error, unknown — pass through (don't starve deck)
    //   empty platforms → confirmed not on streaming — exclude
    //   non-empty       → check against selection, exclude if no match
    if (_swipeSelectedPlatforms.isNotEmpty) {
      _filteredShows = _filteredShows.where((show) {
        final avail = show.streamingAvailability;
        if (avail == null) return true; // Unknown (API error) — pass through.
        if (avail.availablePlatforms.isEmpty) return false; // Confirmed not on streaming.
        return _swipeSelectedPlatforms.any((id) => avail.isAvailableOn(id));
      }).toList();
    }

    notifyListeners();
  }
  
  /// Immediately removes a show from the list when user interacts with it
  /// Returns the strategy key with the largest contribution to a show's score.
  String _dominantStrategy(Map<String, double> contributions) {
    var bestKey = 'contentBased';
    var bestValue = double.negativeInfinity;
    for (final entry in contributions.entries) {
      if (entry.value > bestValue) {
        bestValue = entry.value;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }

  /// Trains the adaptive weights from a swipe: attributes the like/dislike to
  /// the strategy that surfaced [showId] (recorded at scoring time). No-op if
  /// the show wasn't scored this session (e.g. curated/starter cards).
  Future<void> recordSwipeFeedback({
    required int showId,
    required bool liked,
    required User user,
  }) async {
    final strategy = _itemDominantStrategy[showId];
    if (strategy == null) return;
    await _adaptiveWeighting.recordFeedback(
      strategy: strategy,
      liked: liked,
      user: user,
    );
  }

  /// Restores a just-swiped show to the front of the deck (for UNDO).
  /// Mirrors [MovieProvider.reinsertSwipedMovieAtFront]; bypasses like/dislike
  /// filtering so it doesn't race the asynchronous auth rollback.
  void reinsertSwipedShowAtFront(TvShow show) {
    _shows.removeWhere((s) => s.id == show.id);
    _shows.insert(0, show);
    _filteredShows.removeWhere((s) => s.id == show.id);
    _filteredShows.insert(0, show);
    notifyListeners();
  }

  void removeShow(int showId, {User? user}) {
    final beforeCount = _shows.length;
    _shows.removeWhere((show) => show.id == showId);
    final removed = beforeCount - _shows.length;
    if (removed > 0) {
      _applyFilters(user: user);
      // When we're about to show empty, flush pending shows so user gets content without seeing "pop in" during swipe
      if (_filteredShows.isEmpty && _pendingShows.isNotEmpty) {
        _shows = List<TvShow>.from(_pendingShows);
        _pendingShows.clear();
        _filterOutInteractedShows(user);
        _applyFilters(user: user);
        debugPrint('ShowProvider: Flushed ${_shows.length} pending shows (was empty)');
      }
      notifyListeners();
      debugPrint('ShowProvider: Removed show $showId from list');
    }
  }
  
  /// Re-filters all shows with the latest user data
  /// Call this when user data changes (e.g., after liking/disliking)
  void refreshFilters(User? user) {
    if (user != null) {
      _filterOutInteractedShows(user);
      _applyFilters(user: user);
      notifyListeners();
      debugPrint('ShowProvider: Refreshed filters with latest user data');
    }
  }
  
  /// CRITICAL: Final safety filter to remove any liked/disliked/skipped/watchlist shows
  /// This should be called after any shows are added to ensure nothing slips through
  void _filterOutInteractedShows(User? user) {
    if (user == null) return;
    
    final likedShowIds = user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final dislikedShowIds = user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final skippedIds = _behaviorService.getSkippedMovies(user.id);
    final watchlistShowIds = user.watchlistShowsOrEmpty.map((id) => int.tryParse(id)).whereType<int>().toSet();
    
    final beforeFilter = _shows.length;
    
    _shows.removeWhere((show) =>
        likedShowIds.contains(show.id) ||
        dislikedShowIds.contains(show.id) ||
        skippedIds.contains(showItemId(show.id)) ||
        watchlistShowIds.contains(show.id));

    final pendingBefore = _pendingShows.length;
    _pendingShows.removeWhere((show) =>
        likedShowIds.contains(show.id) ||
        dislikedShowIds.contains(show.id) ||
        skippedIds.contains(showItemId(show.id)) ||
        watchlistShowIds.contains(show.id));

    final removedShows = beforeFilter - _shows.length;
    final removedPending = pendingBefore - _pendingShows.length;
    if (removedShows > 0 || removedPending > 0) {
      debugPrint(
        'ShowProvider: SAFETY FILTER removed $removedShows shows, $removedPending pending (liked: ${likedShowIds.length}, disliked: ${dislikedShowIds.length}, skipped: ${skippedIds.length}, watchlist: ${watchlistShowIds.length})',
      );
      _applyFilters(user: user);
    }
  }

  void _removeInteractedFromPending(User user) {
    final likedShowIds =
        user.likedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final dislikedShowIds =
        user.dislikedShows.map((id) => int.tryParse(id)).whereType<int>().toSet();
    final skippedIds = _behaviorService.getSkippedMovies(user.id);
    final watchlistShowIds = user.watchlistShowsOrEmpty
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    _pendingShows.removeWhere(
      (show) =>
          likedShowIds.contains(show.id) ||
          dislikedShowIds.contains(show.id) ||
          skippedIds.contains(showItemId(show.id)) ||
          watchlistShowIds.contains(show.id),
    );
  }

  /// Sets swipe moods filter
  void setSwipeMoods(List<Mood> moods, {User? user}) {
    _swipeMoods = moods;
    _applyFilters(user: user);
    notifyListeners();
  }

  /// Sets swipe genres filter
  void setSwipeGenres(List<int> genres, {User? user}) {
    _swipeSelectedGenres = genres;
    _applyFilters(user: user);
    notifyListeners();
  }

  /// Sets swipe platforms filter
  void setSwipePlatforms(List<String> platforms, {User? user}) {
    _swipeSelectedPlatforms = platforms;
    _applyFilters(user: user);
    notifyListeners();
  }

  /// Clears all swipe filters
  void clearSwipeFilters({User? user}) {
    _swipeMoods = [];
    _swipeSelectedGenres = [];
    _swipeSelectedPlatforms = [];
    _applyFilters(user: user);
    notifyListeners();
  }

  /// ENHANCED: Fetches external ratings (IMDb, Rotten Tomatoes) for shows
  /// This is done in background to enhance show quality scores
  /// IMPORTANT: This method batches updates and only notifies listeners once at the end
  /// to avoid causing UI refreshes after every show
  Future<void> _enhanceShowsWithExternalRatings(List<TvShow> shows) async {
    // Load OMDb API key if not already loaded
    await _omdbService.loadApiKey();
    
    // Track if we made any updates
    bool hasUpdates = false;
    final updatedShows = <int, TvShow>{};
    
    // Process shows in batches to avoid overwhelming the API
    for (final show in shows) {
      // Skip if we already have external ratings
      if (show.imdbRating != null || show.rottenTomatoesTomatometer != null) {
        continue;
      }
      
      // Skip if no IMDb ID available (we need it to fetch from OMDb)
      if (show.imdbId == null || show.imdbId!.isEmpty) {
        // Try to fetch IMDb ID from TMDB
        try {
          final externalIds = await _tmdbService.getShowExternalIds(show.id);
          final imdbId = externalIds['imdb_id'];
          if (imdbId == null || imdbId.isEmpty) {
            continue; // No IMDb ID available
          }
          
          // Store update for batch processing
          TvShow updatedShow = show.copyWith(imdbId: imdbId);
          
          // Fetch ratings from OMDb
          final ratings = await _omdbService.getRatingsByImdbId(imdbId);
          if (ratings != null) {
            updatedShow = updatedShow.copyWith(
              imdbRating: ratings.imdbRating,
              imdbVotes: ratings.imdbVotes,
              rottenTomatoesTomatometer: ratings.rottenTomatoesTomatometer,
              rottenTomatoesAudienceScore: ratings.rottenTomatoesAudienceScore,
            );
            updatedShows[show.id] = updatedShow;
            hasUpdates = true;
          } else {
            // Still update with IMDb ID even if ratings aren't available
            updatedShows[show.id] = updatedShow;
            hasUpdates = true;
          }
        } catch (e) {
          // Silently fail - external ratings are optional
          debugPrint('Error fetching external ratings for show ${show.id}: $e');
        }
      } else {
        // We have IMDb ID, fetch ratings directly
        try {
          final ratings = await _omdbService.getRatingsByImdbId(show.imdbId!);
          if (ratings != null) {
            final updatedShow = show.copyWith(
              imdbRating: ratings.imdbRating,
              imdbVotes: ratings.imdbVotes,
              rottenTomatoesTomatometer: ratings.rottenTomatoesTomatometer,
              rottenTomatoesAudienceScore: ratings.rottenTomatoesAudienceScore,
            );
            updatedShows[show.id] = updatedShow;
            hasUpdates = true;
          }
        } catch (e) {
          // Silently fail - external ratings are optional
          debugPrint('Error fetching external ratings for show ${show.id}: $e');
        }
      }
      
      // Rate limit: small delay between requests to avoid overwhelming OMDb API
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
      // Batch update all shows at once and notify listeners only once
      if (hasUpdates) {
        for (int i = 0; i < _shows.length; i++) {
          final showId = _shows[i].id;
          if (updatedShows.containsKey(showId)) {
            _shows[i] = updatedShows[showId]!;
          }
        }
        
        // Update filtered shows list with updated ratings (no need to re-filter)
        // Just update the existing filtered shows with new rating data
        for (int i = 0; i < _filteredShows.length; i++) {
          final showId = _filteredShows[i].id;
          if (updatedShows.containsKey(showId)) {
            _filteredShows[i] = updatedShows[showId]!;
          }
        }
        
        // Don't call notifyListeners() here - external ratings are background enhancement
        // The UI doesn't need to refresh just for rating updates
        // Only notify if this is a critical update, which it's not
        debugPrint('ShowProvider: Enhanced ${updatedShows.length} shows with external ratings (silent update)');
      }
    }

  /// Loads more shows (pagination) - for personalized recommendations
  Future<void> loadMoreShows(User user) async {
    if (_isLoading || !_hasMorePages) return;

    await loadPersonalizedRecommendations(user);
  }

  /// Loads more popular shows (pagination) - for non-personalized loading
  Future<void> loadMorePopularShows({User? user}) async {
    if (_isLoading || !_hasMorePages) return;
    
    _currentPage++;
    await loadPopularShows(refresh: false, user: user);
  }

  /// Scores shows based on relevance to user preferences.
  /// Parity with MovieProvider: adds actor/director scoring, cross-features,
  /// real embedding similarity, and improved base-weight distribution.
  Future<List<TvShow>> _scoreShows(
    List<TvShow> shows,
    UserPreferences preferences,
    User user,
    String variant,
  ) async {
    final swScoreShowsTotal = Stopwatch()..start();
    final scoredShows = <_ScoredShow>[];

    final userLikedShowItemIds = <int>{};
    for (final id in user.likedShows) {
      final v = int.tryParse(id);
      if (v != null) userLikedShowItemIds.add(showItemId(v));
    }

    // Get current context
    final currentTime = DateTime.now();
    final currentMoods = _swipeMoods;

    // A/B Testing: Adjust MF weight based on variant
    double mfWeightMultiplier = 0.15;
    if (variant == ABTestingService.variantC) {
      mfWeightMultiplier = 0.25;
    } else if (variant == ABTestingService.variantB) {
      mfWeightMultiplier = 0.20;
    }

    // ── Credits fetch for actor/director scoring (top 20 shows only) ──────────
    final creditsCache = <int, Map<String, dynamic>>{};
    final showsToVerify = shows.take(20).toList();
    final creditFutures = <Future<void>>[];
    for (final show in showsToVerify) {
      final cached = _showCreditsSessionCache[show.id];
      if (cached != null) {
        creditsCache[show.id] = cached;
      } else {
        creditFutures.add(() async {
          try {
            final credits = await _tmdbService.getShowCredits(show.id);
            _showCreditsSessionCache[show.id] = credits;
            creditsCache[show.id] = credits;
          } catch (_) {}
        }());
      }
    }
    try {
      await Future.wait(creditFutures, eagerError: false)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      debugPrint('ShowProvider: Credits fetch timeout — continuing with partial data');
    }

    // Experienced-user boost: >10 likes → lean harder on cast/crew signal
    final isExperienced = user.likedShows.length > 10;
    final castBoost = isExperienced ? 1.25 : 1.0;

    for (final show in shows) {
      double score = 0.0;

      // ── Base scoring components ────────────────────────────────────────────
      double genreScore = 0.0;
      double actorScore = 0.0;
      double creatorScore = 0.0;
      double ratingScore = 0.0;
      double recencyScore = 0.0;
      double qualityScore = 0.0;
      double temporalScore = 0.0;
      double crossFeatureScore = 0.0;

      // Genre match (normalized)
      if (show.genreIds != null && preferences.topGenres.isNotEmpty) {
        final matching = show.genreIds!
            .where((id) => preferences.topGenres.contains(id))
            .length;
        genreScore = (matching / preferences.topGenres.length).clamp(0.0, 1.0);
      }

      // Actor match — verify via TMDB credits (same approach as movies)
      if (preferences.preferredActors.isNotEmpty &&
          creditsCache.containsKey(show.id)) {
        try {
          final credits = creditsCache[show.id]!;
          final cast = credits['cast'] as List;
          final castNames = cast
              .take(15)
              .map((a) => (a['name'] as String?)?.toLowerCase() ?? '')
              .toSet();
          final matchingActors = preferences.preferredActors
              .where((a) => castNames.contains(a.toLowerCase()))
              .length;
          actorScore = (matchingActors / preferences.preferredActors.length)
              .clamp(0.0, 1.0);
        } catch (_) {}
      }

      // Creator/director match — use show crew or created_by from credits
      if (preferences.preferredDirectors.isNotEmpty &&
          creditsCache.containsKey(show.id)) {
        try {
          final credits = creditsCache[show.id]!;
          final crew = credits['crew'] as List;
          final creatorJobs = {'Creator', 'Executive Producer', 'Showrunner'};
          final creatorNames = crew
              .where((c) => creatorJobs.contains(c['job'] as String?))
              .map((c) => (c['name'] as String?)?.toLowerCase() ?? '')
              .toSet();
          final matchingCreators = preferences.preferredDirectors
              .where((d) => creatorNames.contains(d.toLowerCase()))
              .length;
          creatorScore =
              (matchingCreators / preferences.preferredDirectors.length)
                  .clamp(0.0, 1.0);
        } catch (_) {}
      }

      // Rating score
      if (show.voteAverage != null && preferences.preferredMinRating != null) {
        final rating = show.voteAverage!;
        final preferredMin = preferences.preferredMinRating!;
        final preferredMax = preferences.preferredMaxRating ?? 10.0;
        if (rating >= preferredMin && rating <= preferredMax) {
          ratingScore = 1.0;
        } else {
          final distance = rating < preferredMin
              ? preferredMin - rating
              : rating - preferredMax;
          ratingScore = (1.0 - (distance / 5.0)).clamp(0.0, 1.0);
        }
      } else if (show.voteAverage != null) {
        ratingScore = (show.voteAverage! / 10.0).clamp(0.0, 1.0);
      }

      // Recency score
      if (show.year != null) {
        final showYear = int.tryParse(show.year!);
        if (showYear != null) {
          final yearsAgo = DateTime.now().year - showYear;
          if (yearsAgo == 0) {
            recencyScore = 1.0;
          } else if (yearsAgo == 1) {
            recencyScore = 0.95;
          } else if (yearsAgo == 2) {
            recencyScore = 0.85;
          } else if (yearsAgo <= 5) {
            recencyScore = 0.7;
          } else if (yearsAgo <= 10) {
            recencyScore = 0.5;
          } else if (yearsAgo <= 15) {
            recencyScore = 0.3;
          } else {
            recencyScore = 0.1;
          }
        }
      }
      if (show.popularity != null && show.popularity! > 0) {
        final normalizedPopularity = (show.popularity! / 100.0).clamp(0.0, 1.0);
        recencyScore = (recencyScore * 0.7) + (normalizedPopularity * 0.3);
        recencyScore = recencyScore.clamp(0.0, 1.0);
      }

      // Quality score (external ratings if available, else TMDB)
      double? externalQualityScore;
      if (show.imdbRating != null || show.rottenTomatoesTomatometer != null) {
        final scores = <double>[];
        final weights = <double>[];
        if (show.imdbRating != null) {
          scores.add((show.imdbRating! / 10.0).clamp(0.0, 1.0));
          weights.add(0.40);
        }
        if (show.rottenTomatoesTomatometer != null) {
          scores.add((show.rottenTomatoesTomatometer! / 100.0).clamp(0.0, 1.0));
          weights.add(0.30);
        }
        if (show.rottenTomatoesAudienceScore != null) {
          scores.add(
              (show.rottenTomatoesAudienceScore! / 100.0).clamp(0.0, 1.0));
          weights.add(0.20);
        }
        if (show.voteAverage != null) {
          scores.add((show.voteAverage! / 10.0).clamp(0.0, 1.0));
          weights.add(0.10);
        }
        if (scores.isNotEmpty) {
          final totalWeight = weights.fold(0.0, (s, w) => s + w);
          if (totalWeight > 0) {
            double ws = 0.0;
            for (int i = 0; i < scores.length; i++) {
              ws += scores[i] * (weights[i] / totalWeight);
            }
            externalQualityScore = ws;
          }
        }
      }
      if (externalQualityScore != null) {
        qualityScore = externalQualityScore;
        if (show.voteCount != null) {
          final logVC = show.voteCount! > 0
              ? (math.log(show.voteCount! + 1) / math.log(10000))
              : 0.0;
          final normPop = show.popularity != null
              ? (show.popularity! / 200.0).clamp(0.0, 1.0)
              : 0.0;
          qualityScore = (qualityScore * 0.80) +
              ((logVC.clamp(0.0, 1.0) * 0.5 + normPop * 0.5) * 0.20);
        }
      } else if (show.voteAverage != null && show.voteCount != null) {
        final normalizedRating = (show.voteAverage! / 10.0).clamp(0.0, 1.0);
        final logVC = show.voteCount! > 0
            ? (math.log(show.voteCount! + 1) / math.log(10000))
            : 0.0;
        final normPop = show.popularity != null
            ? (show.popularity! / 200.0).clamp(0.0, 1.0)
            : 0.0;
        qualityScore = (normalizedRating * 0.60) +
            (logVC.clamp(0.0, 1.0) * 0.25) +
            (normPop * 0.15);
      } else if (show.voteAverage != null) {
        qualityScore = (show.voteAverage! / 10.0).clamp(0.0, 1.0);
      }

      // Temporal score
      final hour = currentTime.hour;
      if (hour >= 6 && hour < 12) {
        if (show.genreIds != null) {
          if (show.genreIds!.contains(35)) temporalScore += 0.3; // Comedy
          if (show.genreIds!.contains(16)) temporalScore += 0.2; // Animation
        }
      } else if (hour >= 17 && hour < 22) {
        if (show.genreIds != null) {
          if (show.genreIds!.contains(18)) temporalScore += 0.3; // Drama
          if (show.genreIds!.contains(28)) temporalScore += 0.2; // Action
        }
      }
      temporalScore = temporalScore.clamp(0.0, 1.0);

      // Cross-feature interactions (mirrors movie cross-features)
      if (show.genreIds != null) {
        // Timeless genres: Drama + Comedy
        if (show.genreIds!.any((id) => id == 18 || id == 35)) {
          crossFeatureScore += 0.1;
        }
        // Sci-Fi/Action + recent (≤3 years)
        final showYear = show.year != null ? int.tryParse(show.year!) : null;
        if (showYear != null &&
            DateTime.now().year - showYear <= 3 &&
            show.genreIds!.any((id) => id == 878 || id == 28 || id == 10759)) {
          crossFeatureScore += 0.2;
        }
      }
      // High rating + credible vote count
      if (show.voteAverage != null &&
          show.voteAverage! >= 7.5 &&
          (show.voteCount ?? 0) >= 500) {
        crossFeatureScore += 0.3;
      }
      crossFeatureScore = crossFeatureScore.clamp(0.0, 1.0);

      // ── Base score with new weight distribution ────────────────────────────
      // genre 22%, actor 15%, creator 10%, rating 14%, recency 6%,
      // quality 16%, temporal 9%, cross-feature 8%  (sums to 100%)
      final baseScore =
          (genreScore * 0.22) +
          (actorScore * castBoost * 0.15) +
          (creatorScore * castBoost * 0.10) +
          (ratingScore * 0.14) +
          (recencyScore * 0.06) +
          (qualityScore * 0.16) +
          (temporalScore * 0.09) +
          (crossFeatureScore * 0.08);

      // ── Adaptive weights ───────────────────────────────────────────────────
      final adaptiveWeights = _adaptiveWeighting.getContextualWeights(
        user: user,
        likedMoviesCount: user.likedShows.length,
        hasRecentActivity:
            _behaviorService.getInterestScore(showItemId(show.id)) > 0,
      );

      // Content-based score
      final contentContribution = baseScore * adaptiveWeights['contentBased']!;
      score = contentContribution;

      // Contextual (mood + time)
      double contextualContribution = 0;
      if (show.genreIds != null && show.genreIds!.isNotEmpty) {
        double contextualWeight = 0.5;
        for (final mood in currentMoods) {
          if (show.genreIds!.any((id) => mood.preferredGenres.contains(id))) {
            contextualWeight += 0.2;
          }
        }
        contextualContribution =
            adaptiveWeights['contextual']! * contextualWeight.clamp(0.0, 1.0);
        score += contextualContribution;
      }

      // Behavior weight
      final behaviorWeight =
          _behaviorService.getBehaviorWeight(showItemId(show.id));
      final behaviorContribution = adaptiveWeights['behavior']! * behaviorWeight;
      score += behaviorContribution;

      // Embedding — genre-profile matching (replaces flat 0.5 stub)
      final embeddingWeight = _computeShowEmbeddingScore(show, preferences);
      final embeddingContribution =
          adaptiveWeights['embedding']! * embeddingWeight;
      score += embeddingContribution;

      // Collaborative filtering
      final collaborativeWeight = _collaborativeService.getCollaborativeWeight(
        showItemId(show.id),
        userLikedShowItemIds,
      );
      final collaborativeContribution =
          adaptiveWeights['collaborative']! * collaborativeWeight;
      score += collaborativeContribution;

      // Attribute this show to its top-contributing strategy for weight training.
      _itemDominantStrategy[show.id] = _dominantStrategy({
        'contentBased': contentContribution,
        'contextual': contextualContribution,
        'behavior': behaviorContribution,
        'embedding': embeddingContribution,
        'collaborative': collaborativeContribution,
      });

      // Matrix Factorization
      final mfWeight =
          _mfService.getMatrixFactorizationWeight(user.id, showItemId(show.id));
      score += mfWeightMultiplier * mfWeight;

      // Novelty boost: surface high-quality shows outside user's top-3 genres
      if ((show.voteAverage ?? 0.0) >= 7.8 && preferences.topGenres.length >= 3) {
        final top3 = preferences.topGenres.take(3).toSet();
        final hasOverlap = show.genreIds?.any((g) => top3.contains(g)) ?? false;
        if (!hasOverlap) score += 0.08;
      }

      scoredShows.add(_ScoredShow(show: show, score: score));
    }

    // Sort by score
    scoredShows.sort((a, b) => b.score.compareTo(a.score));
    swScoreShowsTotal.stop();
    _logPerf('_scoreShows total (${shows.length} candidates)', swScoreShowsTotal);

    final scoredShowList = scoredShows.map((sm) => sm.show).toList();

    // Track metrics (async)
    _trackRecommendationMetrics(scoredShowList, user);
    _trackABTestMetrics(scoredShowList, user, variant);

    return scoredShowList;
  }

  /// Profile-matching embedding for shows.
  /// Computes a 0–1 similarity between the show's metadata profile and the
  /// user's preference profile derived from `UserPreferences`.
  /// This replaces the flat 0.5 neutral stub, giving genuine signal.
  double _computeShowEmbeddingScore(TvShow show, UserPreferences prefs) {
    // Genre alignment (how well show genres match user's top genres)
    double genreMatch = 0.0;
    if (show.genreIds != null && prefs.topGenres.isNotEmpty) {
      final matching =
          show.genreIds!.where((g) => prefs.topGenres.contains(g)).length;
      genreMatch = (matching / prefs.topGenres.length).clamp(0.0, 1.0);
    }

    // Rating alignment (how close the show's rating is to user's preferred range)
    double ratingMatch = 0.5; // neutral if no data
    if (show.voteAverage != null) {
      final rating = show.voteAverage!;
      final prefMin = prefs.preferredMinRating ?? 6.0;
      final prefMax = prefs.preferredMaxRating ?? 9.0;
      final prefMid = (prefMin + prefMax) / 2.0;
      ratingMatch =
          (1.0 - ((rating - prefMid).abs() / 5.0)).clamp(0.0, 1.0);
    }

    // Weighted combination: genre is the dominant signal
    return (genreMatch * 0.65) + (ratingMatch * 0.35);
  }

  /// Tracks recommendation metrics for evaluation
  void _trackRecommendationMetrics(List<TvShow> recommendations, User user) {
    Future.microtask(() async {
      try {
        // Note: Metrics service works with Movie, but we can track show IDs
        // For now, we'll skip detailed metrics for shows
        debugPrint('Show recommendations tracked: ${recommendations.length} shows');
      } catch (e) {
        debugPrint('Error tracking show metrics: $e');
      }
    });
  }

  /// Tracks A/B test metrics for variant comparison
  void _trackABTestMetrics(List<TvShow> recommendations, User user, String variant) {
    Future.microtask(() async {
      try {
        final metric = recommendations.length.toDouble();
        await _abTestingService.recordMetric(variant, metric);
      } catch (e) {
        debugPrint('Error tracking A/B test metrics for shows: $e');
      }
    });
  }

  /// Applies diversity filter to avoid clustering similar shows.
  /// Matches movie provider behaviour: top-20% of ranked shows always bypass
  /// the filter, window size is 5 (was 3), minimum 10 shows always returned.
  List<TvShow> _applyDiversityFilter(List<TvShow> shows) {
    if (shows.isEmpty) return shows;
    if (shows.length <= 15) return shows;

    const minShowsToKeep = 10;
    // Top 20% of ranked shows are always included regardless of genre overlap
    final topTierCutoff = (shows.length * 0.20).ceil();

    final diverseShows = <TvShow>[];
    final recentGenres = <List<int>>[];

    for (int index = 0; index < shows.length; index++) {
      final show = shows[index];
      bool shouldAdd = true;

      // Top-tier shows (first 20% by rank) always pass through
      if (index < topTierCutoff) {
        diverseShows.add(show);
        if (show.genreIds != null) {
          recentGenres.add(show.genreIds!);
          if (recentGenres.length > 5) recentGenres.removeAt(0);
        }
        continue;
      }

      if (show.genreIds != null && diverseShows.length >= 3) {
        final showGenres = show.genreIds!.toSet();
        int recentOverlaps = 0;
        for (final recentGenreList in recentGenres) {
          final overlap = showGenres.intersection(recentGenreList.toSet()).length;
          if (overlap >= 2) recentOverlaps++;
        }
        // Only skip if last 5 shows all overlap AND we're above the minimum
        if (recentOverlaps >= 3 && diverseShows.length >= minShowsToKeep) {
          shouldAdd = false;
        }
      }

      if (shouldAdd) {
        diverseShows.add(show);
        if (show.genreIds != null) {
          recentGenres.add(show.genreIds!);
          if (recentGenres.length > 5) recentGenres.removeAt(0);
        }
      }
    }

    if (diverseShows.length < minShowsToKeep && shows.length >= minShowsToKeep) {
      return shows.take(minShowsToKeep).toList();
    }

    return diverseShows;
  }
}
