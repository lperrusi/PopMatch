import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/video_player_widget.dart';
import '../../providers/streaming_provider.dart';
import '../../models/streaming_platform.dart';
import '../../models/video.dart';
import '../../models/streaming_platform.dart' show MovieStreamingAvailability;
import '../../services/tmdb_service.dart';
import '../../services/movie_cache_service.dart';
import '../../services/movie_embedding_service.dart';
import '../../widgets/transparent_button_image.dart';
import '../../widgets/retro_cinema_bottom_nav.dart';
import '../../utils/navigation_utils.dart';
import 'home_screen.dart' show updateHomeScreenTab;

/// Retro Cinema styled movie detail screen
class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isLightBackground = false;
  bool _isLoadingColor = true;
  Movie? _loadedMovie;
  bool _isSynopsisExpanded = false;
  bool _isDisposed =
      false; // Track if widget is disposed to prevent setState calls
  Timer? _movieDetailsTimer;
  Timer? _colorExtractionTimer;

  @override
  void initState() {
    super.initState();

    // Check if movie is already cached for instant loading
    final cacheService = MovieCacheService.instance;
    final cachedMovie = cacheService.getCachedMovie(widget.movie.id);
    if (cachedMovie != null) {
      // Use cached data immediately - screen is ready to display
      _loadedMovie = cachedMovie;
    }
    // We have basic movie data from widget.movie, so screen can render immediately
    // Additional details (cast/crew) will load in background

    // Defer ALL heavy operations until after the screen fully renders
    // This ensures smooth transition animation completes before any blocking operations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for multiple frames to ensure screen is fully rendered and interactive
      _movieDetailsTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !_isDisposed && cachedMovie == null) {
          // Load additional movie details (cast/crew) in background
          // This will enhance the existing data, not block the screen
          _loadMovieDetails();
        }
      });

      // Color extraction - delay significantly to not block UI
      // This is non-critical and can happen much later
      _colorExtractionTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && !_isDisposed) {
          if (widget.movie.backdropUrl != null ||
              widget.movie.posterUrl != null) {
            _extractColorFromImage();
          } else {
            setState(() {
              _isLoadingColor = false;
              _isLightBackground = false;
            });
          }
        }
      });
    });
  }

  /// Loads full movie details including cast and crew (uses cache if available)
  /// This is called asynchronously after the screen renders - non-blocking
  Future<void> _loadMovieDetails() async {
    // Only load if we don't already have full details with cast/crew
    if (_loadedMovie != null &&
        _loadedMovie!.cast != null &&
        _loadedMovie!.cast!.isNotEmpty) {
      return; // Already have full details
    }

    try {
      final cacheService = MovieCacheService.instance;
      final loadedMovie = await cacheService.getMovieDetails(widget.movie.id);

      // Schedule setState on next frame to avoid blocking
      if (mounted && !_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _loadedMovie = loadedMovie;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading movie details: $e');
      // Don't update state on error - keep showing what we have
      // Screen is already displaying basic movie info, no need to show error state
    }
  }

  /// Gets the movie to display (loaded movie with cast/crew, or fallback to original)
  Movie get _displayMovie => _loadedMovie ?? widget.movie;

  /// Extracts dominant color from poster/backdrop image and determines if background is light
  Future<void> _extractColorFromImage() async {
    try {
      final movie = _displayMovie;
      final imageUrl = movie.backdropUrl ?? movie.posterUrl;
      if (imageUrl == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLightBackground = false;
            _isLoadingColor = false;
          });
        }
        return;
      }

      final imageProvider = CachedNetworkImageProvider(imageUrl);
      // Add timeout to prevent blocking for too long
      PaletteGenerator paletteGenerator;
      try {
        paletteGenerator =
            await PaletteGenerator.fromImageProvider(imageProvider)
                .timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // Use default color if timeout
        if (mounted && !_isDisposed) {
          setState(() {
            _isLightBackground = false;
            _isLoadingColor = false;
          });
        }
        return;
      }

      if (mounted && !_isDisposed) {
        final dominantColor =
            paletteGenerator.dominantColor?.color ?? AppTheme.filmStripBlack;
        final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
        final isLight = brightness == Brightness.light;

        setState(() {
          _isLightBackground = isLight;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLightBackground = false;
          _isLoadingColor = false;
        });
      }
    }
  }

  /// Gets the appropriate text color based on background brightness
  Color get _textColor {
    if (_isLoadingColor) return AppTheme.warmCream;
    return _isLightBackground ? AppTheme.filmStripBlack : AppTheme.warmCream;
  }

  /// Gets the appropriate overlay color for better text readability
  Color get _overlayColor {
    if (_isLightBackground) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return AppTheme.filmStripBlack.withValues(alpha: 0.75);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Mark as disposed immediately to stop all async operations
          _isDisposed = true;
          // Cancel any timers
          _movieDetailsTimer?.cancel();
          _colorExtractionTimer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.vintagePaper,
        body: CustomScrollView(
          slivers: [
            // Retro Cinema App Bar with movie poster
            SliverAppBar(
              expandedHeight: 450,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.vintagePaper,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Movie backdrop (use posterUrl as fallback if backdropUrl is null)
                    Positioned.fill(
                      child: (_displayMovie.backdropUrl != null ||
                              _displayMovie.posterUrl != null)
                          ? CachedNetworkImage(
                              imageUrl: _displayMovie.backdropUrl ??
                                  _displayMovie.posterUrl ??
                                  '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.vintagePaper,
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint(
                                    'Image load error: $error for URL: ${_displayMovie.backdropUrl ?? _displayMovie.posterUrl}');
                                return Container(
                                  color: AppTheme.vintagePaper,
                                  child: Icon(
                                    Icons.movie_outlined,
                                    size: 64,
                                    color: AppTheme.filmStripBlack
                                        .withValues(alpha: 50),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppTheme.vintagePaper,
                              child: Icon(
                                Icons.movie_outlined,
                                size: 64,
                                color: AppTheme.filmStripBlack
                                    .withValues(alpha: 50),
                              ),
                            ),
                    ),

                    // Gradient overlay at bottom for text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 320,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _overlayColor,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Movie info overlay positioned on poster (like swipe screen)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title with adaptive color
                            Text(
                              _displayMovie.title,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 36,
                                color: _textColor,
                                letterSpacing: 1.5,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),

                            // Year and Rating row with adaptive colors
                            Row(
                              children: [
                                if (_displayMovie.year != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brickRed,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _textColor.withValues(alpha: 30),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _displayMovie.year!,
                                      style: GoogleFonts.lato(
                                        color: AppTheme.warmCream,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.brickRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _displayMovie.formattedRating,
                                  style: GoogleFonts.lato(
                                    color: _textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_displayMovie.voteCount != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${_displayMovie.voteCount} votes)',
                                    style: GoogleFonts.lato(
                                      color: _textColor.withValues(alpha: 70),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Watchlist, Like, Dislike and Share buttons row
                            Row(
                              children: [
                                // Watchlist button
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final isInWatchlist =
                                        authProvider.isInWatchlist(
                                            _displayMovie.id.toString());
                                    return IconButton(
                                      icon: TransparentButtonImage(
                                        assetPath:
                                            'assets/buttons/watchlist_button.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                        errorWidget: Icon(
                                          isInWatchlist
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: _textColor,
                                          size: 24,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final movieProvider =
                                            Provider.of<MovieProvider>(context, listen: false);

                                        if (isInWatchlist) {
                                          await authProvider.removeFromWatchlist(
                                              _displayMovie.id.toString());
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Removed ${_displayMovie.title} from watchlist'),
                                              backgroundColor:
                                                  AppTheme.fadedCurtain,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          await authProvider.addToWatchlist(
                                              _displayMovie.id.toString());
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Added ${_displayMovie.title} to watchlist'),
                                              backgroundColor:
                                                  AppTheme.fadedCurtain,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }

                                        // Keep the swipe feed in sync with detail actions.
                                        movieProvider.refreshFilters(authProvider.userData);
                                      },
                                    );
                                  },
                                ),
                                // Like button
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final movieId = _displayMovie.id.toString();
                                    final isLiked = authProvider.isLikedMovie(movieId);
                                    return IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                        color: isLiked ? AppTheme.vintagePaper : _textColor,
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        if (authProvider.userData == null) return;
                                        final movieProvider = Provider.of<MovieProvider>(
                                          context,
                                          listen: false,
                                        );
                                        if (isLiked) {
                                          await authProvider.removeLikedMovie(movieId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Removed ${_displayMovie.title} from favorites'),
                                                backgroundColor: AppTheme.fadedCurtain,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          await authProvider.removeDislikedMovie(movieId);
                                          await authProvider.addLikedMovie(movieId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Added ${_displayMovie.title} to favorites'),
                                                backgroundColor: AppTheme.fadedCurtain,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }

                                        movieProvider.refreshFilters(authProvider.userData);
                                      },
                                    );
                                  },
                                ),
                                // Dislike button
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final movieId = _displayMovie.id.toString();
                                    final isDisliked = authProvider.isDislikedMovie(movieId);
                                    return IconButton(
                                      icon: Icon(
                                        isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                                        color: isDisliked ? AppTheme.vintagePaper : _textColor.withValues(alpha: 0.8),
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        if (authProvider.userData == null) return;
                                        final movieProvider = Provider.of<MovieProvider>(
                                          context,
                                          listen: false,
                                        );
                                        if (isDisliked) {
                                          await authProvider.removeDislikedMovie(movieId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Removed ${_displayMovie.title} from disliked'),
                                                backgroundColor: AppTheme.fadedCurtain,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          await authProvider.removeLikedMovie(movieId);
                                          await authProvider.addDislikedMovie(movieId);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Added ${_displayMovie.title} to disliked'),
                                                backgroundColor: AppTheme.fadedCurtain,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }

                                        movieProvider.refreshFilters(authProvider.userData);
                                      },
                                    );
                                  },
                                ),
                                // Share button
                                IconButton(
                                  icon: Icon(
                                    Icons.share_rounded,
                                    color: _textColor,
                                    size: 24,
                                  ),
                                  onPressed: () => _shareMovie(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Where to Watch section inline with horizontal scroll
                            _InlineStreamingAvailability(
                                movie: _displayMovie, textColor: _textColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Cancel all ongoing operations immediately
                      _isDisposed = true;
                      _movieDetailsTimer?.cancel();
                      _colorExtractionTimer?.cancel();

                      // Navigate immediately - non-blocking
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.vintagePaper,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.cinemaRed.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.cinemaRed,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: const [],
            ),

            // Movie details with Retro Cinema styling
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview with Retro Cinema styling (expandable)
                    if (_displayMovie.overview != null &&
                        _displayMovie.overview!.isNotEmpty) ...[
                      Text(
                        'Synopsis',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 24,
                          color: AppTheme.filmStripBlack,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.vintagePaper,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayMovie.overview!,
                              style: GoogleFonts.lato(
                                color: AppTheme.filmStripBlack,
                                fontSize: 15,
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                              maxLines: _isSynopsisExpanded ? null : 4,
                              overflow: _isSynopsisExpanded
                                  ? null
                                  : TextOverflow.ellipsis,
                            ),
                            // Check if text needs expansion
                            if (_displayMovie.overview!.length > 200) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isSynopsisExpanded = !_isSynopsisExpanded;
                                  });
                                },
                                child: Text(
                                  _isSynopsisExpanded ? 'Show less' : 'More',
                                  style: GoogleFonts.lato(
                                    color: AppTheme.cinemaRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // Videos Section (between Synopsis and Cast & Crew)
            SliverToBoxAdapter(
              child: _VideosSection(movie: _displayMovie),
            ),

            // Director and Actors section
            if (_displayMovie.crew != null || _displayMovie.cast != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _DirectorActorsSection(movie: _displayMovie),
                ),
              ),

            // Similar Movies Section
            SliverToBoxAdapter(
              child: _SimilarMoviesSection(movie: _displayMovie),
            ),
          ],
        ),
        bottomNavigationBar: RetroCinemaBottomNav(
          currentIndex: _getCurrentTabIndex(),
          onTap: (index) {
            _handleNavigationTap(index);
          },
        ),
      ),
    );
  }

  /// Gets the current tab index based on navigation context
  int _getCurrentTabIndex() {
    // Default to 0 (Discover) - we can't determine the actual tab from this screen
    return 0;
  }

  /// Handles navigation tap from bottom navigation
  void _handleNavigationTap(int index) {
    // Cancel all ongoing operations immediately
    _isDisposed = true;
    _movieDetailsTimer?.cancel();
    _colorExtractionTimer?.cancel();

    // Navigate immediately - non-blocking
    Navigator.of(context).pop();

    // Update the HomeScreen tab index after navigation starts
    // Use a microtask to ensure navigation happens first
    Future.microtask(() => updateHomeScreenTab(index));
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel any ongoing timers to prevent operations after disposal
    _movieDetailsTimer?.cancel();
    _colorExtractionTimer?.cancel();
    super.dispose();
  }

  /// Shares movie information
  void _shareMovie(BuildContext context) {
    final shareText = '''
🎬 ${_displayMovie.title}

${_displayMovie.overview ?? 'No description available'}

⭐ Rating: ${_displayMovie.formattedRating}
📅 Year: ${_displayMovie.year ?? 'Unknown'}
🎭 Genres: ${_displayMovie.genres?.join(', ') ?? 'Unknown'}

Check out this movie on PopMatch!
''';

    Share.share(shareText,
        subject: 'Check out this movie: ${_displayMovie.title}');
  }
}

// Keep existing section widgets but update their styling
// Similar Movies Section
class _SimilarMoviesSection extends StatefulWidget {
  final Movie movie;

  const _SimilarMoviesSection({required this.movie});

  @override
  State<_SimilarMoviesSection> createState() => _SimilarMoviesSectionState();
}

class _SimilarMoviesSectionState extends State<_SimilarMoviesSection> {
  List<Movie> _similarMovies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer similar movies loading until after screen renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSimilarMovies();
      }
    });
  }

  Future<void> _loadSimilarMovies() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tmdbService = TMDBService();
      final embeddingService = MovieEmbeddingService();

      // Get similar movies from TMDB API
      List<Movie> similarMovies = [];
      List<Movie> recommendedMovies = [];

      try {
        similarMovies = await tmdbService.getSimilarMovies(widget.movie.id);
        debugPrint(
            'Loaded ${similarMovies.length} similar movies for movie ${widget.movie.id}');
      } catch (e) {
        debugPrint('Error loading similar movies: $e');
        similarMovies = [];
      }

      try {
        recommendedMovies =
            await tmdbService.getMovieRecommendations(widget.movie.id);
        debugPrint(
            'Loaded ${recommendedMovies.length} recommended movies for movie ${widget.movie.id}');
      } catch (e) {
        debugPrint('Error loading recommended movies: $e');
        recommendedMovies = [];
      }

      // Combine both lists
      final allMovies = <Movie>[];
      final seenIds = <int>{};

      // Add similar movies first (they're more directly related)
      for (final movie in similarMovies) {
        if (!seenIds.contains(movie.id) && movie.id != widget.movie.id) {
          allMovies.add(movie);
          seenIds.add(movie.id);
        }
      }

      // Add recommended movies (TMDB's algorithm-based recommendations)
      for (final movie in recommendedMovies) {
        if (!seenIds.contains(movie.id) && movie.id != widget.movie.id) {
          allMovies.add(movie);
          seenIds.add(movie.id);
        }
      }

      debugPrint('Total combined movies before ranking: ${allMovies.length}');

      // If we have movies, use embedding-based similarity to rank them
      if (allMovies.isNotEmpty) {
        // Use embedding service to find most similar movies
        final rankedMovies = embeddingService.findSimilarMovies(
          widget.movie,
          allMovies,
          limit: 6, // Show top 6 most similar for better accuracy
        );

        debugPrint('Ranked movies count: ${rankedMovies.length}');

        if (!mounted) return;

        setState(() {
          _similarMovies = rankedMovies;
          _isLoading = false;
        });
      } else {
        // Fallback: try to get movies from same genres
        if (widget.movie.genreIds != null &&
            widget.movie.genreIds!.isNotEmpty) {
          final genreMovies = await tmdbService.getMoviesByGenre(
            widget.movie.genreIds!.first,
            page: 1,
          );

          // Filter out the current movie and limit to 6
          final filtered = genreMovies
              .where((m) => m.id != widget.movie.id)
              .take(6)
              .toList();

          if (!mounted) return;

          setState(() {
            _similarMovies = filtered;
            _isLoading = false;
          });
        } else {
          if (!mounted) return;

          setState(() {
            _similarMovies = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error loading similar movies: $e');
      setState(() {
        // Prefer empty-state UI over hard error card for transient data issues.
        _error = null;
        _similarMovies = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movies Like This',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: SizedBox.shrink(),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.brickRed,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load similar movies',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 70),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSimilarMovies,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brickRed,
                      foregroundColor: AppTheme.warmCream,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_similarMovies.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.movie_outlined,
                    color: AppTheme.filmStripBlack.withValues(alpha: 30),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No similar movies found',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 60),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _similarMovies.length,
                itemBuilder: (context, index) {
                  return _RetroSimilarMovieCard(movie: _similarMovies[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Retro Cinema styled similar movie card
class _RetroSimilarMovieCard extends StatelessWidget {
  final Movie movie;

  const _RetroSimilarMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
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
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: movie.posterUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.vintagePaper,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.vintagePaper,
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppTheme.filmStripBlack.withValues(alpha: 50),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              movie.title,
              style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 60),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (movie.voteAverage != null) ...[
                  Icon(
                    Icons.star_rounded,
                    color: AppTheme.brickRed,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    movie.formattedRating,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 80),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Import and keep existing section widgets - they will be updated separately
// For now, we'll keep the existing implementations but they should be styled later
// Videos Section
class _VideosSection extends StatefulWidget {
  final Movie movie;

  const _VideosSection({required this.movie});

  @override
  State<_VideosSection> createState() => _VideosSectionState();
}

class _VideosSectionState extends State<_VideosSection> {
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // First check if videos are already in the movie object (from cached data)
    if (widget.movie.videos != null && widget.movie.videos!.isNotEmpty) {
      // Use videos from movie object - no API call needed!
      _videos = widget.movie.videos!;
      _isLoading = false;
    } else {
      // Defer video loading until after screen renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadVideos();
        }
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final tmdbService = TMDBService();
      final videos = await tmdbService.getMovieVideos(widget.movie.id);

      if (!mounted) return;

      setState(() {
        _videos = videos; // Already List<Video>, no need to convert
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trailers & Videos',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return _RetroVideoCard(video: _videos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RetroVideoCard extends StatelessWidget {
  final Video video;

  const _RetroVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cinemaRed,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(video: video),
      ),
    );
  }
}

// Director and Actors Section (horizontal scrollable with overlay text)
class _DirectorActorsSection extends StatelessWidget {
  final Movie movie;

  const _DirectorActorsSection({required this.movie});

  @override
  Widget build(BuildContext context) {
    // Get director from crew
    final directors = movie.crew
            ?.where((member) => member.job?.toLowerCase() == 'director')
            .toList() ??
        [];

    // Get top 10 actors from cast
    final topActors = movie.cast?.take(10).toList() ?? [];

    // Combine director and actors, with director first
    final List<dynamic> allPeople = [];

    // Add directors first
    for (var director in directors) {
      allPeople.add({
        'type': 'director',
        'person': director,
      });
    }

    // Add actors
    for (var actor in topActors) {
      allPeople.add({
        'type': 'actor',
        'person': actor,
      });
    }

    if (allPeople.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast & Crew',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: AppTheme.filmStripBlack,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200, // Fixed height for horizontal scroll
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPeople.length,
            itemBuilder: (context, index) {
              final item = allPeople[index];
              final isDirector = item['type'] == 'director';
              final person = item['person'];

              String? profileUrl;
              String name;
              String? info;

              if (isDirector) {
                final director = person as CrewMember;
                profileUrl = director.profileUrl;
                name = director.name;
                info = director.job;
              } else {
                final actor = person as CastMember;
                profileUrl = actor.profileUrl;
                name = actor.name;
                info =
                    actor.character != null ? 'as ${actor.character!}' : null;
              }

              return _CastCrewCard(
                profileUrl: profileUrl,
                name: name,
                info: info,
                isDirector: isDirector,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual cast/crew card with overlay text
class _CastCrewCard extends StatelessWidget {
  final String? profileUrl;
  final String name;
  final String? info;
  final bool isDirector;

  const _CastCrewCard({
    required this.profileUrl,
    required this.name,
    this.info,
    required this.isDirector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile image
            profileUrl != null
                ? CachedNetworkImage(
                    imageUrl: profileUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brickRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                      child: Icon(
                        Icons.person,
                        color: AppTheme.filmStripBlack.withValues(alpha: 50),
                        size: 48,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.filmStripBlack.withValues(alpha: 20),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.filmStripBlack.withValues(alpha: 50),
                      size: 48,
                    ),
                  ),

            // Gradient overlay at bottom for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.filmStripBlack.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Name and info overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.lato(
                        color: AppTheme.warmCream,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        info!,
                        style: GoogleFonts.lato(
                          color: AppTheme.warmCream.withValues(alpha: 85),
                          fontSize: 11,
                          fontStyle:
                              isDirector ? FontStyle.normal : FontStyle.italic,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Streaming Availability Section
class _StreamingAvailabilitySection extends StatefulWidget {
  final Movie movie;

  const _StreamingAvailabilitySection({required this.movie});

  @override
  State<_StreamingAvailabilitySection> createState() =>
      _StreamingAvailabilitySectionState();
}

class _StreamingAvailabilitySectionState
    extends State<_StreamingAvailabilitySection> {
  MovieStreamingAvailability? _availability;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer streaming availability loading until after screen renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadStreamingAvailability();
      }
    });
  }

  Future<void> _loadStreamingAvailability() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final streamingProvider =
          Provider.of<StreamingProvider>(context, listen: false);
      final availability =
          await streamingProvider.getStreamingAvailability(widget.movie.id);

      if (!mounted) return;

      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tv_rounded,
                color: AppTheme.brickRed,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Where to Watch',
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: AppTheme.filmStripBlack,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: SizedBox.shrink(),
            )
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.brickRed,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load streaming information',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 70),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStreamingAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brickRed,
                      foregroundColor: AppTheme.warmCream,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_availability == null ||
              _availability!.availablePlatforms.isEmpty)
            Center(
              child: Text(
                'No streaming information available',
                style: GoogleFonts.lato(
                  color: AppTheme.filmStripBlack.withValues(alpha: 60),
                  fontSize: 14,
                ),
              ),
            )
          else
            _buildStreamingAvailability(_availability!),
        ],
      ),
    );
  }

  /// Builds Retro Cinema styled streaming availability display
  Widget _buildStreamingAvailability(MovieStreamingAvailability availability) {
    final platforms = availability.platforms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform logos
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: platforms.map((platform) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.vintagePaper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.filmStripBlack.withValues(alpha: 40),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.brickRed.withValues(alpha: 20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getPlatformInitials(platform.name),
                        style: GoogleFonts.bebasNeue(
                          color: AppTheme.brickRed,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    platform.name,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        // Pricing information
        if (availability.isFree ||
            availability.rentalPrice != null ||
            availability.purchasePrice != null) ...[
          const SizedBox(height: 20),
          Text(
            'Pricing',
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (availability.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brickRed.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.brickRed,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Free to Watch',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (availability.rentalPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brickRed.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.brickRed.withValues(alpha: 60),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Rent: ${availability.rentalPrice}',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (availability.purchasePrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brickRed.withValues(alpha: 20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.brickRed.withValues(alpha: 60),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Buy: ${availability.purchasePrice}',
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Gets platform initials for display
  String _getPlatformInitials(String platformName) {
    if (platformName.toLowerCase().contains('netflix')) return 'N';
    if (platformName.toLowerCase().contains('disney')) return 'D+';
    if (platformName.toLowerCase().contains('amazon')) return 'AP';
    if (platformName.toLowerCase().contains('hulu')) return 'H';
    if (platformName.toLowerCase().contains('hbo')) return 'HBO';
    if (platformName.toLowerCase().contains('apple')) return 'A+';
    if (platformName.toLowerCase().contains('paramount')) return 'P+';
    if (platformName.toLowerCase().contains('peacock')) return 'P';
    if (platformName.toLowerCase().contains('youtube')) return 'YT';
    if (platformName.toLowerCase().contains('tubi')) return 'T';
    if (platformName.toLowerCase().contains('pluto')) return 'PTV';
    return platformName.substring(0, 1).toUpperCase();
  }
}

/// Inline streaming availability widget for movie overlay
class _InlineStreamingAvailability extends StatefulWidget {
  final Movie movie;
  final Color textColor;

  const _InlineStreamingAvailability({
    required this.movie,
    this.textColor = AppTheme.warmCream,
  });

  @override
  State<_InlineStreamingAvailability> createState() =>
      _InlineStreamingAvailabilityState();
}

class _InlineStreamingAvailabilityState
    extends State<_InlineStreamingAvailability> {
  MovieStreamingAvailability? _availability;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreamingAvailability();
  }

  Future<void> _loadStreamingAvailability() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final streamingProvider =
          Provider.of<StreamingProvider>(context, listen: false);
      final availability =
          await streamingProvider.getStreamingAvailability(widget.movie.id);

      if (mounted) {
        setState(() {
          _availability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_error != null ||
        _availability == null ||
        _availability!.availablePlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final platforms = _availability!.platforms.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tv_rounded,
              color: widget.textColor.withValues(alpha: 80),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Where to Watch:',
              style: GoogleFonts.lato(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              final platform = platforms[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.sepiaBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      platform.name,
                      style: GoogleFonts.lato(
                        color: widget.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
