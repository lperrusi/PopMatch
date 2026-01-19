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
import 'package:google_fonts/google_fonts.dart';

/// Favorites screen showing user's liked movies and shows with lazy loading
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
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
    if (_isLoadingMore || !_hasMore || _loadedCount >= _allLikedMovieIds.length) {
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
      final batchIds = _allLikedMovieIds
          .skip(_loadedCount)
          .take(batchSize)
          .toList();

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
                  Icon(
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

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _favoriteMovies.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the bottom
              if (index >= _favoriteMovies.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.cinemaRed,
                    ),
                  ),
                );
              }

              final movie = _favoriteMovies[index];
              return GestureDetector(
                onTap: () async {
                  // Preload movie details in background before navigation
                  MovieCacheService.instance.preloadMovieDetails(movie.id);
                  
                  // Small delay to allow preload to start
                  await Future.delayed(const Duration(milliseconds: 50));
                  
                  if (context.mounted) {
                    Navigator.of(context).push(
                      NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
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
                      // Title overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cinemaRed,
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
        },
    );
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

        return GridView.builder(
          controller: _showScrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _favoriteShows.length + (_isLoadingMoreShows ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _favoriteShows.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.cinemaRed,
                  ),
                ),
              );
            }

            final show = _favoriteShows[index];
            return GestureDetector(
              onTap: () {
                // TODO: Navigate to show detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Show details coming soon: ${show.name}'),
                    backgroundColor: AppTheme.fadedCurtain,
                  ),
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
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cinemaRed,
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
    if (_isLoadingMoreShows || !_hasMoreShows || _loadedShowCount >= _allLikedShowIds.length) {
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
      final batchIds = _allLikedShowIds
          .skip(_loadedShowCount)
          .take(batchSize)
          .toList();

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
