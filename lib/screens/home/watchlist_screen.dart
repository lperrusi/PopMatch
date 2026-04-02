import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import '../../services/tmdb_service.dart';
import 'movie_detail_screen.dart';
import 'show_detail_screen.dart';

final TMDBService _watchlistTmdbService = TMDBService();

void _removeFromWatchlist(BuildContext context, Movie movie) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  authProvider.removeFromWatchlist(movie.id.toString());
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Removed ${movie.title} from watchlist'),
      backgroundColor: AppTheme.fadedCurtain,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showMovieWatchlistActionSheet(BuildContext context, Movie movie) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.vintagePaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  movie.title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.thumb_up_rounded, color: AppTheme.brickRed),
                title: Text(
                  'Liked',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Add to Favorites and remove from watchlist',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.addLikedMovie(movie.id.toString());
                  await authProvider.removeFromWatchlist(movie.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${movie.title} moved to Favorites'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.thumb_down_rounded, color: AppTheme.filmStripBlack.withValues(alpha: 0.8)),
                title: Text(
                  'Disliked',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Mark as disliked and remove from watchlist',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.addDislikedMovie(movie.id.toString());
                  await authProvider.removeFromWatchlist(movie.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${movie.title} marked as disliked'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: AppTheme.filmStripBlack.withValues(alpha: 0.8)),
                title: Text(
                  'Remove',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Remove from watchlist only',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.removeFromWatchlist(movie.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${movie.title} from watchlist'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _removeFromWatchlistShow(BuildContext context, TvShow show) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  authProvider.removeFromWatchlistShow(show.id.toString());
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Removed ${show.name} from watchlist'),
      backgroundColor: AppTheme.fadedCurtain,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showShowWatchlistActionSheet(BuildContext context, TvShow show) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.vintagePaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  show.name,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.thumb_up_rounded, color: AppTheme.brickRed),
                title: Text(
                  'Liked',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Add to Favorites and remove from watchlist',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.addLikedShow(show.id.toString());
                  await authProvider.removeFromWatchlistShow(show.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${show.name} moved to Favorites'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.thumb_down_rounded, color: AppTheme.filmStripBlack.withValues(alpha: 0.8)),
                title: Text(
                  'Disliked',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Mark as disliked and remove from watchlist',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.addDislikedShow(show.id.toString());
                  await authProvider.removeFromWatchlistShow(show.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${show.name} marked as disliked'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: AppTheme.filmStripBlack.withValues(alpha: 0.8)),
                title: Text(
                  'Remove',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.filmStripBlack,
                  ),
                ),
                subtitle: Text(
                  'Remove from watchlist only',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await authProvider.removeFromWatchlistShow(show.id.toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${show.name} from watchlist'),
                        backgroundColor: AppTheme.fadedCurtain,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showMovieDetails(BuildContext context, Movie movie) {
  MovieCacheService.instance.preloadMovieDetails(movie.id);
  Navigator.of(context).push(
    NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
  );
}

void _showShowDetails(BuildContext context, TvShow show) {
  Navigator.of(context).push(
    NavigationUtils.fastSlideRoute(ShowDetailScreen(show: show)),
  );
}

/// Watchlist screen showing user's saved movies and shows
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: _WatchlistScaffold(),
    );
  }
}

class _WatchlistScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      appBar: AppBar(
        title: Text(
          'WATCHLIST',
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
          controller: tabController,
          indicatorColor: AppTheme.popcornGold,
          labelColor: AppTheme.warmCream,
          unselectedLabelColor: AppTheme.warmCream.withValues(alpha: 0.6),
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
      body: Consumer3<AuthProvider, MovieProvider, ShowProvider>(
        builder: (context, authProvider, movieProvider, showProvider, child) {
          if (authProvider.userData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final watchlistIds = authProvider.userData!.watchlist;
          final watchlistShowIds = authProvider.userData!.watchlistShowsOrEmpty;
          final hasAnyIds = watchlistIds.isNotEmpty || watchlistShowIds.isNotEmpty;

          if (!hasAnyIds) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppTheme.sepiaBrown,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your watchlist is empty',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.sepiaBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start swiping to add movies and shows to your watchlist!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.sepiaBrown.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Movies: from provider first, then load missing by ID
          final fromProviderMovies = movieProvider.movies
              .where((m) => watchlistIds.contains(m.id.toString()))
              .toList();
          final missingMovieIds = watchlistIds
              .where((id) => !fromProviderMovies.any((m) => m.id.toString() == id))
              .toList();

          // Shows: from provider first, then load missing by ID
          final fromProviderShows = showProvider.shows
              .where((s) => watchlistShowIds.contains(s.id.toString()))
              .toList();
          final missingShowIds = watchlistShowIds
              .where((id) => !fromProviderShows.any((s) => s.id.toString() == id))
              .toList();

          return _WatchlistContent(
            tabController: tabController,
            authProvider: authProvider,
            fromProviderMovies: fromProviderMovies,
            fromProviderShows: fromProviderShows,
            missingMovieIds: missingMovieIds,
            missingShowIds: missingShowIds,
            tmdbService: _watchlistTmdbService,
            onRemoveMovie: _removeFromWatchlist,
            onMovieMinusPressed: _showMovieWatchlistActionSheet,
            onRemoveShow: _removeFromWatchlistShow,
            onShowMinusPressed: _showShowWatchlistActionSheet,
            onTapMovie: _showMovieDetails,
            onTapShow: _showShowDetails,
          );
        },
      ),
    );
  }
}

/// Content that loads missing items by ID and displays movies + shows in tabs
class _WatchlistContent extends StatefulWidget {
  final TabController tabController;
  final AuthProvider authProvider;
  final List<Movie> fromProviderMovies;
  final List<TvShow> fromProviderShows;
  final List<String> missingMovieIds;
  final List<String> missingShowIds;
  final TMDBService tmdbService;
  final void Function(BuildContext, Movie) onRemoveMovie;
  final void Function(BuildContext, Movie) onMovieMinusPressed;
  final void Function(BuildContext, TvShow) onRemoveShow;
  final void Function(BuildContext, TvShow) onShowMinusPressed;
  final void Function(BuildContext, Movie) onTapMovie;
  final void Function(BuildContext, TvShow) onTapShow;

  const _WatchlistContent({
    required this.tabController,
    required this.authProvider,
    required this.fromProviderMovies,
    required this.fromProviderShows,
    required this.missingMovieIds,
    required this.missingShowIds,
    required this.tmdbService,
    required this.onRemoveMovie,
    required this.onMovieMinusPressed,
    required this.onRemoveShow,
    required this.onShowMinusPressed,
    required this.onTapMovie,
    required this.onTapShow,
  });

  @override
  State<_WatchlistContent> createState() => _WatchlistContentState();
}

class _WatchlistContentState extends State<_WatchlistContent> {
  List<Movie> _extraMovies = [];
  List<TvShow> _extraShows = [];
  bool _loadingMovies = false;
  bool _loadingShows = false;

  @override
  void initState() {
    super.initState();
    _loadMissing();
  }

  @override
  void didUpdateWidget(covariant _WatchlistContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missingMovieIds != widget.missingMovieIds ||
        oldWidget.missingShowIds != widget.missingShowIds) {
      _loadMissing();
    }
  }

  Future<void> _loadMissing() async {
    if (widget.missingMovieIds.isEmpty && widget.missingShowIds.isEmpty) {
      if (_extraMovies.isNotEmpty || _extraShows.isNotEmpty) {
        setState(() {
          _extraMovies = [];
          _extraShows = [];
        });
      }
      return;
    }

    setState(() {
      _loadingMovies = widget.missingMovieIds.isNotEmpty;
      _loadingShows = widget.missingShowIds.isNotEmpty;
    });

    final loadedMovies = <Movie>[];
    final loadedShows = <TvShow>[];

    for (final idStr in widget.missingMovieIds) {
      final id = int.tryParse(idStr);
      if (id == null) continue;
      try {
        final movie = await widget.tmdbService.getMovieDetails(id);
        loadedMovies.add(movie);
      } catch (_) {
        // Skip failed
      }
    }

    for (final idStr in widget.missingShowIds) {
      final id = int.tryParse(idStr);
      if (id == null) continue;
      try {
        final show = await widget.tmdbService.getShowDetails(id);
        loadedShows.add(show);
      } catch (_) {
        // Skip failed
      }
    }

    if (mounted) {
      setState(() {
        _extraMovies = loadedMovies;
        _extraShows = loadedShows;
        _loadingMovies = false;
        _loadingShows = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMovies = [
      ...widget.fromProviderMovies,
      ..._extraMovies,
    ];
    final allShows = [
      ...widget.fromProviderShows,
      ..._extraShows,
    ];
    final isLoadingMovies = _loadingMovies;
    final isLoadingShows = _loadingShows;

    return TabBarView(
      controller: widget.tabController,
      children: [
        _buildMoviesTab(
          context,
          allMovies: allMovies,
          isLoading: isLoadingMovies,
        ),
        _buildShowsTab(
          context,
          allShows: allShows,
          isLoading: isLoadingShows,
        ),
      ],
    );
  }

  Widget _buildMoviesTab(
    BuildContext context, {
    required List<Movie> allMovies,
    required bool isLoading,
  }) {
    if (isLoading && allMovies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cinemaRed),
      );
    }
    if (allMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppTheme.sepiaBrown.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'No movies in watchlist',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: AppTheme.sepiaBrown,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to add movies!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.sepiaBrown.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allMovies.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= allMovies.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.cinemaRed)),
          );
        }
        final movie = allMovies[index];
        MovieCacheService.instance.preloadMovieDetails(movie.id);
        return WatchlistMovieCard(
          movie: movie,
          onRemove: () => widget.onRemoveMovie(context, movie),
          onMinusPressed: () => widget.onMovieMinusPressed(context, movie),
          onTap: () => widget.onTapMovie(context, movie),
        );
      },
    );
  }

  Widget _buildShowsTab(
    BuildContext context, {
    required List<TvShow> allShows,
    required bool isLoading,
  }) {
    if (isLoading && allShows.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cinemaRed),
      );
    }
    if (allShows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_rounded,
              size: 64,
              color: AppTheme.sepiaBrown.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'No shows in watchlist',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: AppTheme.sepiaBrown,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to add shows!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.sepiaBrown.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allShows.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= allShows.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.cinemaRed)),
          );
        }
        final show = allShows[index];
        return WatchlistShowCard(
          show: show,
          onRemove: () => widget.onRemoveShow(context, show),
          onMinusPressed: () => widget.onShowMinusPressed(context, show),
          onTap: () => widget.onTapShow(context, show),
        );
      },
    );
  }
}

/// Movie card widget for watchlist
class WatchlistMovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onRemove;
  final VoidCallback? onMinusPressed;
  final VoidCallback onTap;

  const WatchlistMovieCard({
    super.key,
    required this.movie,
    required this.onRemove,
    this.onMinusPressed,
    required this.onTap,
  });

  @override
  State<WatchlistMovieCard> createState() => _WatchlistMovieCardState();
}

class _WatchlistMovieCardState extends State<WatchlistMovieCard> {
  @override
  void initState() {
    super.initState();
    MovieCacheService.instance.preloadMovieDetails(widget.movie.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: widget.movie.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.movie.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.movie.year != null) ...[
                          Text(
                            widget.movie.year!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.vintagePaper,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.star,
                          color: AppTheme.vintagePaper,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.movie.formattedRating,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.movie.genres != null &&
                        widget.movie.genres!.isNotEmpty)
                      Text(
                        widget.movie.genres!.take(2).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onMinusPressed ?? widget.onRemove,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.vintagePaper,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show card widget for watchlist
class WatchlistShowCard extends StatelessWidget {
  final TvShow show;
  final VoidCallback onRemove;
  final VoidCallback? onMinusPressed;
  final VoidCallback onTap;

  const WatchlistShowCard({
    super.key,
    required this.show,
    required this.onRemove,
    this.onMinusPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: show.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: show.posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.tv, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.tv, color: Colors.grey),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.vintagePaper,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.star,
                          color: AppTheme.vintagePaper,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          show.formattedRating,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (show.genres != null && show.genres!.isNotEmpty)
                      Text(
                        show.genres!.take(2).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMinusPressed ?? onRemove,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.vintagePaper,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
