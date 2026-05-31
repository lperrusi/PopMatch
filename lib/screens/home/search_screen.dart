import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../models/social_activity.dart';
import '../../providers/movie_provider.dart';
import '../../providers/social_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/poster_grid_skeleton.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/navigation_utils.dart';
import '../../services/tmdb_service.dart';
import '../../services/search_service.dart';
import '../../services/movie_cache_service.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late TabController _searchTabController;

  Timer? _debounce;

  // Search history
  final List<String> _searchHistory = [];

  // Resolved trending movies from friends feed
  final Map<String, Movie?> _resolvedTrendingMovies = {};

  bool get _isSearchActive =>
      _searchController.text.isNotEmpty || _searchFocusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _searchTabController = TabController(length: 2, vsync: this);

    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        context.read<SocialProvider>().searchUsers(query);
        if (SearchService.instance.isValidSearchQuery(query)) {
          _autoSearchMovies(query);
        }
      });
    } else {
      context.read<MovieProvider>().clearFilters();
    }
  }

  Future<void> _autoSearchMovies(String query) async {
    if (!mounted) return;
    await Provider.of<MovieProvider>(context, listen: false)
        .searchMovies(SearchService.instance.sanitizeQuery(query));
  }

  void _onFocusChanged() {
    setState(() {});
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchService.instance.loadSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory.clear();
        _searchHistory.addAll(history);
      });
    }
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    await SearchService.instance.addToHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (!SearchService.instance.isValidSearchQuery(query)) return;
    await _saveToHistory(query);
    if (!mounted) return;
    _searchFocusNode.unfocus();
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    await movieProvider.searchMovies(
      SearchService.instance.sanitizeQuery(query),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    context.read<MovieProvider>().clearFilters();
  }

  void _onMovieTap(Movie movie) async {
    MovieCacheService.instance.preloadMovieDetails(movie.id);
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
      );
    }
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch();
  }

  Future<void> _removeFromHistory(String query) async {
    await SearchService.instance.removeFromHistory(query);
    await _loadSearchHistory();
  }

  // ─── Trending resolution ──────────────────────────────────────────────────

  List<String> _computeTrendingIds(List<SocialActivity> feed) {
    final freq = <String, int>{};
    for (final a in feed) {
      if (a.itemType == SocialItemType.movie) {
        freq[a.itemId] = (freq[a.itemId] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }

  void _loadTrendingMoviesFromFeed(List<SocialActivity> feed) {
    final ids = _computeTrendingIds(feed);
    for (final id in ids) {
      if (_resolvedTrendingMovies.containsKey(id)) continue;
      MovieCacheService.instance.getMovieDetails(int.tryParse(id) ?? 0).then((movie) {
        if (mounted) {
          setState(() => _resolvedTrendingMovies[id] = movie);
        }
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          l10n.searchTitle.toUpperCase(),
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: AppTheme.warmCream,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _isSearchActive
                  ? _buildActiveSearchResults()
                  : _buildDiscoveryFeed(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.filmStripBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    cursorColor: AppTheme.popcornGold,
                    style: GoogleFonts.lato(color: AppTheme.warmCream),
                    decoration: InputDecoration(
                      hintText: 'Search movies, shows or people...',
                      hintStyle: GoogleFonts.lato(
                        color: AppTheme.warmCream.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchActive
                            ? AppTheme.popcornGold
                            : AppTheme.warmCream.withValues(alpha: 0.5),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: AppTheme.warmCream.withValues(alpha: 0.6)),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.filmStripBlack,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ),
              if (_isSearchActive) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _clearSearch();
                    _searchFocusNode.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lato(
                        color: AppTheme.cinemaRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  // ─── Discovery feed (idle state) ─────────────────────────────────────────

  Widget _buildDiscoveryFeed() {
    return Consumer<SocialProvider>(
      key: const ValueKey('discovery'),
      builder: (context, social, _) {
        if (social.isLoading) return _buildLoadingState();

        // Trigger trending resolution when feed is loaded
        if (social.friendsFeed.isNotEmpty) {
          _loadTrendingMoviesFromFeed(social.friendsFeed);
        }

        final hasAnyContent = social.suggestedUsers.isNotEmpty ||
            social.friendsFeed.isNotEmpty;

        if (!hasAnyContent) return _buildNoFriendsOnboarding();

        return CustomScrollView(
          slivers: [
            // Follow request banner
            if (social.incomingRequests.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildFollowRequestBanner(social),
              ),

            // Suggested people section
            SliverToBoxAdapter(
              child: _buildSectionHeader('PEOPLE YOU MIGHT LIKE'),
            ),
            SliverToBoxAdapter(
              child: social.suggestedUsers.isEmpty
                  ? _buildFindFriendsPrompt()
                  : _buildSuggestedPeopleSection(social),
            ),

            // Friends' recent activity
            if (social.friendsFeed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader("FRIENDS' RECENT ACTIVITY"),
              ),
              SliverToBoxAdapter(
                child: _buildFriendsActivitySection(social.friendsFeed),
              ),
            ],

            // Trending in your circle
            if (social.friendsFeed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader('TRENDING IN YOUR CIRCLE'),
              ),
              _buildTrendingGrid(social.friendsFeed),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildFollowRequestBanner(SocialProvider social) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.requestFocus();
        _searchTabController.animateTo(0);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cinemaRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.cinemaRed.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded,
                color: AppTheme.popcornGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${social.incomingRequests.length} follow '
                '${social.incomingRequests.length == 1 ? 'request' : 'requests'} waiting',
                style: GoogleFonts.lato(
                    color: AppTheme.filmStripBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.popcornGold, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.bebasNeue(
                  color: AppTheme.filmStripBlack, fontSize: 22, letterSpacing: 1),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: GoogleFonts.lato(
                    color: AppTheme.popcornGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPeopleSection(SocialProvider social) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: social.suggestedUsers.length > 8
            ? 8
            : social.suggestedUsers.length,
        itemBuilder: (context, index) {
          return _PeopleToFollowCard(
            user: social.suggestedUsers[index],
            onFollow: () =>
                context.read<SocialProvider>().sendFollowRequest(
                  social.suggestedUsers[index]['uid'].toString(),
                ),
          );
        },
      ),
    );
  }

  Widget _buildFindFriendsPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.fadedCurtain.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.cinemaRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline_rounded,
                color: AppTheme.popcornGold, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover people with your taste',
                    style: GoogleFonts.bebasNeue(
                        color: AppTheme.filmStripBlack, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Like more movies to unlock taste-based friend suggestions',
                    style: GoogleFonts.lato(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsActivitySection(List<SocialActivity> feed) {
    final deduped = <String, SocialActivity>{};
    for (final a in feed) {
      if (a.itemType == SocialItemType.movie &&
          a.activityType == SocialActivityType.liked) {
        deduped.putIfAbsent(a.itemId, () => a);
        if (deduped.length >= 12) break;
      }
    }
    if (deduped.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: deduped.length,
        itemBuilder: (context, index) {
          final activity = deduped.values.elementAt(index);
          return _FriendActivityCard(activity: activity);
        },
      ),
    );
  }

  Widget _buildTrendingGrid(List<SocialActivity> feed) {
    final trendingIds = _computeTrendingIds(feed);
    if (trendingIds.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= trendingIds.length) return null;
            final id = trendingIds[index];
            final movie = _resolvedTrendingMovies[id];
            if (movie == null) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.fadedCurtain.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.cinemaRed,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            return GestureDetector(
              onTap: () => _onMovieTap(movie),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: TMDBService.getImageUrl(
                            movie.posterPath, size: 'w342'),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.fadedCurtain.withValues(alpha: 0.4)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.fadedCurtain.withValues(alpha: 0.4),
                          child: const Icon(Icons.movie_outlined,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        child: Text(
                          movie.title,
                          style: GoogleFonts.lato(
                              color: AppTheme.creamyWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: trendingIds.length,
        ),
      ),
    );
  }

  Widget _buildNoFriendsOnboarding() {
    return Center(
      key: const ValueKey('onboarding'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_rounded,
                size: 72, color: AppTheme.popcornGold),
            const SizedBox(height: 20),
            Text(
              'DISCOVER YOUR NEXT MATCH',
              style: GoogleFonts.bebasNeue(
                  color: AppTheme.filmStripBlack,
                  fontSize: 28,
                  letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Search for movies, shows, or friends. Follow people to see what they\'re watching and get better recommendations.',
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack.withValues(alpha: 0.65),
                  fontSize: 15,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _searchFocusNode.requestFocus(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cinemaRed,
                foregroundColor: AppTheme.creamyWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                'START SEARCHING',
                style: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Active search state ──────────────────────────────────────────────────

  Widget _buildActiveSearchResults() {
    return Column(
      key: const ValueKey('search'),
      children: [
        Container(
          color: AppTheme.vintagePaper,
          child: TabBar(
            controller: _searchTabController,
            tabs: const [Tab(text: 'PEOPLE'), Tab(text: 'MOVIES & SHOWS')],
            labelStyle: GoogleFonts.bebasNeue(fontSize: 16, letterSpacing: 1),
            unselectedLabelStyle:
                GoogleFonts.bebasNeue(fontSize: 16, letterSpacing: 1),
            indicatorColor: AppTheme.cinemaRed,
            indicatorWeight: 2.5,
            labelColor: AppTheme.filmStripBlack,
            unselectedLabelColor:
                AppTheme.filmStripBlack.withValues(alpha: 0.45),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _searchTabController,
            children: [
              _buildPeopleResults(),
              _buildMovieResults(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleResults() {
    return Consumer<SocialProvider>(
      builder: (context, social, _) {
        if (social.isLoading) return _buildLoadingState();

        // No search text → show incoming follow requests
        if (_searchController.text.isEmpty) {
          if (social.incomingRequests.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No pending requests',
              subtitle: 'Search for friends above',
            );
          }
          return _buildIncomingRequestsList(social);
        }

        // Active search
        if (social.searchResults.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search_rounded,
            title: 'No users found',
            subtitle: 'Try a different name or email',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: social.searchResults.length,
          itemBuilder: (context, index) {
            return _UserResultCard(
              user: social.searchResults[index],
              onFollow: () => context.read<SocialProvider>().sendFollowRequest(
                    social.searchResults[index]['uid'].toString(),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestsList(SocialProvider social) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'FOLLOW REQUESTS',
            style: GoogleFonts.bebasNeue(
                color: AppTheme.filmStripBlack, fontSize: 20, letterSpacing: 1),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: social.incomingRequests.length,
            itemBuilder: (context, index) {
              final req = social.incomingRequests[index];
              return _IncomingRequestCard(
                followerUid: req.followerUid,
                onAccept: () => context
                    .read<SocialProvider>()
                    .respondToFollowRequest(
                        requesterUid: req.followerUid, accept: true),
                onDecline: () => context
                    .read<SocialProvider>()
                    .respondToFollowRequest(
                        requesterUid: req.followerUid, accept: false),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieResults() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, _) {
        if (movieProvider.isLoading) return const PosterGridSkeleton();

        if (movieProvider.error != null) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            title: context.l10n.searchErrorTitle,
            subtitle: movieProvider.error!,
          );
        }

        if (_searchController.text.isEmpty) {
          // Show recent searches if available
          if (_searchHistory.isNotEmpty) {
            return _buildSearchHistoryList();
          }
          return _buildEmptyState(
            icon: Icons.movie_outlined,
            title: 'Search for movies & shows',
            subtitle: 'Type above and tap Search',
          );
        }

        if (movieProvider.filteredMovies.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: context.l10n.noMoviesFound,
            subtitle: context.l10n.tryAdjustingSearchTerms,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: movieProvider.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = movieProvider.filteredMovies[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSearchResultItem(movie),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHistoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Text(
          context.l10n.recentSearchesTitle,
          style: GoogleFonts.bebasNeue(
              color: AppTheme.filmStripBlack, fontSize: 20, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map(_buildHistoryItem),
      ],
    );
  }

  Widget _buildHistoryItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.fadedCurtain.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cinemaRed.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(Icons.history, color: AppTheme.popcornGold, size: 20),
        title: Text(query,
            style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack, fontSize: 14)),
        trailing: IconButton(
          icon: Icon(Icons.close,
              size: 16, color: AppTheme.filmStripBlack.withValues(alpha: 0.5)),
          onPressed: () => _removeFromHistory(query),
        ),
        onTap: () => _onHistoryItemTap(query),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildSearchResultItem(Movie movie) {
    return GestureDetector(
      onTap: () => _onMovieTap(movie),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.fadedCurtain.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cinemaRed.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 120,
                child: CachedNetworkImage(
                  imageUrl:
                      TMDBService.getImageUrl(movie.posterPath, size: 'w200'),
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppTheme.fadedCurtain.withValues(alpha: 0.4)),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.fadedCurtain.withValues(alpha: 0.4),
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.lato(
                          color: AppTheme.filmStripBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.mediaType == 'tv') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.cinemaRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.cinemaRed.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'TV SHOW',
                          style: GoogleFonts.lato(
                            color: AppTheme.cinemaRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (movie.year != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        movie.year!,
                        style: GoogleFonts.lato(
                            color: AppTheme.filmStripBlack.withValues(alpha: 0.55),
                            fontSize: 12),
                      ),
                    ],
                    if (movie.voteAverage != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            movie.voteAverage!.toStringAsFixed(1),
                            style: GoogleFonts.lato(
                                color: AppTheme.filmStripBlack,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (movie.overview != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        movie.overview!,
                        style: GoogleFonts.lato(
                            color: AppTheme.filmStripBlack.withValues(alpha: 0.65),
                            fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppTheme.filmStripBlack.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.cinemaRed,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 52, color: AppTheme.filmStripBlack.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private card widgets ─────────────────────────────────────────────────────

class _PeopleToFollowCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onFollow;

  const _PeopleToFollowCard({required this.user, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    final displayName = (user['displayName'] as String?) ?? 'Unknown';
    final photoURL = user['photoURL'] as String?;
    final tasteSimilarity = (user['tasteSimilarity'] as num?)?.toDouble() ?? 0.0;
    final followStatus = user['followStatus'] as String? ?? 'notFollowing';
    final isPending = followStatus == 'pending';
    final isFollowing = followStatus == 'accepted';

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.fadedCurtain.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cinemaRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.popcornGold.withValues(alpha: 0.2),
            backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                ? CachedNetworkImageProvider(photoURL)
                : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.bebasNeue(
                        color: AppTheme.popcornGold, fontSize: 22),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            displayName,
            style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack,
                fontWeight: FontWeight.bold,
                fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          // Taste match
          Text(
            '${(tasteSimilarity * 100).round()}% taste match',
            style: GoogleFonts.lato(
                color: AppTheme.popcornGold, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Follow button
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: (isPending || isFollowing) ? null : onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.transparent
                    : isPending
                        ? AppTheme.fadedCurtain.withValues(alpha: 0.5)
                        : AppTheme.cinemaRed,
                foregroundColor: AppTheme.creamyWhite,
                disabledBackgroundColor: isPending
                    ? AppTheme.fadedCurtain.withValues(alpha: 0.5)
                    : Colors.transparent,
                disabledForegroundColor:
                    AppTheme.filmStripBlack.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                      color: isFollowing || isPending
                          ? AppTheme.filmStripBlack.withValues(alpha: 0.3)
                          : Colors.transparent),
                ),
              ),
              child: Text(
                isFollowing
                    ? 'Following'
                    : isPending
                        ? 'Pending'
                        : 'Follow',
                style: GoogleFonts.lato(
                    fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendActivityCard extends StatefulWidget {
  final SocialActivity activity;

  const _FriendActivityCard({required this.activity});

  @override
  State<_FriendActivityCard> createState() => _FriendActivityCardState();
}

class _FriendActivityCardState extends State<_FriendActivityCard> {
  Movie? _movie;

  @override
  void initState() {
    super.initState();
    final movieId = int.tryParse(widget.activity.itemId);
    if (movieId != null) {
      MovieCacheService.instance.getMovieDetails(movieId).then((movie) {
        if (mounted) setState(() => _movie = movie);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actorName = widget.activity.actorDisplayName ?? 'A friend';
    final posterUrl = _movie?.posterUrl;

    return GestureDetector(
      onTap: () {
        if (_movie != null) {
          Navigator.of(context).push(
            NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: _movie!)),
          );
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppTheme.fadedCurtain.withValues(alpha: 0.4)),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.fadedCurtain.withValues(alpha: 0.4),
                          child: const Icon(Icons.movie_outlined,
                              color: Colors.grey, size: 32),
                        ),
                      )
                    : Container(
                        color: AppTheme.fadedCurtain.withValues(alpha: 0.4),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.cinemaRed, strokeWidth: 2),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          actorName,
                          style: GoogleFonts.lato(
                              color: AppTheme.creamyWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onFollow;

  const _UserResultCard({required this.user, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    final displayName = (user['displayName'] as String?) ?? 'Unknown';
    final email = (user['email'] as String?) ?? '';
    final photoURL = user['photoURL'] as String?;
    final followStatus = user['followStatus'] as String? ?? 'notFollowing';
    final isPending = followStatus == 'pending';
    final isFollowing = followStatus == 'accepted';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.fadedCurtain.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cinemaRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.popcornGold.withValues(alpha: 0.2),
            backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                ? CachedNetworkImageProvider(photoURL)
                : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.bebasNeue(
                        color: AppTheme.popcornGold, fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.lato(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                        fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: (isPending || isFollowing) ? null : onFollow,
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  isFollowing ? Colors.transparent : AppTheme.cinemaRed,
              foregroundColor: AppTheme.creamyWhite,
              disabledForegroundColor:
                  AppTheme.filmStripBlack.withValues(alpha: 0.45),
              side: BorderSide(
                  color: isPending || isFollowing
                      ? AppTheme.filmStripBlack.withValues(alpha: 0.3)
                      : AppTheme.cinemaRed),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isFollowing ? 'Following' : isPending ? 'Pending' : 'Follow',
              style:
                  GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final String followerUid;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestCard({
    required this.followerUid,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.fadedCurtain.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.popcornGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.popcornGold.withValues(alpha: 0.15),
            child: Icon(Icons.person_outline,
                color: AppTheme.popcornGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow request',
                  style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  followerUid,
                  style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 0.45),
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onDecline,
                icon: Icon(Icons.close_rounded,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                    size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: onAccept,
                icon: Icon(Icons.check_circle_rounded,
                    color: AppTheme.popcornGold, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
