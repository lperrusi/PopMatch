import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/mood.dart';
import '../../models/user.dart';
import '../../models/streaming_platform.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import '../../services/user_preference_analyzer.dart';
import '../../services/behavior_tracking_service.dart';
import '../../services/collaborative_filtering_service.dart';
import '../../services/adaptive_weighting_service.dart';
import '../../services/online_learning_service.dart';
import '../../utils/recommendation_item_id_utils.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';
import '../../widgets/retro_cinema_movie_card.dart';
import '../../widgets/retro_cinema_show_card.dart';
import '../../widgets/match_success_screen.dart';

/// Main swiping screen with Retro Cinema aesthetic
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  /// Integration/widget tests: do not start the periodic buffer timer (avoids
  /// pending timers and lets `pumpAndSettle` complete).
  @visibleForTesting
  static bool debugDisableBufferMaintenance = false;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _movieSwiperController = CardSwiperController();
  final CardSwiperController _showSwiperController = CardSwiperController();
  late TabController _tabController;
  Timer? _bufferMaintenanceTimer;
  final List<Timer> _pendingTimers = <Timer>[];
  DateTime? _lastMoviePreloadKick;
  DateTime? _lastShowPreloadKick;
  /// Throttle swipe-driven preload so we do not fetch after every swipe.
  DateTime? _lastSwipeTriggeredMoviePreload;
  DateTime? _lastSwipeTriggeredShowPreload;
  /// Debounce background refills when the deck is small (total list size).
  DateTime? _lastLowDeckMovieRefresh;
  int _currentTabIndex = 0; // 0 = Movies, 1 = Shows

  static const int _swipePreloadRemainingThreshold = 10;
  static const Duration _swipePreloadMinInterval = Duration(seconds: 3);
  static const Duration _lowDeckRefreshMinInterval = Duration(seconds: 8);
  /// Keys to force CardSwiper to reset to first card after refresh
  Key _moviesSwiperKey = const ValueKey('movies_0');
  Key _showsSwiperKey = const ValueKey('shows_0');

  /// Bumped to cancel pending match overlays when a new swipe or undo happens.
  int _movieSwipeEpoch = 0;
  int _showSwipeEpoch = 0;

  /// Reloads movies when filters change
  Future<void> _reloadMoviesWithFilters() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();

      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user,
            refresh: true);
      } else {
        await movieProvider.loadCuratedStarterMovies(refresh: true, user: user);
      }
    } else {
      await movieProvider.loadCuratedStarterMovies(refresh: true, user: null);
    }
  }

  /// Reloads shows when the show filters change.
  ///
  /// Note: show ranking uses `ShowProvider`'s internal swipe filter state
  /// (`swipeMoods`, `swipeSelectedGenres`, `swipeSelectedPlatforms`), so we must
  /// trigger a personalized/curated reload after changing them.
  Future<void> _reloadShowsWithFilters() async {
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();

      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        await showProvider.loadCuratedStarterShows(refresh: true, user: user);
      }
    } else {
      await showProvider.loadCuratedStarterShows(refresh: true, user: null);
    }

    if (mounted) {
      // Force CardSwiper to rebuild with the updated filtered list.
      setState(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Do not call refresh:true on every tab switch — that clears the deck and
        // reloads page 1, so users see titles they already swiped past.
        if (_tabController.index == 0) {
          _ensureMoviesTabContent();
        } else {
          _ensureShowsTabContent();
        }
      }
    });
    // Defer movie loading until after screen renders to prevent freezing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMovies();
        // INFINITE SWIPE: Start periodic buffer check to maintain seamless experience
        _startBufferMaintenance();
      }
    });
  }

  /// INFINITE SWIPE: Periodically checks and maintains buffer for seamless swiping
  void _startBufferMaintenance() {
    if (SwipeScreen.debugDisableBufferMaintenance) {
      return;
    }
    _bufferMaintenanceTimer?.cancel();
    _bufferMaintenanceTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted) return;

        final movieProvider = Provider.of<MovieProvider>(context, listen: false);
        final showProvider = Provider.of<ShowProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userData;

        if (_currentTabIndex == 0) {
          movieProvider.checkAndPreload(user);
        } else {
          showProvider.checkAndPreload(user);
        }
      },
    );
  }

  void _scheduleTimer(Duration duration, VoidCallback callback) {
    final timer = Timer(duration, callback);
    _pendingTimers.add(timer);
  }

  void _scheduleMoviePreload(User? user) {
    final now = DateTime.now();
    if (_lastMoviePreloadKick != null &&
        now.difference(_lastMoviePreloadKick!).inMilliseconds < 900) {
      return;
    }
    _lastMoviePreloadKick = now;
    _scheduleTimer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      movieProvider.checkAndPreload(user);
    });
  }

  void _scheduleShowPreload(User? user) {
    final now = DateTime.now();
    if (_lastShowPreloadKick != null &&
        now.difference(_lastShowPreloadKick!).inMilliseconds < 900) {
      return;
    }
    _lastShowPreloadKick = now;
    _scheduleTimer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      showProvider.checkAndPreload(user);
    });
  }

  @override
  void dispose() {
    _bufferMaintenanceTimer?.cancel();
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _tabController.dispose();
    _movieSwiperController.dispose();
    _showSwiperController.dispose();
    super.dispose();
  }

  /// One circular swipe hint (does not intercept gestures).
  Widget _swipeDirectionHintCell(String asset, String tooltip,
      {double iconSize = 46}) {
    return Tooltip(
      message: tooltip,
      child: IgnorePointer(
        child: ClipOval(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }

  /// Places up / right / down / left hints at the edges of the swipe area
  /// (aligned with swipe directions). [swiper] is typically a [CardSwiper].
  Widget _buildSwipeAreaWithEdgeHints({
    required Key swiperKey,
    required Widget swiper,
  }) {
    const iconSize = 68.0;
    const sideBand = iconSize + 22.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: KeyedSubtree(
            key: swiperKey,
            child: swiper,
          ),
        ),
        Positioned(
          top: 2,
          left: sideBand,
          right: sideBand,
          child: Center(
            child: _swipeDirectionHintCell(
              'assets/swipe/swipe_up.png',
              'Swipe up — Match',
              iconSize: iconSize,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: sideBand,
          child: Center(
            child: _swipeDirectionHintCell(
              'assets/swipe/swipe_right.png',
              'Swipe right — Like',
              iconSize: iconSize,
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          left: sideBand,
          right: sideBand,
          child: Center(
            child: _swipeDirectionHintCell(
              'assets/swipe/swipe_down.png',
              'Swipe down — Skip',
              iconSize: iconSize,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: sideBand,
          child: Center(
            child: _swipeDirectionHintCell(
              'assets/swipe/swipe_left.png',
              'Swipe left — Pass',
              iconSize: iconSize,
            ),
          ),
        ),
      ],
    );
  }

  void _bumpMovieSwipeEpoch() => _movieSwipeEpoch++;

  void _bumpShowSwipeEpoch() => _showSwipeEpoch++;

  Future<void> _onMoviesDeckEnd() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    if (!movieProvider.hasMorePages) {
      movieProvider.clearSwipeFeedStack();
      if (!mounted) return;
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
      return;
    }
    await movieProvider.refillSwipeDeckAfterEnd(authProvider.userData);
    if (!mounted) return;
    setState(() {
      _moviesSwiperKey =
          ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
      _bumpMovieSwipeEpoch();
    });
  }

  Future<void> _onShowsDeckEnd() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    if (!showProvider.hasMorePages) {
      showProvider.clearSwipeFeedStack(user: authProvider.userData);
      if (!mounted) return;
      setState(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
      return;
    }
    await showProvider.refillSwipeDeckAfterEnd(authProvider.userData);
    if (!mounted) return;
    setState(() {
      _showsSwiperKey =
          ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
      _bumpShowSwipeEpoch();
    });
  }

  void _showDiscoverUndoSnackBar(CardSwiperController swiperController) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Replace any currently visible snackbar to avoid stale controller races.
    // Calling `clearSnackBars()` + later closing an old controller can trigger
    // the `_snackBars.first == controller` assertion.
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Swipe recorded'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.popcornGold,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            swiperController.undo();
          },
        ),
      ),
    );
  }

  bool _onMoviesUndo(
    int? indexAfterSwipe,
    int restoredFrontIndex,
    CardSwiperDirection direction,
  ) {
    if (!mounted) return false;
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (restoredFrontIndex < 0 ||
        restoredFrontIndex >= movieProvider.filteredMovies.length) {
      return false;
    }

    _movieSwipeEpoch++;
    final movie = movieProvider.filteredMovies[restoredFrontIndex];

    switch (direction) {
      case CardSwiperDirection.right:
        unawaited(authProvider.removeLikedMovie(movie.id.toString()));
        break;
      case CardSwiperDirection.left:
        unawaited(authProvider.removeDislikedMovie(movie.id.toString()));
        break;
      case CardSwiperDirection.top:
        unawaited(authProvider.removeLikedMovie(movie.id.toString()));
        unawaited(authProvider.removeFromWatchlist(movie.id.toString()));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      case CardSwiperDirection.bottom:
        break;
      default:
        return false;
    }

    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    return true;
  }

  bool _onShowsUndo(
    int? indexAfterSwipe,
    int restoredFrontIndex,
    CardSwiperDirection direction,
  ) {
    if (!mounted) return false;
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (restoredFrontIndex < 0 ||
        restoredFrontIndex >= showProvider.filteredShows.length) {
      return false;
    }

    _showSwipeEpoch++;
    final show = showProvider.filteredShows[restoredFrontIndex];

    switch (direction) {
      case CardSwiperDirection.right:
        unawaited(authProvider.removeLikedShow(show.id.toString()));
        break;
      case CardSwiperDirection.left:
        unawaited(authProvider.removeDislikedShow(show.id.toString()));
        break;
      case CardSwiperDirection.top:
        unawaited(authProvider.removeLikedShow(show.id.toString()));
        unawaited(authProvider.removeFromWatchlistShow(show.id.toString()));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        break;
      case CardSwiperDirection.bottom:
        break;
      default:
        return false;
    }

    if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    return true;
  }

  /// Skeleton card for loading state: poster-shaped + title bar with shimmer.
  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.warmCream.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Container(color: AppTheme.filmStripBlack.withValues(alpha: 0.08)),
              ),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppTheme.filmStripBlack.withValues(alpha: 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared loading UI for both movies and shows tabs.
  Widget _buildSwipeLoadingState(String label) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppTheme.vintagePaper,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 420,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: Transform.scale(
                          scale: 0.92,
                          child: _buildSkeletonCard(),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.92,
                        child: _buildSkeletonCard(),
                      ),
                      _buildSkeletonCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// When returning to the Movies tab: keep the existing deck; only bootstrap if empty.
  void _ensureMoviesTabContent() {
    if (!mounted) return;
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (movieProvider.filteredMovies.isNotEmpty ||
        movieProvider.isLoading ||
        movieProvider.isPreloading) {
      final u = authProvider.userData;
      if (u != null) {
        movieProvider.refreshFilters(u);
      }
      unawaited(movieProvider.checkAndPreload(authProvider.userData));
      return;
    }
    // Empty deck: continue TMDB pagination if Discover already ran once; avoid
    // refresh:true which resets to page 1 and replays titles (incl. watchlisted).
    unawaited(_loadMoviesContinue());
  }

  /// When returning to the Shows tab: same as movies (no full refresh on tab focus).
  void _ensureShowsTabContent() {
    if (!mounted) return;
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (showProvider.filteredShows.isNotEmpty ||
        showProvider.isLoading ||
        showProvider.isPreloading) {
      final u = authProvider.userData;
      if (u != null) {
        showProvider.refreshFilters(u);
      }
      unawaited(showProvider.checkAndPreload(authProvider.userData));
      return;
    }
    unawaited(_loadShowsContinue());
  }

  /// Loads movies for swiping - deferred until after screen renders
  Future<void> _loadMovies() async {
    if (!mounted) return;

    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    if (movieProvider.shouldSkipDiscoverSwipeLoad) {
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Small delay to ensure transition completes and auth is initialized
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // Ensure auth provider is initialized (user data might still be loading)
    if (authProvider.isLoading) {
      // Wait a bit more for auth to finish loading
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    // Always check user preferences and load appropriate recommendations
    // This ensures personalized recommendations are loaded even after app restart
    if (authProvider.userData != null) {
      final user = authProvider.userData!;

      // Auto-apply streaming platforms from user preferences if not already set
      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      if (selectedPlatforms != null && selectedPlatforms.isNotEmpty) {
        final platformList =
            selectedPlatforms.map((p) => p.toString()).toList();
        // Only set if not already set (to avoid overriding manual filter changes)
        if (movieProvider.swipeSelectedPlatforms.isEmpty) {
          movieProvider.setSwipePlatforms(platformList);
        }
      }

      // Auto-apply genres from user profile (onboarding / edit preferences) so filter shows them selected by default
      final selectedGenres =
          user.preferences['selectedGenres'] as List<dynamic>?;
      if (selectedGenres != null &&
          selectedGenres.isNotEmpty &&
          movieProvider.swipeSelectedGenres.isEmpty) {
        final genreIds = selectedGenres
            .map((g) => g is int ? g : (g as num).toInt())
            .toList();
        movieProvider.setSwipeGenres(genreIds);
      }

      final analyzer = UserPreferenceAnalyzer();

      // Use the same hybrid personalized pipeline as TV shows for consistency.
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        await movieProvider.loadCuratedStarterMovies(refresh: true, user: user);
      }

      // INFINITE SWIPE: After initial load, start preloading to fill buffer
      _scheduleTimer(const Duration(milliseconds: 500), () {
        if (mounted) {
          movieProvider.checkAndPreload(user);
        }
      });
    } else {
      await movieProvider.loadCuratedStarterMovies(refresh: true, user: null);

      // INFINITE SWIPE: After initial load, start preloading to fill buffer
      _scheduleTimer(const Duration(milliseconds: 500), () {
        if (mounted) {
          movieProvider.checkAndPreload(null);
        }
      });
    }

    if (mounted) {
      // Any refresh-style load can shrink the list; reset swiper index safely.
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
    }
  }

  /// Handles movie swipe actions:
  /// - Right swipe = Like
  /// - Left swipe = Dislike
  /// - Up swipe = Match (shows match screen with options)
  /// - Down swipe = Skip (neutral action, doesn't like or dislike)
  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    // Allow left, right, up, and down swipes
    if (direction != CardSwiperDirection.left &&
        direction != CardSwiperDirection.right &&
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false; // Block other directions
    }

    Movie? swipedMovie;
    if (previousIndex >= 0) {
      _movieSwipeEpoch++;
      final swipeToken = _movieSwipeEpoch;

      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Prefetch when few cards ahead — throttled so we don't load after every swipe.
      if (currentIndex != null) {
        final totalMovies = movieProvider.filteredMovies.length;
        final remainingMovies = totalMovies - currentIndex;

        if (remainingMovies <= _swipePreloadRemainingThreshold &&
            movieProvider.hasMorePages) {
          final now = DateTime.now();
          if (_lastSwipeTriggeredMoviePreload == null ||
              now.difference(_lastSwipeTriggeredMoviePreload!) >=
                  _swipePreloadMinInterval) {
            _lastSwipeTriggeredMoviePreload = now;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                final user = authProvider.userData;
                movieProvider.checkAndPreload(
                  user,
                  estimatedRemaining: remainingMovies,
                );
              }
            });
          }
        }
      }

      if (previousIndex < movieProvider.filteredMovies.length) {
        final movie = movieProvider.filteredMovies[previousIndex];
        swipedMovie = movie;

        if (direction == CardSwiperDirection.right) {
          // Like action - add to liked movie
          final likedCountBefore =
              authProvider.userData?.likedMovies.length ?? 0;
          await authProvider.addLikedMovie(movie.id.toString());

          // Track behavior and collaborative filtering
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'like');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);

          // ENHANCED: Record feedback for adaptive weighting (strategy from discovery)
          final user = authProvider.userData;
          if (user != null) {
            AdaptiveWeightingService().recordFeedback(
              strategy: movie.recommendationStrategy ?? 'contentBased',
              liked: true,
              user: user,
            );

            // NEW: Online learning - update models in real-time
            OnlineLearningService().recordInteraction(
              userId: user.id,
              movieId: movie.id,
              action: 'like',
            );
          }

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            // One background refresh when crossing 3+ likes, not on every like up to 5.
            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedMovies.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            } else {
              _refreshRecommendationsIfNeeded();
            }
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.left) {
          // Dislike action - add to disliked movies
          await authProvider.addDislikedMovie(movie.id.toString());

          // Track behavior
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'dislike');
          CollaborativeFilteringService().recordUserDislike(userId, movie.id);

          // ENHANCED: Record negative feedback for adaptive weighting (strategy from discovery)
          final user = authProvider.userData;
          if (user != null) {
            AdaptiveWeightingService().recordFeedback(
              strategy: movie.recommendationStrategy ?? 'contentBased',
              liked: false,
              user: user,
            );

            // NEW: Online learning - update models in real-time
            OnlineLearningService().recordInteraction(
              userId: user.id,
              movieId: movie.id,
              action: 'dislike',
            );
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.bottom) {
          // Skip action - neutral, doesn't like or dislike
          // Just track the skip behavior for learning
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'skip');

          // NEW: Online learning - record skip for learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: movie.id,
              action: 'skip',
            );
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);
        } else if (direction == CardSwiperDirection.top) {
          // Match action - show match success screen with options
          final likedCountBefore =
              authProvider.userData?.likedMovies.length ?? 0;
          await authProvider.addLikedMovie(movie.id.toString());

          // Track behavior and collaborative filtering
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'match');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedMovies.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            } else {
              _refreshRecommendationsIfNeeded();
            }
          }
          movieProvider.recordSwipeForRecalc(authProvider.userData);

          await authProvider.addToWatchlist(movie.id.toString());

          // Show match success screen after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted || swipeToken != _movieSwipeEpoch) return;
            showMatchSuccessScreen(
                context,
                movie,
                showAddToWatchlistButton: false,
                autoDismissAfter: const Duration(seconds: 5),
                onContinue: () {
                  Navigator.of(context).pop();
                },
                onViewDetails: () async {
                  // Preload movie details before navigation
                  await MovieCacheService.instance
                      .preloadMovieDetails(movie.id);

                  // Replace match success screen with movie detail screen directly
                  // This avoids the delay from pop animation + push animation
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      NavigationUtils.fastSlideRoute(
                          MovieDetailScreen(movie: movie)),
                    );
                  }
                },
              );
          });
        }
      }

      if (!mounted) return true;
      final mpEnd = Provider.of<MovieProvider>(context, listen: false);
      final deckLen = mpEnd.filteredMovies.length;
      if (currentIndex == null &&
          deckLen > 0 &&
          previousIndex == deckLen - 1) {
        mpEnd.beginDiscoverRefillLoading();
      }
    }

    if (mounted && swipedMovie != null) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      movieProvider.removeMovie(swipedMovie.id, user: authProvider.userData);
    }

    if (mounted &&
        previousIndex >= 0 &&
        direction != CardSwiperDirection.top) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      if (previousIndex < movieProvider.filteredMovies.length) {
        _showDiscoverUndoSnackBar(_movieSwiperController);
      }
    }

    return true; // Allow the swipe to complete
  }

  /// Refreshes recommendations if user has enough data and we're running low on movies
  void _refreshRecommendationsIfNeeded() {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only refresh if user is logged in
    if (authProvider.userData == null) return;

    final user = authProvider.userData!;
    final analyzer = UserPreferenceAnalyzer();

    final hasEnoughData = analyzer.hasEnoughData(user);
    // Total deck size (not "cards ahead"); avoid refreshing on every swipe when
    // the list is simply small — only when truly low, with debounce.
    final deckSize = movieProvider.filteredMovies.length;

    if (!hasEnoughData || deckSize >= 6) return;

    final now = DateTime.now();
    if (_lastLowDeckMovieRefresh != null &&
        now.difference(_lastLowDeckMovieRefresh!) < _lowDeckRefreshMinInterval) {
      return;
    }
    _lastLowDeckMovieRefresh = now;

    _scheduleTimer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      movieProvider.loadPersonalizedRecommendations(
        user,
        refresh: false,
        insertAtFront: false,
        backgroundLoad: true,
      );
    });
  }

  /// Handles movie card tap to show details
  void _onMovieTap(Movie movie) async {
    // Preload movie details in the background before navigation
    // This way the detail screen can use cached data instantly
    MovieCacheService.instance.preloadMovieDetails(movie.id);

    // Small delay to allow preload to start, then navigate
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
      );
    }
  }


  /// Refill when the deck is empty (e.g. after swiping through) — continues TMDB pages
  /// instead of [refresh: true] which resets to page 1 and replays old cards.
  Future<void> _loadMoviesContinue() async {
    if (!mounted) return;
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    final refresh = !movieProvider.discoverBootstrapComplete;

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      if (selectedPlatforms != null && selectedPlatforms.isNotEmpty) {
        final platformList =
            selectedPlatforms.map((p) => p.toString()).toList();
        if (movieProvider.swipeSelectedPlatforms.isEmpty) {
          movieProvider.setSwipePlatforms(platformList);
        }
      }
      final selectedGenres =
          user.preferences['selectedGenres'] as List<dynamic>?;
      if (selectedGenres != null &&
          selectedGenres.isNotEmpty &&
          movieProvider.swipeSelectedGenres.isEmpty) {
        final genreIds = selectedGenres
            .map((g) => g is int ? g : (g as num).toInt())
            .toList();
        movieProvider.setSwipeGenres(genreIds);
      }

      final analyzer = UserPreferenceAnalyzer();
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user,
            refresh: refresh);
      } else {
        await movieProvider.loadCuratedStarterMovies(
            refresh: refresh, user: user);
      }
      _scheduleMoviePreload(user);
    } else {
      await movieProvider.loadCuratedStarterMovies(
          refresh: refresh, user: null);
      _scheduleMoviePreload(null);
    }

    if (mounted) {
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
    }
  }

  /// Same as [_loadMoviesContinue] for TV shows.
  Future<void> _loadShowsContinue() async {
    if (!mounted) return;
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    final refresh = !showProvider.discoverBootstrapComplete;

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final selectedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      if (selectedPlatforms != null && selectedPlatforms.isNotEmpty) {
        final platformList =
            selectedPlatforms.map((p) => p.toString()).toList();
        if (showProvider.swipeSelectedPlatforms.isEmpty) {
          showProvider.setSwipePlatforms(platformList, user: user);
        }
      }
      final selectedGenres =
          user.preferences['selectedGenres'] as List<dynamic>?;
      if (selectedGenres != null && selectedGenres.isNotEmpty) {
        final genreIds = selectedGenres
            .map((g) => g is int ? g : (g as num).toInt())
            .toList();
        if (showProvider.swipeSelectedGenres.isEmpty) {
          showProvider.setSwipeGenres(genreIds, user: user);
        }
        final movieProvider =
            Provider.of<MovieProvider>(context, listen: false);
        if (movieProvider.swipeSelectedGenres.isEmpty) {
          movieProvider.setSwipeGenres(genreIds);
        }
      }

      final analyzer = UserPreferenceAnalyzer();
      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(user,
            refresh: refresh);
      } else {
        await showProvider.loadCuratedStarterShows(
            refresh: refresh, user: user);
      }
      _scheduleShowPreload(user);
    } else {
      await showProvider.loadCuratedStarterShows(
          refresh: refresh, user: null);
      _scheduleShowPreload(null);
    }

    if (mounted) {
      setState(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
    }
  }

  /// Refreshes the movie list
  Future<void> _refreshMovies() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();

      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user,
            refresh: true);
      } else {
        await movieProvider.loadCuratedStarterMovies(refresh: true, user: user);
      }
    } else {
      await movieProvider.loadCuratedStarterMovies(refresh: true, user: null);
    }
    if (mounted) {
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
    }
  }

  /// Refreshes the show list
  Future<void> _refreshShows() async {
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();

      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        await showProvider.loadCuratedStarterShows(refresh: true, user: user);
      }
    } else {
      await showProvider.loadCuratedStarterShows(refresh: true, user: null);
    }
    if (mounted) {
      setState(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.vintagePaper, // Changed to Vintage Paper from guide
      appBar: AppBar(
        title: Text(
          'DISCOVER',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: AppTheme.warmCream,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.popcornGold,
          labelColor: AppTheme.warmCream,
          unselectedLabelColor: AppTheme.warmCream.withValues(alpha: 60),
          labelStyle: GoogleFonts.bebasNeue(
            fontSize: 20,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'MOVIES'),
            Tab(text: 'SHOWS'),
          ],
        ),
        actions: [
          // Filter icon with badge if filters are active
          _currentTabIndex == 0
              ? Consumer<MovieProvider>(
                  builder: (context, movieProvider, child) {
                    final hasActiveFilters =
                        movieProvider.swipeMoods.isNotEmpty ||
                            movieProvider.swipeSelectedGenres.isNotEmpty ||
                            movieProvider.swipeSelectedPlatforms.isNotEmpty;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: AppTheme.warmCream,
                          ),
                          onPressed: () => _showFilterMenu(movieProvider),
                          tooltip: 'Filters',
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.popcornGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : Consumer<ShowProvider>(
                  builder: (context, showProvider, child) {
                    final hasActiveFilters =
                        showProvider.swipeMoods.isNotEmpty ||
                            showProvider.swipeSelectedGenres.isNotEmpty ||
                            showProvider.swipeSelectedPlatforms.isNotEmpty;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: AppTheme.warmCream,
                          ),
                          onPressed: () => _showShowFilterMenu(showProvider),
                          tooltip: 'Filters',
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.popcornGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          // Refresh button
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.warmCream,
            ),
            onPressed: () {
              final isMoviesTab = _tabController.index == 0;
              if (isMoviesTab) {
                _refreshMovies();
              } else {
                _refreshShows();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe-to-switch tabs to prevent interference with card swiping
          children: [
            // Movies Tab
            _buildMoviesTab(),
            // Shows Tab
            _buildShowsTab(),
          ],
        ),
      ),
    );
  }

  /// Builds the movies tab content
  Widget _buildMoviesTab() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        if (movieProvider.filteredMovies.isEmpty) {
          if (movieProvider.isLoading || movieProvider.isPreloading) {
            return _buildSwipeLoadingState('Loading more movies...');
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 64,
                  color: AppTheme.filmStripBlack.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  movieProvider.hasMorePages
                      ? 'No movies found'
                      : "You're all caught up",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  movieProvider.hasMorePages
                      ? 'Try refreshing to load more movies'
                      : 'Check back later for new releases',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshMovies,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Swipe cards area with stacked cards effect + edge hints
            Expanded(
              child: Container(
                color: AppTheme.vintagePaper, // Background color from guide
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 16.0),
                  child: _buildSwipeAreaWithEdgeHints(
                    swiperKey: _moviesSwiperKey,
                    swiper: CardSwiper(
                      // Must reset swiper state when the front item is removed from the list:
                      // CardSwiper advances its index on swipe, but we also remove the swiped
                      // row from [filteredMovies], so indices shift — without this key the
                      // "next" card shows the wrong movie or appears to swap with a new fetch.
                      key: ValueKey<int>(
                        movieProvider.filteredMovies.first.id,
                      ),
                      controller: _movieSwiperController,
                      cardsCount: movieProvider.filteredMovies.length,
                      onSwipe: _onSwipe,
                      onEnd: _onMoviesDeckEnd,
                      onUndo: _onMoviesUndo,
                      numberOfCardsDisplayed:
                          math.min(3, movieProvider.filteredMovies.length),
                      threshold: 50, // Minimum distance to trigger swipe
                      isLoop: false,
                      duration: const Duration(
                          milliseconds: 400), // Smoother animation duration
                      scale:
                          0.92, // Scale of cards behind the front card (slightly larger for better visibility)
                      backCardOffset:
                          const Offset(0, 8), // Small vertical offset for depth
                      allowedSwipeDirection: const AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                        up: true,
                        down: true,
                      ),
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        if (index >= movieProvider.filteredMovies.length) {
                          return const SizedBox.shrink();
                        }
                        final movie = movieProvider.filteredMovies[index];

                        // Track movie view for behavior analysis
                        BehaviorTrackingService().recordMovieView(movie.id);

                        return RetroCinemaMovieCard(
                          movie: movie,
                          onTap: () {
                            // Track detail view
                            final startTime = DateTime.now();
                            BehaviorTrackingService().recordDetailView(movie.id,
                                startTime: startTime);
                            _onMovieTap(movie);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the shows tab content
  Widget _buildShowsTab() {
    return Consumer<ShowProvider>(
      builder: (context, showProvider, child) {
        if (showProvider.filteredShows.isEmpty) {
          if (showProvider.isLoading || showProvider.isPreloading) {
            return _buildSwipeLoadingState('Loading more shows...');
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv_outlined,
                  size: 64,
                  color: AppTheme.filmStripBlack.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  showProvider.hasMorePages
                      ? 'No shows found'
                      : "You're all caught up",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  showProvider.hasMorePages
                      ? 'Try refreshing to load more shows'
                      : 'Check back later for new releases',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshShows,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.vintagePaper,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 16.0),
                  child: _buildSwipeAreaWithEdgeHints(
                    swiperKey: _showsSwiperKey,
                    swiper: CardSwiper(
                      key: ValueKey<int>(
                        showProvider.filteredShows.first.id,
                      ),
                      controller: _showSwiperController,
                      cardsCount: showProvider.filteredShows.length,
                      onSwipe: _onShowSwipe,
                      onEnd: _onShowsDeckEnd,
                      onUndo: _onShowsUndo,
                      numberOfCardsDisplayed:
                          math.min(3, showProvider.filteredShows.length),
                      threshold: 50,
                      isLoop: false,
                      duration: const Duration(milliseconds: 400),
                      scale: 0.92,
                      backCardOffset: const Offset(0, 8),
                      allowedSwipeDirection: const AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                        up: true,
                        down: true,
                      ),
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        if (index >= showProvider.filteredShows.length) {
                          return const SizedBox.shrink();
                        }
                        final show = showProvider.filteredShows[index];

                        BehaviorTrackingService()
                            .recordMovieView(showItemId(show.id));

                        return RetroCinemaShowCard(
                          show: show,
                          onTap: () {
                            final startTime = DateTime.now();
                            BehaviorTrackingService().recordDetailView(
                                showItemId(show.id),
                                startTime: startTime);
                            _onShowTap(show);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handles show swipe actions
  Future<bool> _onShowSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (direction != CardSwiperDirection.left &&
        direction != CardSwiperDirection.right &&
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false;
    }

    TvShow? swipedShow;
    if (previousIndex >= 0) {
      _showSwipeEpoch++;
      final swipeToken = _showSwipeEpoch;

      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (currentIndex != null) {
        final totalShows = showProvider.filteredShows.length;
        final remainingShows = totalShows - currentIndex;

        if (remainingShows <= _swipePreloadRemainingThreshold &&
            showProvider.hasMorePages) {
          final now = DateTime.now();
          if (_lastSwipeTriggeredShowPreload == null ||
              now.difference(_lastSwipeTriggeredShowPreload!) >=
                  _swipePreloadMinInterval) {
            _lastSwipeTriggeredShowPreload = now;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                final user = authProvider.userData;
                showProvider.checkAndPreload(
                  user,
                  estimatedRemaining: remainingShows,
                );
              }
            });
          }
        }
      }

      if (previousIndex < showProvider.filteredShows.length) {
        final show = showProvider.filteredShows[previousIndex];
        swipedShow = show;

        if (direction == CardSwiperDirection.right) {
          // Like action
          final likedCountBefore =
              authProvider.userData?.likedShows.length ?? 0;
          await authProvider.addLikedShow(show.id.toString());

          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'like');
          CollaborativeFilteringService()
              .recordUserLike(userId, showItemId(show.id));

          // NEW: Online learning - update models in real-time
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'like',
            );

            // Record feedback for adaptive weighting (strategy from discovery)
            final user = authProvider.userData;
            if (user != null) {
              AdaptiveWeightingService().recordFeedback(
                strategy: show.recommendationStrategy ?? 'contentBased',
                liked: true,
                user: user,
              );
            }
          }

          final updatedUserForRefresh = authProvider.userData;
          if (updatedUserForRefresh != null &&
              likedCountBefore < 3 &&
              updatedUserForRefresh.likedShows.length >= 3) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                showProvider.loadPersonalizedRecommendations(
                  updatedUserForRefresh,
                  refresh: false,
                  insertAtFront: false,
                  backgroundLoad: true,
                );
              }
            });
          }
        } else if (direction == CardSwiperDirection.left) {
          // Dislike action
          await authProvider.addDislikedShow(show.id.toString());

          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'dislike');
          CollaborativeFilteringService().recordUserDislike(
              userId, showItemId(show.id));

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'dislike',
            );

            final user = authProvider.userData;
            if (user != null) {
              AdaptiveWeightingService().recordFeedback(
                strategy: show.recommendationStrategy ?? 'contentBased',
                liked: false,
                user: user,
              );
            }
          }
        } else if (direction == CardSwiperDirection.bottom) {
          // Skip action
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'skip');

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'skip',
            );
          }
        } else if (direction == CardSwiperDirection.top) {
          // Match action - show match success screen with options
          final likedCountBefore =
              authProvider.userData?.likedShows.length ?? 0;
          await authProvider.addLikedShow(show.id.toString());

          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(
              userId, showItemId(show.id), 'match');
          CollaborativeFilteringService()
              .recordUserLike(userId, showItemId(show.id));

          // NEW: Online learning
          if (userId.isNotEmpty) {
            OnlineLearningService().recordInteraction(
              userId: userId,
              movieId: showItemId(show.id),
              action: 'like',
            );

            final user = authProvider.userData;
            if (user != null) {
              AdaptiveWeightingService().recordFeedback(
                strategy: show.recommendationStrategy ?? 'contentBased',
                liked: true,
                user: user,
              );
            }
          }

          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);

            if (hasEnoughData &&
                likedCountBefore < 3 &&
                updatedUser.likedShows.length >= 3) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  showProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false,
                    backgroundLoad: true,
                  );
                }
              });
            }
          }

          await authProvider.addShowToWatchlist(show.id.toString());

          // Show match success screen after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted || swipeToken != _showSwipeEpoch) return;
            showShowMatchSuccessScreen(
                context,
                show,
                showAddToWatchlistButton: false,
                autoDismissAfter: const Duration(seconds: 5),
                onContinue: () {
                  Navigator.of(context).pop();
                },
                onViewDetails: () async {
                  // Replace match success screen with show detail screen directly
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      NavigationUtils.fastSlideRoute(
                          ShowDetailScreen(show: show)),
                    );
                  }
                },
              );
          });
        }
      }

      if (!mounted) return true;
      final spEnd = Provider.of<ShowProvider>(context, listen: false);
      final deckLenShows = spEnd.filteredShows.length;
      if (currentIndex == null &&
          deckLenShows > 0 &&
          previousIndex == deckLenShows - 1) {
        spEnd.beginDiscoverRefillLoading();
      }
    }

    if (mounted && swipedShow != null) {
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      showProvider.removeShow(swipedShow.id, user: authProvider.userData);
    }

    if (mounted &&
        previousIndex >= 0 &&
        direction != CardSwiperDirection.top) {
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      if (previousIndex < showProvider.filteredShows.length) {
        _showDiscoverUndoSnackBar(_showSwiperController);
      }
    }

    return true;
  }

  /// Handles show card tap
  void _onShowTap(TvShow show) async {
    // Navigate to show detail screen
    if (context.mounted) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
      );
    }
  }

  /// Shows filter menu for shows
  void _showShowFilterMenu(ShowProvider showProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (showProvider.swipeMoods.isNotEmpty ||
                    showProvider.swipeSelectedGenres.isNotEmpty ||
                    showProvider.swipeSelectedPlatforms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showProvider.clearSwipeFilters();
                      Navigator.pop(context);
                      _reloadShowsWithFilters();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFilterMenuItem(
              'Mood',
              showProvider.swipeMoods.isNotEmpty
                  ? '${showProvider.swipeMoods.length} selected'
                  : 'Select moods',
              showProvider.swipeMoods.isNotEmpty,
              () {
                Navigator.pop(context);
                _showMoodDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 12),

            _buildFilterMenuItem(
              'Genres',
              showProvider.swipeSelectedGenres.isNotEmpty
                  ? '${showProvider.swipeSelectedGenres.length} selected'
                  : 'Select genres',
              showProvider.swipeSelectedGenres.isNotEmpty,
              () {
                Navigator.pop(context);
                _showGenreDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 12),

            _buildFilterMenuItem(
              'Platform',
              showProvider.swipeSelectedPlatforms.isNotEmpty
                  ? '${showProvider.swipeSelectedPlatforms.length} selected'
                  : 'Select platforms',
              showProvider.swipeSelectedPlatforms.isNotEmpty,
              () {
                Navigator.pop(context);
                _showPlatformDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Shows mood selection dialog with multi-select support (TV shows).
  void _showMoodDialogForShows(ShowProvider showProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Moods',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeMoods.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipeMoods([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: Mood.availableMoods.length,
                    itemBuilder: (context, index) {
                      final mood = Mood.availableMoods[index];
                      final isSelected =
                          showProvider.swipeMoods.any((m) => m.id == mood.id);

                      return GestureDetector(
                        onTap: () {
                          final currentMoods = List<Mood>.from(showProvider.swipeMoods);
                          if (isSelected) {
                            currentMoods.removeWhere((m) => m.id == mood.id);
                          } else {
                            currentMoods.add(mood);
                          }
                          showProvider.setSwipeMoods(currentMoods);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.cinemaRed
                                : AppTheme.fadedCurtain,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.popcornGold
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mood.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  mood.name,
                                  style: TextStyle(
                                    color: AppTheme.warmCream,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows genre selection dialog (TV shows).
  void _showGenreDialogForShows(ShowProvider showProvider) {
    final genres = showProvider.genres;
    if (genres.isEmpty) {
      showProvider.loadGenres();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading genres...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          final genres = showProvider.genres;
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Genres',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeSelectedGenres.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipeGenres([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.entries.map((entry) {
                        final genreId = entry.key;
                        final genreName = entry.value;
                        final isSelected = showProvider
                            .swipeSelectedGenres
                            .contains(genreId);

                        return GestureDetector(
                          onTap: () {
                            final currentGenres = List<int>.from(
                                showProvider.swipeSelectedGenres);
                            if (isSelected) {
                              currentGenres.remove(genreId);
                            } else {
                              currentGenres.add(genreId);
                            }
                            showProvider.setSwipeGenres(currentGenres);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              genreName,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows platform selection dialog (TV shows).
  void _showPlatformDialogForShows(ShowProvider showProvider) {
    const platforms = StreamingPlatform.availablePlatforms;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Platforms',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeSelectedPlatforms.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipePlatforms([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: platforms.map((platform) {
                        final isSelected = showProvider
                            .swipeSelectedPlatforms
                            .contains(platform.id);

                        return GestureDetector(
                          onTap: () {
                            final currentPlatforms = List<String>.from(
                                showProvider.swipeSelectedPlatforms);
                            if (isSelected) {
                              currentPlatforms.remove(platform.id);
                            } else {
                              currentPlatforms.add(platform.id);
                            }
                            showProvider.setSwipePlatforms(currentPlatforms);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              platform.name,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows filter menu with all filter options
  void _showFilterMenu(MovieProvider movieProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (movieProvider.swipeMoods.isNotEmpty ||
                    movieProvider.swipeSelectedGenres.isNotEmpty ||
                    movieProvider.swipeSelectedPlatforms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      movieProvider.clearSwipeFilters();
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Mood filter option
            _buildFilterMenuItem(
              'Mood',
              movieProvider.swipeMoods.isNotEmpty
                  ? '${movieProvider.swipeMoods.length} selected'
                  : 'Select moods',
              movieProvider.swipeMoods.isNotEmpty,
              () {
                Navigator.pop(context);
                _showMoodDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Genre filter option
            _buildFilterMenuItem(
              'Genres',
              movieProvider.swipeSelectedGenres.isNotEmpty
                  ? '${movieProvider.swipeSelectedGenres.length} selected'
                  : 'Select genres',
              movieProvider.swipeSelectedGenres.isNotEmpty,
              () {
                Navigator.pop(context);
                _showGenreDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Platform filter option
            _buildFilterMenuItem(
              'Platform',
              movieProvider.swipeSelectedPlatforms.isNotEmpty
                  ? '${movieProvider.swipeSelectedPlatforms.length} selected'
                  : 'Select platforms',
              movieProvider.swipeSelectedPlatforms.isNotEmpty,
              () {
                Navigator.pop(context);
                _showPlatformDialog(movieProvider);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a filter menu item
  Widget _buildFilterMenuItem(
    String title,
    String subtitle,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.cinemaRed.withValues(alpha: 0.3)
              : AppTheme.fadedCurtain,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.popcornGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.warmCream,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.warmCream.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.warmCream,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows mood selection dialog with multi-select support
  void _showMoodDialog(MovieProvider movieProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Moods',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (movieProvider.swipeMoods.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          movieProvider.setSwipeMoods([]);
                          Navigator.pop(context);
                          _reloadMoviesWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: Mood.availableMoods.length,
                    itemBuilder: (context, index) {
                      final mood = Mood.availableMoods[index];
                      final isSelected =
                          movieProvider.swipeMoods.any((m) => m.id == mood.id);

                      return GestureDetector(
                        onTap: () {
                          final currentMoods =
                              List<Mood>.from(movieProvider.swipeMoods);
                          if (isSelected) {
                            currentMoods.removeWhere((m) => m.id == mood.id);
                          } else {
                            currentMoods.add(mood);
                          }
                          movieProvider.setSwipeMoods(currentMoods);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.cinemaRed
                                : AppTheme.fadedCurtain,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.popcornGold
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mood.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  mood.name,
                                  style: TextStyle(
                                    color: AppTheme.warmCream,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows genre selection dialog
  void _showGenreDialog(MovieProvider movieProvider) {
    final genres = movieProvider.genres;
    if (genres.isEmpty) {
      // Load genres if not loaded
      movieProvider.loadGenres();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading genres...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          final genres = movieProvider.genres;
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Genres',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (movieProvider.swipeSelectedGenres.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          movieProvider.setSwipeGenres([]);
                          Navigator.pop(context);
                          _reloadMoviesWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.entries.map((entry) {
                        final genreId = entry.key;
                        final genreName = entry.value;
                        final isSelected =
                            movieProvider.swipeSelectedGenres.contains(genreId);

                        return GestureDetector(
                          onTap: () {
                            final currentGenres =
                                List<int>.from(movieProvider.swipeSelectedGenres);
                            if (isSelected) {
                              currentGenres.remove(genreId);
                            } else {
                              currentGenres.add(genreId);
                            }
                            movieProvider.setSwipeGenres(currentGenres);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              genreName,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows platform selection dialog
  void _showPlatformDialog(MovieProvider movieProvider) {
    const platforms = StreamingPlatform.availablePlatforms;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Platforms',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (movieProvider.swipeSelectedPlatforms.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          movieProvider.setSwipePlatforms([]);
                          Navigator.pop(context);
                          _reloadMoviesWithFilters();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: platforms.map((platform) {
                        final isSelected = movieProvider.swipeSelectedPlatforms
                            .contains(platform.id);

                        return GestureDetector(
                          onTap: () {
                            final currentPlatforms = List<String>.from(
                                movieProvider.swipeSelectedPlatforms);
                            if (isSelected) {
                              currentPlatforms.remove(platform.id);
                            } else {
                              currentPlatforms.add(platform.id);
                            }
                            movieProvider.setSwipePlatforms(currentPlatforms);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              platform.name,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
