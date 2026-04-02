import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import '../../services/tmdb_service.dart';
import '../../services/search_service.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

/// Screen for displaying personalized movie recommendations
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TMDBService _tmdbService = TMDBService();

  // Search state
  List<Movie> _searchMovies = [];
  List<TvShow> _searchShows = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  List<String> _recentSearches = [];

  // Filter states - allow multiple selections
  final Set<String> _selectedFilters = {'forYou'}; // Default to 'For You'

  // Enhanced recommendation features
  final bool _showRecommendationExplanations = false;
  final Map<String, dynamic> _smartFilters = {};

  // Animation controllers for smooth removals
  final Map<int, AnimationController> _removalControllers = {};
  final Map<int, Animation<double>> _removalAnimations = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(() => setState(() {}));
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    // Dispose all animation controllers
    for (final controller in _removalControllers.values) {
      controller.dispose();
    }
    _removalControllers.clear();
    _removalAnimations.clear();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchMovies = [];
        _searchShows = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {}); // Update clear button and show search area
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _loadRecentSearches() async {
    final history = await SearchService.instance.loadSearchHistory();
    if (mounted) setState(() => _recentSearches = history.take(5).toList());
  }

  Future<void> _runSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await Future.wait([
        _tmdbService.searchMovies(query),
        _tmdbService.searchShows(query),
      ]);
      if (mounted) {
        setState(() {
          _searchMovies = results[0] as List<Movie>;
          _searchShows = results[1] as List<TvShow>;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchMovies = [];
          _searchShows = [];
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchMovies = [];
      _searchShows = [];
      _isSearching = false;
    });
  }

  /// Saves the current search query to recent history (only when user commits: Enter or tap on result).
  Future<void> _saveSearchToHistory() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    await SearchService.instance.addToHistory(query);
    if (mounted) _loadRecentSearches();
  }

  /// Loads recommendations for the current user
  // ignore: unused_element
  Future<void> _loadRecommendations() async {
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final recommendationsProvider =
          Provider.of<RecommendationsProvider>(context, listen: false);

      if (authProvider.userData != null) {
        recommendationsProvider.setCurrentUser(authProvider.userData!);

        // Only load if we don't have recommendations yet (show cached data immediately)
        if (recommendationsProvider.recommendations.isEmpty) {
          await recommendationsProvider.loadPersonalizedRecommendations();
        } else {
          // User already has recommendations cached, refresh in background
          recommendationsProvider.loadPersonalizedRecommendations(
              refresh: true);
        }
        recommendationsProvider.loadFriendsRecommendations();
      }

      // Only load trending if we don't have them yet
      if (recommendationsProvider.trendingRecommendations.isEmpty) {
        await recommendationsProvider.loadTrendingRecommendations();
      }
    });
  }

  /// Handles movie tap to show details
  void _onMovieTap(Movie movie) async {
    // Preload movie details in background before navigation
    MovieCacheService.instance.preloadMovieDetails(movie.id);

    // Small delay to allow preload to start
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
      );
    }
  }

  /// Handles movie like action
  void _onMovieLike(Movie movie) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationsProvider =
        Provider.of<RecommendationsProvider>(context, listen: false);

    authProvider.addLikedMovie(movie.id.toString());

    // Animate the removal
    _animateMovieRemoval(movie.id, () {
      recommendationsProvider.handleMovieLike(movie);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${movie.title} to your liked movies!'),
        backgroundColor: AppTheme.primaryRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handles movie dislike action
  void _onMovieDislike(Movie movie) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final recommendationsProvider =
        Provider.of<RecommendationsProvider>(context, listen: false);

    authProvider.addDislikedMovie(movie.id.toString());

    // Animate the removal
    _animateMovieRemoval(movie.id, () {
      recommendationsProvider.handleMovieSkip(movie);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Skipped ${movie.title}'),
        backgroundColor: Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Animates the removal of a movie with a smooth fade-out effect
  void _animateMovieRemoval(int movieId, VoidCallback onComplete) {
    // Create animation controller if it doesn't exist
    if (!_removalControllers.containsKey(movieId)) {
      _removalControllers[movieId] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _removalAnimations[movieId] = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _removalControllers[movieId]!,
        curve: Curves.easeInOut,
      ));
    }

    // Start the animation
    _removalControllers[movieId]!.forward().then((_) {
      onComplete();

      // Load more recommendations if needed
      final recommendationsProvider =
          Provider.of<RecommendationsProvider>(context, listen: false);
      recommendationsProvider.loadMoreRecommendationsIfNeeded();

      // Clean up the animation controller after a delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_removalControllers.containsKey(movieId)) {
          _removalControllers[movieId]!.dispose();
          _removalControllers.remove(movieId);
          _removalAnimations.remove(movieId);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          // Main content: search-only mode (no suggestions/recommendations)
          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _buildSearchResultsContent()
                : _buildSearchOnlyEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchOnlyEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 56,
            color: AppTheme.sepiaBrown.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 14),
          Text(
            'Search movies and shows',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.sepiaBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing to find titles instantly',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppTheme.sepiaBrown.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds smart filters bar
  // ignore: unused_element
  Widget _buildSmartFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: _smartFilters.entries.map((entry) {
          return Chip(
            label: Text('${entry.key}: ${entry.value}'),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              setState(() {
                _smartFilters.remove(entry.key);
              });
              _applySmartFilters();
            },
            backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
            labelStyle: const TextStyle(color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  /// Builds the search bar with debounced search and recent suggestions
  Widget _buildSearchBar() {
    final showRecent = _searchFocusNode.hasFocus &&
        _searchController.text.trim().isEmpty &&
        _recentSearches.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.cinemaRed,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(
              color: AppTheme.warmCream,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search movies & shows...',
              hintStyle: TextStyle(
                color: AppTheme.warmCream.withValues(alpha: 0.6),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.warmCream.withValues(alpha: 0.8),
                size: 24,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: AppTheme.warmCream.withValues(alpha: 0.8),
                        size: 22,
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.filmStripBlack.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _runSearch(value.trim());
                _saveSearchToHistory();
              }
            },
          ),
          if (showRecent) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warmCream.withValues(alpha: 0.7),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await SearchService.instance.clearHistory();
                    if (mounted) _loadRecentSearches();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.popcornGold.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _recentSearches.map((term) {
                return ActionChip(
                  label: Text(
                    term,
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor:
                      AppTheme.filmStripBlack.withValues(alpha: 0.5),
                  side: BorderSide.none,
                  onPressed: () {
                    _searchController.text = term;
                    _runSearch(term);
                    _searchFocusNode.unfocus();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds search results: loading, empty, or tabbed movies + shows
  Widget _buildSearchResultsContent() {
    if (_isSearching && _searchMovies.isEmpty && _searchShows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppTheme.popcornGold,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: AppTheme.warmCream.withValues(alpha: 0.8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    final hasMovies = _searchMovies.isNotEmpty;
    final hasShows = _searchShows.isNotEmpty;
    if (!hasMovies && !hasShows) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppTheme.sepiaBrown.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text.trim()}"',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: AppTheme.warmCream.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different title or keyword',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.warmCream.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Tabbed view: Movies | Shows
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppTheme.cinemaRed,
            child: TabBar(
              indicatorColor: AppTheme.popcornGold,
              labelColor: AppTheme.warmCream,
              unselectedLabelColor: AppTheme.warmCream.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1),
              tabs: [
                Tab(
                    text: hasMovies
                        ? 'MOVIES (${_searchMovies.length})'
                        : 'MOVIES'),
                Tab(
                    text:
                        hasShows ? 'SHOWS (${_searchShows.length})' : 'SHOWS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSearchResultMovieList(),
                _buildSearchResultShowList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultMovieList() {
    if (_searchMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined,
                size: 48, color: AppTheme.sepiaBrown.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No movies found',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  color: AppTheme.warmCream.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _searchMovies.length,
      itemBuilder: (context, index) =>
          _buildSearchResultMovieTile(_searchMovies[index]),
    );
  }

  Widget _buildSearchResultShowList() {
    if (_searchShows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_rounded,
                size: 48, color: AppTheme.sepiaBrown.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No shows found',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  color: AppTheme.warmCream.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _searchShows.length,
      itemBuilder: (context, index) =>
          _buildSearchResultShowTile(_searchShows[index]),
    );
  }

  Widget _buildSearchResultMovieTile(Movie movie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            _saveSearchToHistory();
            MovieCacheService.instance.preloadMovieDetails(movie.id);
            Navigator.of(context).push(
              NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 84,
                    child: movie.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.movie_outlined,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie_outlined,
                                color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppTheme.warmCream,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (movie.year != null) ...[
                            Text(
                              movie.year!,
                              style: TextStyle(
                                color:
                                    AppTheme.warmCream.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.star_rounded,
                              size: 14,
                              color:
                                  AppTheme.popcornGold.withValues(alpha: 0.9)),
                          const SizedBox(width: 4),
                          Text(
                            movie.formattedRating,
                            style: TextStyle(
                              color: AppTheme.warmCream.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.warmCream.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultShowTile(TvShow show) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            _saveSearchToHistory();
            Navigator.of(context).push(
              NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 84,
                    child: show.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: show.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.tv_rounded,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.tv_rounded,
                                color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        show.name,
                        style: const TextStyle(
                          color: AppTheme.warmCream,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (show.year != null) ...[
                            Text(
                              show.year!,
                              style: TextStyle(
                                color:
                                    AppTheme.warmCream.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.star_rounded,
                              size: 14,
                              color:
                                  AppTheme.popcornGold.withValues(alpha: 0.9)),
                          const SizedBox(width: 4),
                          Text(
                            show.formattedRating,
                            style: TextStyle(
                              color: AppTheme.warmCream.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.warmCream.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds filter selector with multi-select capability (navbar style)
  // ignore: unused_element
  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cinemaRed,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildFilterButton('forYou', 'For You')),
          Expanded(child: _buildFilterButton('trending', 'Trending')),
          Expanded(child: _buildFilterButton('mood', 'Mood')),
          Expanded(child: _buildFilterButton('similar', 'Similar')),
          Expanded(child: _buildFilterButton('friends', 'Friends')),
        ],
      ),
    );
  }

  /// Builds individual filter button (navbar style)
  Widget _buildFilterButton(String filterId, String label) {
    final isSelected = _selectedFilters.contains(filterId);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFilters.remove(filterId);
          } else {
            _selectedFilters.add(filterId);
          }
          // Ensure at least one filter is selected
          if (_selectedFilters.isEmpty) {
            _selectedFilters.add('forYou');
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.vintagePaper : AppTheme.fadedCurtain,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.cinemaRed,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds enhanced loading state with AI animation
  // ignore: unused_element
  Widget _buildEnhancedLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI-powered loading animation
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Icon(
                  Icons.psychology,
                  size: 64,
                  color: AppTheme.primaryRed.withValues(alpha: 0.7),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'AI is analyzing your preferences...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finding the perfect movies for you',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds filtered recommendations list based on selected filters
  // ignore: unused_element
  Widget _buildFilteredRecommendationsList(RecommendationsProvider provider) {
    // Combine movies from selected filters
    final Set<int> seenIds = {};
    final List<Movie> combinedMovies = [];
    final Set<int> friendSourceMovieIds = {};

    if (_selectedFilters.contains('forYou')) {
      for (var movie in provider.recommendations) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          combinedMovies.add(movie);
        }
      }
    }

    if (_selectedFilters.contains('trending')) {
      for (var movie in provider.trendingRecommendations) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          combinedMovies.add(movie);
        }
      }
    }

    if (_selectedFilters.contains('mood')) {
      for (var movie in provider.moodRecommendations) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          combinedMovies.add(movie);
        }
      }
    }

    if (_selectedFilters.contains('similar')) {
      for (var movie in provider.becauseYouLikedRecommendations) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          combinedMovies.add(movie);
        }
      }
    }

    if (_selectedFilters.contains('friends')) {
      for (var movie in provider.friendsRecommendations) {
        if (!seenIds.contains(movie.id)) {
          seenIds.add(movie.id);
          combinedMovies.add(movie);
        }
        friendSourceMovieIds.add(movie.id);
      }
    }

    // Determine the type label based on selected filters
    String typeLabel = 'Recommendations';
    if (_selectedFilters.length == 1) {
      if (_selectedFilters.contains('forYou')) {
        typeLabel = 'For You';
      } else if (_selectedFilters.contains('trending')) {
        typeLabel = 'Trending';
      } else if (_selectedFilters.contains('mood')) {
        typeLabel = 'Mood';
      } else if (_selectedFilters.contains('similar')) {
        typeLabel = 'Similar';
      } else if (_selectedFilters.contains('friends')) {
        typeLabel = 'Friends';
      }
    } else {
      typeLabel = 'Filtered';
    }

    return _buildRecommendationsList(
      combinedMovies,
      typeLabel,
      friendSourceMovieIds: friendSourceMovieIds,
    );
  }

  /// Builds enhanced recommendations list with explanations
  Widget _buildRecommendationsList(
    List<Movie> movies,
    String type, {
    Set<int>? friendSourceMovieIds,
  }) {
    if (movies.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final fromFriends = friendSourceMovieIds?.contains(movie.id) ?? false;
        return _buildEnhancedMovieCard(
          movie,
          type,
          index,
          fromFriends: fromFriends,
        );
      },
    );
  }

  /// Builds enhanced movie card with recommendation explanations
  Widget _buildEnhancedMovieCard(
    Movie movie,
    String type,
    int index, {
    bool fromFriends = false,
  }) {
    final isAnimating = _removalAnimations.containsKey(movie.id);
    final animation = isAnimating ? _removalAnimations[movie.id]! : null;

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced movie poster with overlay
              Container(
                width: 120,
                height: 180,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: movie.posterPath != null
                            ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
                            : 'https://via.placeholder.com/120x180/666666/FFFFFF?text=No+Image',
                        fit: BoxFit.cover,
                        width: 120,
                        height: 180,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryRed,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // AI recommendation badge
                    if (_showRecommendationExplanations)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Movie details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and year
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (movie.year != null)
                        Text(
                          movie.year!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Rating
                      if (movie.voteAverage != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      // Genres
                      if (movie.genreIds != null && movie.genreIds!.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: movie.genreIds!.take(3).map((genreId) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getGenreName(genreId),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 12),

                      // Recommendation explanation
                      if (_showRecommendationExplanations)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getRecommendationExplanation(movie, type),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      if (fromFriends) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.popcornGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.popcornGold.withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 12,
                                color: AppTheme.popcornGold,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Liked by friends',
                                style: TextStyle(
                                  color: AppTheme.popcornGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onMovieDislike(movie),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Skip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Like button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onMovieLike(movie),
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text('Like'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isAnimating && animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: 0.8 + (animation.value * 0.2),
              child: card,
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _onMovieTap(movie),
      child: card,
    );
  }

  /// Gets recommendation explanation for a movie
  String _getRecommendationExplanation(Movie movie, String type) {
    switch (type) {
      case 'For You':
        return 'Recommended based on your AI-analyzed preferences and viewing history';
      case 'Trending':
        return 'Currently popular and trending among movie enthusiasts';
      case 'Mood':
        return 'Perfect for your current mood and emotional state';
      case 'Similar':
        return 'Similar to movies you\'ve liked, with AI-enhanced matching';
      case 'Friends':
        return 'Liked by people you follow';
      default:
        return 'AI-powered recommendation for you';
    }
  }

  /// Gets genre name from ID
  String _getGenreName(int genreId) {
    final genreMap = {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Sci-Fi',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western'
    };
    return genreMap[genreId] ?? 'Unknown';
  }

  /// Shows smart filters dialog
  // ignore: unused_element
  void _showSmartFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => _buildSmartFiltersDialog(),
    );
  }

  /// Builds smart filters dialog
  Widget _buildSmartFiltersDialog() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Genre filter
          const Text(
            'Genres',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Action', 'Comedy', 'Drama', 'Horror', 'Sci-Fi']
                .map((genre) => FilterChip(
                      label: Text(genre),
                      selected: _smartFilters['genre'] == genre,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _smartFilters['genre'] = genre;
                          } else {
                            _smartFilters.remove('genre');
                          }
                        });
                      },
                      selectedColor: AppTheme.primaryRed,
                      checkmarkColor: Colors.white,
                    ))
                .toList(),
          ),

          const SizedBox(height: 16),

          // Year range filter
          const Text(
            'Year Range',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'From',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _smartFilters['yearFrom'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'To',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _smartFilters['yearTo'] = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applySmartFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  /// Applies smart filters
  void _applySmartFilters() {
    // Apply filters to recommendations
    // This would filter the recommendations based on smart filters
    // Implementation depends on your filtering logic
    Provider.of<RecommendationsProvider>(context, listen: false);
  }

  /// Refines recommendations with AI
  // ignore: unused_element
  void _refineRecommendations() {
    final provider =
        Provider.of<RecommendationsProvider>(context, listen: false);
    provider.loadPersonalizedRecommendations(refresh: true);
  }

  /// Builds empty state
  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No $type movies found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your preferences or filters',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds error state
  // ignore: unused_element
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading recommendations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final provider =
                  Provider.of<RecommendationsProvider>(context, listen: false);
              provider.loadPersonalizedRecommendations(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
