import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/mood.dart';
import '../../models/user.dart';
import '../../models/streaming_platform.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import '../../services/user_preference_analyzer.dart';
import '../../services/discover_movie_list_cache.dart';
import '../../services/behavior_tracking_service.dart';
import '../../services/collaborative_filtering_service.dart';
import '../../services/online_learning_service.dart';
import '../../utils/recommendation_item_id_utils.dart';
import '../../models/social_activity.dart';
import '../../providers/social_provider.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';
import '../../widgets/discover_undo_snackbar.dart';
import '../../widgets/retro_cinema_movie_card.dart';
import '../../widgets/retro_cinema_show_card.dart';
import '../../widgets/match_success_screen.dart';
import '../../widgets/movie_quick_peek.dart';
import '../../widgets/swipe_gesture_hints.dart';

part 'discover_filter_sheets.dart';

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

  /// Last front-card ids we recorded a view for, so behaviour tracking fires
  /// once per card instead of on every deck rebuild / animation frame.
  int? _lastTrackedFrontMovieId;
  int? _lastTrackedFrontShowId;

  static const int _swipePreloadRemainingThreshold = 10;
  static const Duration _swipePreloadMinInterval = Duration(seconds: 3);
  static const Duration _lowDeckRefreshMinInterval = Duration(seconds: 8);
  /// Keys to force CardSwiper to reset to first card after refresh
  Key _moviesSwiperKey = const ValueKey('movies_0');
  Key _showsSwiperKey = const ValueKey('shows_0');

  /// Bumped to cancel pending match overlays when a new swipe or undo happens.
  int _movieSwipeEpoch = 0;
  int _showSwipeEpoch = 0;

  // ── Inline undo overlay state ──────────────────────────────────────────────
  // Movies
  Movie?                _pendingRemovedMovie;
  CardSwiperDirection?  _pendingMovieDirection;
  Timer?                _movieUndoTimer;
  bool                  _showMovieUndoBanner = false;
  // Shows
  TvShow?               _pendingRemovedShow;
  CardSwiperDirection?  _pendingShowDirection;
  Timer?                _showUndoTimer;
  bool                  _showShowUndoBanner = false;

  // ── Gesture hints overlay ──────────────────────────────────────────────────
  bool _showGestureHints = false;

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

    if (mounted) {
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
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
    // Defer movie loading until after screen renders to prevent freezing.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Restore persisted Discover filters before the first deck load so the
      // initial recommendations respect saved moods/genres/platforms.
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      await movieProvider.loadPersistedSwipeFilters();
      await showProvider.loadPersistedSwipeFilters();
      if (!mounted) return;
      _loadMovies();
      // INFINITE SWIPE: Start periodic buffer check to maintain seamless experience
      _startBufferMaintenance();
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
    _movieUndoTimer?.cancel();
    _showUndoTimer?.cancel();
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
    _tabController.dispose();
    _movieSwiperController.dispose();
    _showSwiperController.dispose();
    super.dispose();
  }

  /// Wraps the swiper in a keyed subtree so it can be remounted on undo.
  /// Directional affordances live in the MATCH button (above the card) and the
  /// NOPE/SKIP/LIKE action row (below it) — each PNG embeds its swipe arrow.
  Widget _buildSwipeArea({
    required Key swiperKey,
    required Widget swiper,
  }) {
    return KeyedSubtree(key: swiperKey, child: swiper);
  }

  void _bumpMovieSwipeEpoch() => _movieSwipeEpoch++;

  void _bumpShowSwipeEpoch() => _showSwipeEpoch++;

  // ── Card-framing action buttons ─────────────────────────────────────────────
  // The deck is framed in a cross: rectangular MATCH on top, circular NOPE on
  // the left edge, circular LIKE on the right edge, rectangular SKIP below the
  // card. Each PNG embeds its swipe-direction arrow. The edge buttons are
  // siblings of the swiper in the tab Stack, so they stay fixed while cards
  // swipe underneath.

  /// Rectangular MATCH badge (cropped ADMIT ONE ticket) at the top-center.
  Widget _buildMatchButton(VoidCallback onTap) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: _RectActionButton(
          leadingIcon: Icons.local_activity,
          label: 'MATCH',
          trailingIcon: Icons.keyboard_arrow_up_rounded,
          fillColor: AppTheme.cinemaRed,
          borderColor: AppTheme.popcornGold,
          foregroundColor: AppTheme.popcornGold,
          onTap: onTap,
        ),
      ),
    );
  }

  /// Circular NOPE button straddling the card's left edge, vertically centered.
  Widget _buildNopeButton(VoidCallback onTap) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: _SwipeActionButton(
          assetPath: 'assets/swipe/swipe_left.png',
          label: null,
          color: AppTheme.nopeRed,
          size: 64,
          onTap: onTap,
        ),
      ),
    );
  }

  /// Circular LIKE button straddling the card's right edge, vertically centered.
  Widget _buildLikeButton(VoidCallback onTap) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: _SwipeActionButton(
          assetPath: 'assets/swipe/swipe_right.png',
          label: null,
          color: AppTheme.likeGreen,
          size: 64,
          onTap: onTap,
        ),
      ),
    );
  }

  /// Rectangular SKIP badge (cropped "SKIP ↓") centered below the card.
  Widget _buildSkipButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: _RectActionButton(
          leadingIcon: Icons.content_cut,
          label: 'SKIP',
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          fillColor: AppTheme.filmStripBlack.withValues(alpha: 0.9),
          borderColor: AppTheme.sepiaBrown,
          foregroundColor: AppTheme.creamyWhite,
          onTap: onTap,
        ),
      ),
    );
  }

  // ── Deferred removal helpers ──────────────────────────────────────────────

  /// Clears the pending-undo banner/timer for movies. Removal is immediate on
  /// swipe (see the swipe handler), so there is nothing to commit here — this
  /// just hides the banner and drops the undo reference.
  void _clearMoviePendingUndo() {
    _movieUndoTimer?.cancel();
    _pendingRemovedMovie = null;
    _pendingMovieDirection = null;
    if (mounted) setState(() => _showMovieUndoBanner = false);
  }

  /// Rolls back the last movie swipe: reverses auth state and re-inserts the
  /// swiped card at the front of the deck. Removal is immediate on swipe (so
  /// rapid consecutive swipes always advance to the correct next card), so undo
  /// must restore the card via [MovieProvider.reinsertSwipedMovieAtFront] rather
  /// than the unreliable `controller.undo()` path.
  void _undoLastMovieSwipe() {
    _movieUndoTimer?.cancel();
    final movie = _pendingRemovedMovie;
    final dir = _pendingMovieDirection;
    _pendingRemovedMovie = null;
    _pendingMovieDirection = null;

    if (movie != null && dir != null && mounted) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (dir == CardSwiperDirection.right) {
        unawaited(authProvider.removeLikedMovie(movie.id.toString()));
      } else if (dir == CardSwiperDirection.left) {
        unawaited(authProvider.removeDislikedMovie(movie.id.toString()));
      }
      movieProvider.reinsertSwipedMovieAtFront(movie);
      setState(() {
        _showMovieUndoBanner = false;
        _moviesSwiperKey =
            ValueKey('movies_undo_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
    } else if (mounted) {
      setState(() => _showMovieUndoBanner = false);
    }
  }

  /// Show counterpart of [_clearMoviePendingUndo].
  void _clearShowPendingUndo() {
    _showUndoTimer?.cancel();
    _pendingRemovedShow = null;
    _pendingShowDirection = null;
    if (mounted) setState(() => _showShowUndoBanner = false);
  }

  /// Rolls back the last show swipe. Mirrors [_undoLastMovieSwipe].
  void _undoLastShowSwipe() {
    _showUndoTimer?.cancel();
    final show = _pendingRemovedShow;
    final dir = _pendingShowDirection;
    _pendingRemovedShow = null;
    _pendingShowDirection = null;

    if (show != null && dir != null && mounted) {
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (dir == CardSwiperDirection.right) {
        unawaited(authProvider.removeLikedShow(show.id.toString()));
      } else if (dir == CardSwiperDirection.left) {
        unawaited(authProvider.removeDislikedShow(show.id.toString()));
      }
      showProvider.reinsertSwipedShowAtFront(show);
      setState(() {
        _showShowUndoBanner = false;
        _showsSwiperKey =
            ValueKey('shows_undo_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
    } else if (mounted) {
      setState(() => _showShowUndoBanner = false);
    }
  }

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

  bool _onMoviesUndo(
    int? indexAfterSwipe,
    int restoredFrontIndex,
    CardSwiperDirection direction,
  ) {
    // Auth rollback is handled by _undoLastMovieSwipe before controller.undo()
    // is called, so nothing extra needed here.
    if (!mounted) return false;
    _movieSwipeEpoch++;
    return true;
  }

  bool _onShowsUndo(
    int? indexAfterSwipe,
    int restoredFrontIndex,
    CardSwiperDirection direction,
  ) {
    // Auth rollback is handled by _undoLastShowSwipe before controller.undo()
    // is called, so nothing extra needed here.
    if (!mounted) return false;
    _showSwipeEpoch++;
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

  /// Smart empty state shown when active filters produce zero results.
  Widget _buildFilteredEmptyState({
    required IconData icon,
    required List moods,
    required List genres,
    required List platforms,
    required VoidCallback onRelax,
  }) {
    final String message;
    if (platforms.isNotEmpty && genres.isEmpty && moods.isEmpty) {
      message =
          'No titles found on your selected platforms.\nTry adding more platforms or clearing the platform filter.';
    } else if (genres.isNotEmpty && platforms.isEmpty && moods.isEmpty) {
      message =
          'No titles found in your selected genres.\nTry broadening your genre filter.';
    } else if (moods.isNotEmpty && genres.isEmpty && platforms.isEmpty) {
      message =
          'No titles match this mood.\nTry a different mood or clear the mood filter.';
    } else {
      message =
          'No titles match your current filters.\nTry relaxing some filters to see more results.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64,
                color: AppTheme.filmStripBlack.withValues(alpha: 50)),
            const SizedBox(height: 16),
            Text(
              context.l10n.nothingHereLabel,
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRelax,
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: Text(context.l10n.relaxFiltersButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cinemaRed,
                foregroundColor: AppTheme.warmCream,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
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

    // Determine which cache key to use based on current auth state
    final user = authProvider.userData;
    final analyzer = UserPreferenceAnalyzer();
    final cacheKey = (user != null && analyzer.hasEnoughData(user))
        ? DiscoverMovieListCache.keyPersonalized
        : DiscoverMovieListCache.keyCurated;

    // Try to show cached cards immediately (no spinner, no network wait)
    final gotCache = await movieProvider.loadCachedMoviesInstant(
        cacheKey: cacheKey, user: user);

    if (!mounted) return;

    if (gotCache) {
      // Cached cards are visible — reset swiper and show them right away
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });

      // Apply user filters without waiting (they were already applied to cache)
      _applyUserFiltersToProvider(movieProvider, user);

      // Refresh in background; new movies arrive via _pendingMovies without disrupting the deck
      unawaited(_doNetworkRefresh(movieProvider, user, backgroundLoad: true));

      _maybeShowGestureHints();
      return;
    }

    // No cache — first session or expired. Wait for auth if still loading.
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    // Re-read user after potential auth wait
    final resolvedUser = authProvider.userData;
    _applyUserFiltersToProvider(movieProvider, resolvedUser);
    await _doNetworkRefresh(movieProvider, resolvedUser, backgroundLoad: false);

    if (mounted) {
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
    }

    _maybeShowGestureHints();
  }

  /// Applies platform/genre filters from the user's saved preferences to [movieProvider].
  void _applyUserFiltersToProvider(MovieProvider movieProvider, User? user) {
    if (user == null) return;
    final selectedPlatforms =
        user.preferences['selectedPlatforms'] as List<dynamic>?;
    if (selectedPlatforms != null &&
        selectedPlatforms.isNotEmpty &&
        movieProvider.swipeSelectedPlatforms.isEmpty) {
      final normalized = selectedPlatforms
          .map((p) => p.toString().trim())
          .expand((s) {
            if (StreamingPlatform.getById(s) != null) return [s];
            return StreamingPlatform.availablePlatforms
                .where((p) => p.name.toLowerCase() == s.toLowerCase())
                .map((p) => p.id);
          })
          .toSet()
          .toList();
      movieProvider.setSwipePlatforms(normalized);
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
  }

  /// Runs the appropriate network load (personalized or curated) and schedules
  /// the buffer-maintenance preload timer afterward.
  Future<void> _doNetworkRefresh(
    MovieProvider movieProvider,
    User? user, {
    required bool backgroundLoad,
  }) async {
    final analyzer = UserPreferenceAnalyzer();
    if (user != null) {
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(
          user,
          refresh: true,
          backgroundLoad: backgroundLoad,
        );
      } else {
        await movieProvider.loadCuratedStarterMovies(
            refresh: true, user: user);
      }
      _scheduleTimer(const Duration(milliseconds: 500), () {
        if (mounted) movieProvider.checkAndPreload(user);
      });
    } else {
      await movieProvider.loadCuratedStarterMovies(
          refresh: true, user: null);
      _scheduleTimer(const Duration(milliseconds: 500), () {
        if (mounted) movieProvider.checkAndPreload(null);
      });
    }
  }

  Future<void> _maybeShowGestureHints() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('discover_hints_shown') ?? false;
    if (!shown && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _showGestureHints = true);
    }
  }

  Future<void> _dismissGestureHints() async {
    setState(() => _showGestureHints = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('discover_hints_shown', true);
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

          // Train adaptive weights, attributing the like to the weight-aligned
          // strategy that surfaced this movie (tracked at scoring time).
          final user = authProvider.userData;
          if (user != null) {
            movieProvider.recordSwipeFeedback(
              movieId: movie.id,
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

          // Train adaptive weights with negative feedback, attributed to the
          // weight-aligned strategy that surfaced this movie.
          final user = authProvider.userData;
          if (user != null) {
            movieProvider.recordSwipeFeedback(
              movieId: movie.id,
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
          // Match action - present the celebration immediately so it reads as
          // one continuous animation with the card flying off. The match screen
          // renders entirely from the in-hand `movie`, so nothing needs to be
          // awaited first; all persistence/tracking runs afterwards in the
          // background and never blocks the transition frame.
          final likedCountBefore =
              authProvider.userData?.likedMovies.length ?? 0;
          final userId = authProvider.userData?.id ?? '';

          if (mounted && swipeToken == _movieSwipeEpoch) {
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
                await MovieCacheService.instance.preloadMovieDetails(movie.id);

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
          }

          // Persist + track in the background (off the visible critical path).
          await authProvider.addLikedMovie(movie.id.toString());
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
      final movieProvider =
          Provider.of<MovieProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (direction == CardSwiperDirection.top) {
        // Match swipe: remove immediately (match screen drives UX), drop any
        // pending undo from a previous swipe.
        _clearMoviePendingUndo();
        movieProvider.removeMovie(swipedMovie.id, user: authProvider.userData);
      } else {
        // Remove immediately so the deck advances correctly even on rapid
        // consecutive swipes; keep the swiped card for one-tap UNDO. The
        // keyed CardSwiper remounts onto the new front when the list changes.
        _movieUndoTimer?.cancel();
        movieProvider.removeMovie(swipedMovie.id, user: authProvider.userData);
        _pendingRemovedMovie = swipedMovie;
        _pendingMovieDirection = direction;
        setState(() => _showMovieUndoBanner = true);
        _movieUndoTimer = Timer(const Duration(seconds: 4), () {
          _clearMoviePendingUndo();
        });
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
  String? _resolveFriendLabel(Movie movie, List<SocialActivity> feed) {
    for (final a in feed) {
      if (a.itemId == movie.id.toString() &&
          a.itemType == SocialItemType.movie &&
          a.activityType == SocialActivityType.liked) {
        final name = a.actorDisplayName;
        return (name != null && name.isNotEmpty) ? name : null;
      }
    }
    return null;
  }

  void _onMovieTap(Movie movie) {
    // Kick off detail preload in the background so the detail screen can use
    // cached data, but navigate immediately. The premium shared-axis (scaled)
    // transition zooms/fades the detail in with no pre-delay and leaves it
    // scrollable as soon as it settles.
    MovieCacheService.instance.preloadMovieDetails(movie.id);

    Navigator.of(context).push(
      NavigationUtils.premiumScaleRoute(MovieDetailScreen(movie: movie)),
    );
  }


  /// Refill when the deck is empty (e.g. after swiping through) — continues TMDB pages
  /// instead of [refresh: true] which resets to page 1 and replays old cards.
  Future<void> _loadMoviesContinue() async {
    if (!mounted) return;
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    final user = authProvider.userData;
    final analyzer = UserPreferenceAnalyzer();
    final cacheKey = (user != null && analyzer.hasEnoughData(user))
        ? DiscoverMovieListCache.keyPersonalized
        : DiscoverMovieListCache.keyCurated;

    final gotCache = await movieProvider.loadCachedMoviesInstant(
        cacheKey: cacheKey, user: user);

    if (!mounted) return;

    if (gotCache) {
      setState(() {
        _moviesSwiperKey =
            ValueKey('movies_${DateTime.now().millisecondsSinceEpoch}');
        _bumpMovieSwipeEpoch();
      });
      _applyUserFiltersToProvider(movieProvider, user);
      unawaited(_doNetworkRefresh(movieProvider, user, backgroundLoad: true));
      return;
    }

    _applyUserFiltersToProvider(movieProvider, user);
    final refresh = !movieProvider.discoverBootstrapComplete;
    if (user != null) {
      final a = UserPreferenceAnalyzer();
      if (a.hasEnoughData(user)) {
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
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    final user = authProvider.userData;
    final analyzer = UserPreferenceAnalyzer();
    final cacheKey = (user != null && analyzer.hasEnoughData(user))
        ? DiscoverMovieListCache.keyShowsPersonalized
        : DiscoverMovieListCache.keyShowsCurated;

    final gotCache = await showProvider.loadCachedShowsInstant(
        cacheKey: cacheKey, user: user);

    if (!mounted) return;

    if (gotCache) {
      setState(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
      _applyShowFiltersToProvider(showProvider, user);
      unawaited(_doShowNetworkRefresh(showProvider, user, backgroundLoad: true));
      return;
    }

    _applyShowFiltersToProvider(showProvider, user);
    final refresh = !showProvider.discoverBootstrapComplete;
    if (user != null) {
      final a = UserPreferenceAnalyzer();
      if (a.hasEnoughData(user)) {
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

  void _applyShowFiltersToProvider(ShowProvider showProvider, User? user) {
    if (user == null) return;
    final selectedPlatforms =
        user.preferences['selectedPlatforms'] as List<dynamic>?;
    if (selectedPlatforms != null &&
        selectedPlatforms.isNotEmpty &&
        showProvider.swipeSelectedPlatforms.isEmpty) {
      final normalized = selectedPlatforms
          .map((p) => p.toString().trim())
          .expand((s) {
            if (StreamingPlatform.getById(s) != null) return [s];
            return StreamingPlatform.availablePlatforms
                .where((p) => p.name.toLowerCase() == s.toLowerCase())
                .map((p) => p.id);
          })
          .toSet()
          .toList();
      showProvider.setSwipePlatforms(normalized, user: user);
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
    }
  }

  Future<void> _doShowNetworkRefresh(
    ShowProvider showProvider,
    User? user, {
    required bool backgroundLoad,
  }) async {
    final analyzer = UserPreferenceAnalyzer();
    if (user != null) {
      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(
          user,
          refresh: true,
          backgroundLoad: backgroundLoad,
        );
      } else {
        await showProvider.loadCuratedStarterShows(refresh: true, user: user);
      }
      _scheduleShowPreload(user);
    } else {
      await showProvider.loadCuratedStarterShows(refresh: true, user: null);
      _scheduleShowPreload(null);
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
    return Stack(
      children: [
      Scaffold(
      backgroundColor:
          AppTheme.vintagePaper, // Changed to Vintage Paper from guide
      appBar: AppBar(
        title: Text(
          context.l10n.navDiscover.toUpperCase(),
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
          tabs: [
            Tab(text: context.l10n.moviesTab),
            Tab(text: context.l10n.showsTab),
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
                          icon: Icon(
                            Icons.tune,
                            color: hasActiveFilters
                                ? AppTheme.popcornGold
                                : AppTheme.warmCream,
                          ),
                          onPressed: () => _showFilterMenu(movieProvider),
                          tooltip: context.l10n.filtersSectionTitle,
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
                          icon: Icon(
                            Icons.tune,
                            color: hasActiveFilters
                                ? AppTheme.popcornGold
                                : AppTheme.warmCream,
                          ),
                          onPressed: () => _showShowFilterMenu(showProvider),
                          tooltip: context.l10n.filtersSectionTitle,
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
        ],
      ),
      body: SafeArea(
        // Both decks stay mounted (like the app's IndexedStack tabs) so swiper
        // state survives a tab switch. We cross-fade between them instead of the
        // old TabBarView horizontal slide, which stuttered while dragging two
        // heavy CardSwiper stacks past each other. The inactive deck is faded out
        // and made non-interactive.
        child: Stack(
          children: [
            _buildCrossFadeTab(
              index: 0,
              child: _buildMoviesTab(),
            ),
            _buildCrossFadeTab(
              index: 1,
              child: _buildShowsTab(),
            ),
          ],
        ),
      ),
    ),

    // Gesture hints overlay — shown once on first Discover session
    if (_showGestureHints)
      Positioned.fill(
        child: SwipeGestureHints(onDismiss: _dismissGestureHints),
      ),
    ],
    );
  }

  /// Cross-fades one Discover tab based on [_currentTabIndex]. Both tabs stay
  /// in the tree so their swiper state is preserved; the inactive tab fades to
  /// transparent and stops receiving input. `Positioned.fill` forces each tab to
  /// fill the body the way `TabBarView` used to.
  Widget _buildCrossFadeTab({required int index, required Widget child}) {
    final bool isActive = _currentTabIndex == index;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isActive,
        child: AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: child,
        ),
      ),
    );
  }

  /// Records a behaviour-tracking view for the current front movie, deduped by
  /// id. Called from a post-frame callback (not from `cardBuilder`) so it never
  /// fires during a card's build or relayout.
  void _trackFrontMovieView(int id) {
    if (_lastTrackedFrontMovieId == id) return;
    _lastTrackedFrontMovieId = id;
    BehaviorTrackingService().recordMovieView(id);
  }

  /// Show counterpart of [_trackFrontMovieView] (keyed by [showItemId]).
  void _trackFrontShowView(int showId) {
    if (_lastTrackedFrontShowId == showId) return;
    _lastTrackedFrontShowId = showId;
    BehaviorTrackingService().recordMovieView(showItemId(showId));
  }

  /// Builds the movies tab content
  Widget _buildMoviesTab() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        if (movieProvider.filteredMovies.isEmpty) {
          if (movieProvider.isLoading || movieProvider.isPreloading) {
            return _buildSwipeLoadingState('Loading more movies...');
          }
          final hasFilters = movieProvider.swipeMoods.isNotEmpty ||
              movieProvider.swipeSelectedGenres.isNotEmpty ||
              movieProvider.swipeSelectedPlatforms.isNotEmpty;
          if (hasFilters) {
            return _buildFilteredEmptyState(
              icon: Icons.movie_outlined,
              moods: movieProvider.swipeMoods,
              genres: movieProvider.swipeSelectedGenres,
              platforms: movieProvider.swipeSelectedPlatforms,
              onRelax: () {
                movieProvider.clearSwipeFilters();
                _reloadMoviesWithFilters();
              },
            );
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
                      ? context.l10n.noMoviesFoundSwipe
                      : context.l10n.allCaughtUpLabel,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  movieProvider.hasMorePages
                      ? context.l10n.tryRefreshingMovies
                      : context.l10n.checkBackLaterNewReleases,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshMovies,
                  child: Text(context.l10n.refreshButton),
                ),
              ],
            ),
          );
        }

        // Record the front card's view once it has rendered (deduped by id),
        // instead of inside cardBuilder where it fired on every frame.
        final frontMovieId = movieProvider.filteredMovies.first.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _trackFrontMovieView(frontMovieId);
        });

        return Column(
          children: [
            // Swipe cards area with stacked cards effect
            Expanded(
              child: Container(
                color: AppTheme.vintagePaper, // Background color from guide
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _buildSwipeArea(
                    swiperKey: _moviesSwiperKey,
                    swiper: CardSwiper(
                      // Must reset swiper state when the front item is removed from the list:
                      // CardSwiper advances its index on swipe, but we also remove the swiped
                      // row from [filteredMovies], so indices shift — without this key the
                      // "next" card shows the wrong movie or appears to swap with a new fetch.
                      // Remounting clears CardSwiper undo history; see docs/DISCOVER_UNDO_PRODUCT_FIX.md.
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

                        // View tracking is recorded once per front card outside
                        // the builder (see _trackFrontMovieView) so it no longer
                        // fires on every relayout / animation frame.

                        final socialFeed = context
                            .read<SocialProvider>()
                            .friendsFeed;
                        return RetroCinemaMovieCard(
                          movie: movie,
                          friendLikedLabel:
                              _resolveFriendLabel(movie, socialFeed),
                          onTap: () {
                            final startTime = DateTime.now();
                            BehaviorTrackingService().recordDetailView(movie.id,
                                startTime: startTime);
                            _onMovieTap(movie);
                          },
                          onInfoTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => MovieQuickPeek.forMovie(
                                movie: movie,
                                onOpenDetails: () => _onMovieTap(movie),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Card-framing buttons: MATCH top, NOPE left, LIKE right
                  _buildMatchButton(() => _movieSwiperController.swipeTop()),
                  _buildNopeButton(() => _movieSwiperController.swipeLeft()),
                  _buildLikeButton(() => _movieSwiperController.swipeRight()),
                  // Undo overlay — floats above the bottom of the card stack
                  Positioned(
                    bottom: 8,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: DiscoverSwipeFeedback(
                        visible: _showMovieUndoBanner,
                        direction: _pendingMovieDirection,
                        onUndo: _undoLastMovieSwipe,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
            // SKIP (swipe-down) button below the card
            _buildSkipButton(() => _movieSwiperController.swipeBottom()),
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
          final hasFilters = showProvider.swipeMoods.isNotEmpty ||
              showProvider.swipeSelectedGenres.isNotEmpty ||
              showProvider.swipeSelectedPlatforms.isNotEmpty;
          if (hasFilters) {
            return _buildFilteredEmptyState(
              icon: Icons.tv_outlined,
              moods: showProvider.swipeMoods,
              genres: showProvider.swipeSelectedGenres,
              platforms: showProvider.swipeSelectedPlatforms,
              onRelax: () {
                showProvider.clearSwipeFilters();
                _reloadShowsWithFilters();
              },
            );
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
                      ? context.l10n.noShowsFoundSwipe
                      : context.l10n.allCaughtUpLabel,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  showProvider.hasMorePages
                      ? context.l10n.tryRefreshingShows
                      : context.l10n.checkBackLaterNewReleases,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshShows,
                  child: Text(context.l10n.refreshButton),
                ),
              ],
            ),
          );
        }

        // Record the front card's view once it has rendered (deduped by id).
        final frontShowId = showProvider.filteredShows.first.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _trackFrontShowView(frontShowId);
        });

        return Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.vintagePaper,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _buildSwipeArea(
                    swiperKey: _showsSwiperKey,
                    swiper: CardSwiper(
                      // Remount clears undo stack; see docs/DISCOVER_UNDO_PRODUCT_FIX.md.
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

                        // View tracking is recorded once per front card outside
                        // the builder (see _trackFrontShowView).

                        return RetroCinemaShowCard(
                          show: show,
                          onTap: () {
                            final startTime = DateTime.now();
                            BehaviorTrackingService().recordDetailView(
                                showItemId(show.id),
                                startTime: startTime);
                            _onShowTap(show);
                          },
                          onInfoTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => MovieQuickPeek.forShow(
                                show: show,
                                onOpenDetails: () => _onShowTap(show),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Card-framing buttons: MATCH top, NOPE left, LIKE right
                  _buildMatchButton(() => _showSwiperController.swipeTop()),
                  _buildNopeButton(() => _showSwiperController.swipeLeft()),
                  _buildLikeButton(() => _showSwiperController.swipeRight()),
                  // Undo overlay — floats above the bottom of the card stack
                  Positioned(
                    bottom: 8,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: DiscoverSwipeFeedback(
                        visible: _showShowUndoBanner,
                        direction: _pendingShowDirection,
                        onUndo: _undoLastShowSwipe,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
            // SKIP (swipe-down) button below the card
            _buildSkipButton(() => _showSwiperController.swipeBottom()),
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

            // Train adaptive weights, attributed to the weight-aligned strategy
            // that surfaced this show (tracked at scoring time).
            final user = authProvider.userData;
            if (user != null) {
              showProvider.recordSwipeFeedback(
                showId: show.id,
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
              showProvider.recordSwipeFeedback(
                showId: show.id,
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
          // Match action - present the celebration immediately so it reads as
          // one continuous animation with the card flying off. The match screen
          // renders entirely from the in-hand `show`, so nothing needs to be
          // awaited first; all persistence/tracking runs afterwards in the
          // background and never blocks the transition frame.
          final likedCountBefore =
              authProvider.userData?.likedShows.length ?? 0;
          final userId = authProvider.userData?.id ?? '';

          if (mounted && swipeToken == _showSwipeEpoch) {
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
          }

          // Persist + track in the background (off the visible critical path).
          await authProvider.addLikedShow(show.id.toString());
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
              showProvider.recordSwipeFeedback(
                showId: show.id,
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
      final showProvider =
          Provider.of<ShowProvider>(context, listen: false);
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      if (direction == CardSwiperDirection.top) {
        // Match swipe: remove immediately (match screen drives UX).
        _clearShowPendingUndo();
        showProvider.removeShow(swipedShow.id, user: authProvider.userData);
      } else {
        // Remove immediately so the deck advances correctly even on rapid
        // consecutive swipes; keep the swiped card for one-tap UNDO.
        _showUndoTimer?.cancel();
        showProvider.removeShow(swipedShow.id, user: authProvider.userData);
        _pendingRemovedShow = swipedShow;
        _pendingShowDirection = direction;
        setState(() => _showShowUndoBanner = true);
        _showUndoTimer = Timer(const Duration(seconds: 4), () {
          _clearShowPendingUndo();
        });
      }
    }

    return true;
  }

  /// Handles show card tap
  void _onShowTap(TvShow show) {
    // Navigate to show detail screen immediately with the premium shared-axis
    // (scaled) transition (no show cache service exists, so nothing to preload).
    Navigator.of(context).push(
      NavigationUtils.premiumScaleRoute(ShowDetailScreen(show: show)),
    );
  }

}

// ── Circular action button at the bottom of the swipe deck ────────────────────

class _SwipeActionButton extends StatefulWidget {
  const _SwipeActionButton({
    required this.assetPath,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String assetPath;
  // When null, only the image is rendered (no caption below).
  final String? label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<_SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<_SwipeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              widget.assetPath,
              width: widget.size,
              height: widget.size,
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 3),
              Text(
                widget.label!,
                style: TextStyle(
                  color: widget.color.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1.1,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Rectangular action button (MATCH / SKIP) ──────────────────────────────────

/// Tappable rounded-rectangle badge in the Retro Cinema chip vocabulary: a
/// motif glyph + BebasNeue label + optional direction chevron, on a themed
/// fill with a colored border. Used for MATCH (ticket) and SKIP (scissors),
/// which read better as designed rectangles than the cropped circular PNGs.
class _RectActionButton extends StatefulWidget {
  const _RectActionButton({
    required this.leadingIcon,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.onTap,
    this.trailingIcon,
  });

  final IconData leadingIcon;
  final String label;
  final IconData? trailingIcon; // direction chevron (swipe cue)
  final Color fillColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  State<_RectActionButton> createState() => _RectActionButtonState();
}

class _RectActionButtonState extends State<_RectActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.leadingIcon, color: widget.foregroundColor, size: 20),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.bebasNeue(
                  color: widget.foregroundColor,
                  fontSize: 20,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  color: widget.foregroundColor.withValues(alpha: 0.8),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
