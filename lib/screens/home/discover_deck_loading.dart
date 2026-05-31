part of 'swipe_screen.dart';

/// Deck load/refresh/tab-content orchestration for SwipeScreen, split out of
/// swipe_screen.dart. Kept as an extension on _SwipeScreenState (same library
/// via `part`) so the move is verbatim — call sites and the swipe/undo handlers
/// are untouched.
extension _SwipeDeckLoading on _SwipeScreenState {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
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
      _rebuild(() {
        _showsSwiperKey =
            ValueKey('shows_${DateTime.now().millisecondsSinceEpoch}');
        _bumpShowSwipeEpoch();
      });
    }
  }
}
