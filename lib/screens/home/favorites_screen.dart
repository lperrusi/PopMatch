import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../services/tmdb_service.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

enum FavoriteSortOrder {
  /// TV shows: sort by watching status (Watching first, then Finished)
  watchingFirst,
  /// TV shows: sort by watching status (Finished first, then Watching)
  finishedFirst,
  titleAsc,
  titleDesc,
  yearNewest,
  yearOldest,
  ratingHigh,
  ratingLow,
}

/// Favorites screen showing user's liked movies and shows with lazy loading
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _showScrollController = ScrollController();
  List<Movie> _favoriteMovies = [];
  List<TvShow> _favoriteShows = [];
  List<String> _allLikedMovieIds = [];
  List<String> _allLikedShowIds = [];
  int _loadedCount = 0; // Track how many movies have been loaded
  int _loadedShowCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingShows = false;
  bool _isLoadingMoreShows = false;
  bool _hasMore = true;
  bool _hasMoreShows = true;
  String? _error;
  final TMDBService _tmdbService = TMDBService();

  // Sort (per tab)
  FavoriteSortOrder? _sortMovies;
  FavoriteSortOrder? _sortShows;

  // Delete mode: select items then confirm
  bool _isDeleteMode = false;
  final Set<String> _selectedMovieIds = {};
  final Set<String> _selectedShowIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _showScrollController.addListener(_onShowScroll);
    // Load initial batch after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialBatch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showScrollController.removeListener(_onShowScroll);
    _showScrollController.dispose();
    super.dispose();
  }

  void _onShowScroll() {
    if (_showScrollController.position.pixels >=
        _showScrollController.position.maxScrollExtent - 200) {
      _loadMoreShows();
    }
  }

  /// Handles scroll events to load more movies when near bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when 200px from bottom
      _loadMoreMovies();
    }
  }

  /// Loads the initial batch of 8 movies
  Future<void> _loadInitialBatch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final likedMovieIds = authProvider.userData?.likedMovies ?? [];

    if (likedMovieIds.isEmpty) {
      setState(() {
        _favoriteMovies = [];
        _allLikedMovieIds = [];
        _loadedCount = 0;
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _favoriteMovies = []; // Clear existing movies to prevent duplicates
      _allLikedMovieIds = List.from(likedMovieIds);
      _loadedCount = 0;
      _hasMore = likedMovieIds.isNotEmpty;
    });

    await _loadBatch(8); // Load first 8 movies

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads the next batch of movies (8 at a time)
  Future<void> _loadMoreMovies() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _loadedCount >= _allLikedMovieIds.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    await _loadBatch(8); // Load next 8 movies

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        _hasMore = _loadedCount < _allLikedMovieIds.length;
      });
    }
  }

  /// Loads a batch of movies starting from _loadedCount
  Future<void> _loadBatch(int batchSize) async {
    if (_loadedCount >= _allLikedMovieIds.length) {
      return;
    }

    try {
      final cacheService = MovieCacheService.instance;
      final batchIds =
          _allLikedMovieIds.skip(_loadedCount).take(batchSize).toList();

      final batchFutures = batchIds.map((movieIdStr) async {
        try {
          final movieId = int.tryParse(movieIdStr);
          if (movieId == null) return null;

          // Try cache first
          final cachedMovie = cacheService.getCachedMovie(movieId);
          if (cachedMovie != null) {
            return cachedMovie;
          }

          // Fetch from API (cache service handles caching automatically)
          return await cacheService.getMovieDetails(movieId);
        } catch (e) {
          debugPrint('Error loading movie $movieIdStr: $e');
          return null;
        }
      });

      final batchResults = await Future.wait(batchFutures, eagerError: false);

      // Filter out nulls and add to list
      final newMovies = <Movie>[];
      for (final movie in batchResults) {
        if (movie != null) {
          newMovies.add(movie);
        }
      }

      if (mounted) {
        setState(() {
          _favoriteMovies.addAll(newMovies);
          _loadedCount += batchIds.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      _selectedMovieIds.clear();
      _selectedShowIds.clear();
    });
  }

  void _showSortSheet() {
    final isMovies = _tabController.index == 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.vintagePaper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final current = isMovies ? _sortMovies : _sortShows;
        // For shows, null means "Watching first" (default)
        final effectiveShowsSort = current ?? FavoriteSortOrder.watchingFirst;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.75;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Sort ${isMovies ? "movies" : "shows"} by',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22,
                            color: AppTheme.filmStripBlack,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      if (!isMovies) ...[
                        _sortTile('Watching first', FavoriteSortOrder.watchingFirst, effectiveShowsSort),
                        _sortTile('Finished first', FavoriteSortOrder.finishedFirst, effectiveShowsSort),
                        const Divider(height: 1),
                      ],
                      _sortTile('Title A–Z', FavoriteSortOrder.titleAsc, isMovies ? current : effectiveShowsSort),
                      _sortTile('Title Z–A', FavoriteSortOrder.titleDesc, isMovies ? current : effectiveShowsSort),
                      _sortTile('Year (newest first)', FavoriteSortOrder.yearNewest, isMovies ? current : effectiveShowsSort),
                      _sortTile('Year (oldest first)', FavoriteSortOrder.yearOldest, isMovies ? current : effectiveShowsSort),
                      _sortTile('Rating (highest first)', FavoriteSortOrder.ratingHigh, isMovies ? current : effectiveShowsSort),
                      _sortTile('Rating (lowest first)', FavoriteSortOrder.ratingLow, isMovies ? current : effectiveShowsSort),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ListTile _sortTile(String label, FavoriteSortOrder order, FavoriteSortOrder? current) {
    final selected = current == order;
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.lato(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: AppTheme.filmStripBlack,
        ),
      ),
      trailing: selected ? Icon(Icons.check_rounded, color: AppTheme.brickRed) : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          if (_tabController.index == 0) {
            _sortMovies = order;
          } else {
            _sortShows = order;
          }
        });
      },
    );
  }

  List<Movie> get _sortedMovies {
    if (_sortMovies == null) return _favoriteMovies;
    final list = List<Movie>.from(_favoriteMovies);
    switch (_sortMovies!) {
      case FavoriteSortOrder.titleAsc:
        list.sort((a, b) => (a.title).toLowerCase().compareTo((b.title).toLowerCase()));
        break;
      case FavoriteSortOrder.titleDesc:
        list.sort((a, b) => (b.title).toLowerCase().compareTo((a.title).toLowerCase()));
        break;
      case FavoriteSortOrder.yearNewest:
        list.sort((a, b) => _year(b).compareTo(_year(a)));
        break;
      case FavoriteSortOrder.yearOldest:
        list.sort((a, b) => _year(a).compareTo(_year(b)));
        break;
      case FavoriteSortOrder.ratingHigh:
        list.sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));
        break;
      case FavoriteSortOrder.ratingLow:
        list.sort((a, b) => (a.voteAverage ?? 0).compareTo(b.voteAverage ?? 0));
        break;
      case FavoriteSortOrder.watchingFirst:
      case FavoriteSortOrder.finishedFirst:
        // Only used for TV shows; no-op for movies
        break;
    }
    return list;
  }

  int _year(Movie m) => int.tryParse(m.releaseDate?.split('-').first ?? '0') ?? 0;
  int _showYear(TvShow s) => int.tryParse(s.firstAirDate?.split('-').first ?? '0') ?? 0;

  /// Whether the user has finished the show (watched episode count >= total episodes).
  bool _isShowFinished(AuthProvider authProvider, TvShow show) {
    final total = show.numberOfEpisodes ?? 0;
    if (total == 0) return false;
    final watched = authProvider.getWatchedEpisodes(show.id.toString()).length;
    return watched >= total;
  }

  /// Sorted shows list; for status-based sort uses [authProvider] for episode progress.
  List<TvShow> _getSortedShows(AuthProvider authProvider) {
    final list = List<TvShow>.from(_favoriteShows);
    final order = _sortShows;
    // Default for shows: Watching first, then Finished
    if (order == null || order == FavoriteSortOrder.watchingFirst || order == FavoriteSortOrder.finishedFirst) {
      final watching = <TvShow>[];
      final finished = <TvShow>[];
      for (final show in list) {
        if (_isShowFinished(authProvider, show)) {
          finished.add(show);
        } else {
          watching.add(show);
        }
      }
      int nameCmp(TvShow a, TvShow b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase());
      // Within Watching: most recently watched first (actively watching at top), then by title
      watching.sort((a, b) {
        final aAt = authProvider.getShowLastWatchedAt(a.id.toString());
        final bAt = authProvider.getShowLastWatchedAt(b.id.toString());
        if (aAt != null && bAt != null) {
          final cmp = bAt.compareTo(aAt); // descending (newest first)
          if (cmp != 0) return cmp;
        } else if (aAt != null) {
          return -1; // a has date, b doesn't -> a first
        } else if (bAt != null) {
          return 1; // b has date, a doesn't -> b first
        }
        return nameCmp(a, b);
      });
      finished.sort(nameCmp);
      if (order == FavoriteSortOrder.finishedFirst) {
        return [...finished, ...watching];
      }
      return [...watching, ...finished];
    }
    switch (order) {
      case FavoriteSortOrder.titleAsc:
        list.sort((a, b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase()));
        break;
      case FavoriteSortOrder.titleDesc:
        list.sort((a, b) => (b.name).toLowerCase().compareTo((a.name).toLowerCase()));
        break;
      case FavoriteSortOrder.yearNewest:
        list.sort((a, b) => _showYear(b).compareTo(_showYear(a)));
        break;
      case FavoriteSortOrder.yearOldest:
        list.sort((a, b) => _showYear(a).compareTo(_showYear(b)));
        break;
      case FavoriteSortOrder.ratingHigh:
        list.sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));
        break;
      case FavoriteSortOrder.ratingLow:
        list.sort((a, b) => (a.voteAverage ?? 0).compareTo(b.voteAverage ?? 0));
        break;
      default:
        break;
    }
    return list;
  }

  /// Reloads favorites when the list changes
  Future<void> _reloadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final likedMovieIds = authProvider.userData?.likedMovies ?? [];

    // Check if the list actually changed
    final newIdsSet = likedMovieIds.toSet();
    final currentIdsSet = _allLikedMovieIds.toSet();

    if (newIdsSet.length != currentIdsSet.length ||
        !newIdsSet.every((id) => currentIdsSet.contains(id)) ||
        !currentIdsSet.every((id) => newIdsSet.contains(id))) {
      // List changed, reload from start
      await _loadInitialBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'FAVORITES',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: AppTheme.warmCream,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cinemaRed,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            color: AppTheme.warmCream,
            onPressed: _isDeleteMode ? null : _showSortSheet,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: Icon(_isDeleteMode ? Icons.close_rounded : Icons.delete_outline_rounded),
            color: AppTheme.warmCream,
            onPressed: _toggleDeleteMode,
            tooltip: _isDeleteMode ? 'Cancel' : 'Delete',
          ),
        ],
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoviesTab(),
          _buildShowsTab(),
        ],
      ),
    );
  }

  Widget _buildMoviesTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final likedMovieIds = authProvider.userData?.likedMovies ?? [];

        // Check if favorites list changed and reload if needed
        if (likedMovieIds.length != _allLikedMovieIds.length ||
            !likedMovieIds.every((id) => _allLikedMovieIds.contains(id))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isLoading) {
              _reloadFavorites();
            }
          });
        }

        if (likedMovieIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: AppTheme.warmCream.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start swiping to like movies!',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: AppTheme.warmCream.withValues(alpha: 70),
                  ),
                ),
              ],
            ),
          );
        }

        if (_isLoading && _favoriteMovies.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.cinemaRed,
            ),
          );
        }

        if (_error != null && _favoriteMovies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.cinemaRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading favorites',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadInitialBatch,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppTheme.popcornGold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (_favoriteMovies.isEmpty && !_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: AppTheme.warmCream.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorites found',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedMovies = _sortedMovies;
        final grid = GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, _isDeleteMode ? 80 : 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: sortedMovies.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= sortedMovies.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.cinemaRed,
                  ),
                ),
              );
            }

            final movie = sortedMovies[index];
            final movieId = movie.id.toString();
            final isSelected = _isDeleteMode && _selectedMovieIds.contains(movieId);
            return GestureDetector(
              onTap: () async {
                if (_isDeleteMode) {
                  setState(() {
                    if (_selectedMovieIds.contains(movieId)) {
                      _selectedMovieIds.remove(movieId);
                    } else {
                      _selectedMovieIds.add(movieId);
                    }
                  });
                  return;
                }
                MovieCacheService.instance.preloadMovieDetails(movie.id);
                await Future.delayed(const Duration(milliseconds: 50));
                if (context.mounted) {
                  Navigator.of(context).push(
                    NavigationUtils.fastSlideRoute(
                        MovieDetailScreen(movie: movie)),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    movie.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.deepMidnightBrown,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.deepMidnightBrown,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 48,
                                color: AppTheme.warmCream.withValues(alpha: 50),
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.deepMidnightBrown,
                            child: Icon(
                              Icons.movie_outlined,
                              size: 48,
                              color: AppTheme.warmCream.withValues(alpha: 50),
                            ),
                          ),
                    if (_isDeleteMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brickRed
                                : AppTheme.filmStripBlack.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.warmCream,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.circle_outlined,
                            color: AppTheme.warmCream,
                            size: 24,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDeleteMode && isSelected
                              ? AppTheme.brickRed.withValues(alpha: 0.9)
                              : AppTheme.cinemaRed,
                        ),
                        child: Text(
                          movie.title,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            color: AppTheme.warmCream,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (_isDeleteMode) {
          return Column(
            children: [
              Expanded(child: grid),
              _buildDeleteBar(isMovies: true),
            ],
          );
        }
        return grid;
      },
    );
  }

  Widget _buildDeleteBar({required bool isMovies}) {
    final count = isMovies ? _selectedMovieIds.length : _selectedShowIds.length;
    final canDelete = count > 0;
    final label = canDelete
        ? 'Delete $count ${count == 1 ? 'item' : 'items'}'
        : (isMovies ? 'Select Movies to Delete' : 'Select Shows to Delete');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.vintagePaper,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canDelete ? () => _confirmDelete(isMovies: isMovies) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brickRed,
              disabledBackgroundColor: AppTheme.brickRed,
              foregroundColor: AppTheme.warmCream,
              disabledForegroundColor: AppTheme.warmCream.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: canDelete ? 4 : 0,
              shadowColor: canDelete ? AppTheme.brickRed.withValues(alpha: 0.5) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete({required bool isMovies}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (isMovies) {
      final ids = Set<String>.from(_selectedMovieIds);
      for (final id in ids) {
        await authProvider.removeLikedMovie(id);
      }
      final count = ids.length;
      setState(() {
        _favoriteMovies.removeWhere((m) => ids.contains(m.id.toString()));
        _allLikedMovieIds.removeWhere(ids.contains);
        _selectedMovieIds.clear();
        _isDeleteMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $count movie(s) from favorites'),
            backgroundColor: AppTheme.fadedCurtain,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final ids = Set<String>.from(_selectedShowIds);
      for (final id in ids) {
        await authProvider.removeLikedShow(id);
      }
      final count = ids.length;
      setState(() {
        _favoriteShows.removeWhere((s) => ids.contains(s.id.toString()));
        _allLikedShowIds.removeWhere(ids.contains);
        _selectedShowIds.clear();
        _isDeleteMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $count show(s) from favorites'),
            backgroundColor: AppTheme.fadedCurtain,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildShowsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final likedShowIds = authProvider.userData?.likedShows ?? [];

        // Check if shows list changed and reload if needed
        if (likedShowIds.length != _allLikedShowIds.length ||
            !likedShowIds.every((id) => _allLikedShowIds.contains(id))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isLoadingShows) {
              _loadInitialShowsBatch();
            }
          });
        }

        if (likedShowIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: AppTheme.warmCream.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite shows yet',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start swiping to like shows!',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: AppTheme.warmCream.withValues(alpha: 70),
                  ),
                ),
              ],
            ),
          );
        }

        if (_isLoadingShows && _favoriteShows.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.cinemaRed,
            ),
          );
        }

        if (_favoriteShows.isEmpty && !_isLoadingShows) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: AppTheme.warmCream.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite shows found',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedShows = _getSortedShows(authProvider);
        final grid = GridView.builder(
          controller: _showScrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, _isDeleteMode ? 80 : 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: sortedShows.length + (_isLoadingMoreShows ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= sortedShows.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.cinemaRed,
                  ),
                ),
              );
            }

            final show = sortedShows[index];
            final showId = show.id.toString();
            final isSelected = _isDeleteMode && _selectedShowIds.contains(showId);
            final isFinished = _isShowFinished(authProvider, show);
            return GestureDetector(
              onTap: () {
                if (_isDeleteMode) {
                  setState(() {
                    if (_selectedShowIds.contains(showId)) {
                      _selectedShowIds.remove(showId);
                    } else {
                      _selectedShowIds.add(showId);
                    }
                  });
                  return;
                }
                Navigator.of(context).push(
                  NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    show.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: show.posterUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.deepMidnightBrown,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.deepMidnightBrown,
                              child: Icon(
                                Icons.tv_outlined,
                                size: 48,
                                color: AppTheme.warmCream.withValues(alpha: 50),
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.deepMidnightBrown,
                            child: Icon(
                              Icons.tv_outlined,
                              size: 48,
                              color: AppTheme.warmCream.withValues(alpha: 50),
                            ),
                          ),
                    // Status badge: Watching / Finished
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFinished
                              ? AppTheme.popcornGold.withValues(alpha: 0.95)
                              : AppTheme.primaryRed.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          isFinished ? 'Finished' : 'Watching',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isFinished ? AppTheme.filmStripBlack : AppTheme.warmCream,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    if (_isDeleteMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brickRed
                                : AppTheme.filmStripBlack.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.warmCream,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.circle_outlined,
                            color: AppTheme.warmCream,
                            size: 24,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDeleteMode && isSelected
                              ? AppTheme.brickRed.withValues(alpha: 0.9)
                              : isFinished
                                  ? AppTheme.sepiaBrown
                                  : AppTheme.cinemaRed,
                        ),
                        child: Text(
                          show.name,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            color: AppTheme.warmCream,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (_isDeleteMode) {
          return Column(
            children: [
              Expanded(child: grid),
              _buildDeleteBar(isMovies: false),
            ],
          );
        }
        return grid;
      },
    );
  }

  Future<void> _loadInitialShowsBatch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final likedShowIds = authProvider.userData?.likedShows ?? [];

    if (likedShowIds.isEmpty) {
      setState(() {
        _favoriteShows = [];
        _allLikedShowIds = [];
        _loadedShowCount = 0;
        _isLoadingShows = false;
        _hasMoreShows = false;
      });
      return;
    }

    setState(() {
      _isLoadingShows = true;
      _error = null;
      _favoriteShows = [];
      _allLikedShowIds = List.from(likedShowIds);
      _loadedShowCount = 0;
      _hasMoreShows = likedShowIds.isNotEmpty;
    });

    await _loadShowBatch(8);

    if (mounted) {
      setState(() {
        _isLoadingShows = false;
      });
    }
  }

  Future<void> _loadMoreShows() async {
    if (_isLoadingMoreShows ||
        !_hasMoreShows ||
        _loadedShowCount >= _allLikedShowIds.length) {
      return;
    }

    setState(() {
      _isLoadingMoreShows = true;
    });

    await _loadShowBatch(8);

    if (mounted) {
      setState(() {
        _isLoadingMoreShows = false;
        _hasMoreShows = _loadedShowCount < _allLikedShowIds.length;
      });
    }
  }

  Future<void> _loadShowBatch(int batchSize) async {
    if (_loadedShowCount >= _allLikedShowIds.length) {
      return;
    }

    try {
      final batchIds =
          _allLikedShowIds.skip(_loadedShowCount).take(batchSize).toList();

      final batchFutures = batchIds.map((showIdStr) async {
        try {
          final showId = int.tryParse(showIdStr);
          if (showId == null) return null;

          return await _tmdbService.getShowDetails(showId);
        } catch (e) {
          debugPrint('Error loading show $showIdStr: $e');
          return null;
        }
      });

      final batchResults = await Future.wait(batchFutures, eagerError: false);

      final newShows = <TvShow>[];
      for (final show in batchResults) {
        if (show != null) {
          newShows.add(show);
        }
      }

      if (mounted) {
        setState(() {
          _favoriteShows.addAll(newShows);
          _loadedShowCount += batchIds.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
}
