import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../services/premium_service.dart';
import '../../widgets/premium_upsell_sheet.dart';
import '../../widgets/transparent_button_image.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';
import 'for_you_screen.dart';
import '../../widgets/discover_undo_snackbar.dart';
import '../../widgets/retro_cinema_movie_card.dart';
import '../../widgets/retro_cinema_show_card.dart';
import '../../widgets/match_success_screen.dart';
import '../../widgets/movie_quick_peek.dart';
import '../../widgets/swipe_gesture_hints.dart';
import '../../widgets/discover/discover_loading_states.dart';
import '../../widgets/discover/discover_action_buttons.dart';

part 'discover_filter_sheets.dart';
part 'discover_deck_loading.dart';
part 'discover_swipe_handlers.dart';

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

  /// `setState` is `@protected` and can't be called from the deck-loading
  /// `part` extension; this thin wrapper lets it request rebuilds.
  void _rebuild(VoidCallback fn) => setState(fn);


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
          // Premium-gated "For You" browsable surface.
          Consumer<PremiumService>(
            builder: (context, premium, _) => IconButton(
              icon: const TransparentButtonImage(
                assetPath: 'assets/buttons/vip_access_ticket_icon.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                errorWidget: Icon(Icons.workspace_premium_rounded,
                    color: AppTheme.popcornGold),
              ),
              tooltip: context.l10n.forYouTooltip,
              onPressed: () {
                if (premium.isPremium) {
                  Navigator.of(context).push(
                    NavigationUtils.fastSlideRoute(const ForYouScreen()),
                  );
                } else {
                  showPremiumUpsell(
                    context,
                    onUnlocked: () => Navigator.of(context).push(
                      NavigationUtils.fastSlideRoute(const ForYouScreen()),
                    ),
                  );
                }
              },
            ),
          ),
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
            return const DiscoverSwipeLoadingState(label: 'Loading more movies...');
          }
          final hasFilters = movieProvider.swipeMoods.isNotEmpty ||
              movieProvider.swipeSelectedGenres.isNotEmpty ||
              movieProvider.swipeSelectedPlatforms.isNotEmpty;
          if (hasFilters) {
            return DiscoverFilteredEmptyState(
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
                  MatchActionButton(onTap: () => _movieSwiperController.swipeTop()),
                  NopeActionButton(onTap: () => _movieSwiperController.swipeLeft()),
                  LikeActionButton(onTap: () => _movieSwiperController.swipeRight()),
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
            SkipActionButton(onTap: () => _movieSwiperController.swipeBottom()),
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
            return const DiscoverSwipeLoadingState(label: 'Loading more shows...');
          }
          final hasFilters = showProvider.swipeMoods.isNotEmpty ||
              showProvider.swipeSelectedGenres.isNotEmpty ||
              showProvider.swipeSelectedPlatforms.isNotEmpty;
          if (hasFilters) {
            return DiscoverFilteredEmptyState(
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
                  MatchActionButton(onTap: () => _showSwiperController.swipeTop()),
                  NopeActionButton(onTap: () => _showSwiperController.swipeLeft()),
                  LikeActionButton(onTap: () => _showSwiperController.swipeRight()),
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
            SkipActionButton(onTap: () => _showSwiperController.swipeBottom()),
          ],
        );
      },
    );
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
