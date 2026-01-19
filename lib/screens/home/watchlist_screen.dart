import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../services/watchlist_service.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import 'movie_detail_screen.dart';
import 'enhanced_watchlist_screen.dart';

/// Watchlist screen showing user's saved movies
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EnhancedWatchlistScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.tune,
              color: AppTheme.warmCream,
            ),
            tooltip: 'Advanced Organization',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final watchlistIds = authProvider.userData!.watchlist;
          
          if (watchlistIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
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
                    'Start swiping to add movies to your watchlist!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.sepiaBrown.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          }

          return Consumer<MovieProvider>(
            builder: (context, movieProvider, child) {
              // Filter movies that are in the watchlist
              final watchlistMovies = movieProvider.movies
                  .where((movie) => watchlistIds.contains(movie.id.toString()))
                  .toList();

              if (watchlistMovies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: AppTheme.sepiaBrown,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No movies in watchlist',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.sepiaBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Movies you add to your watchlist will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.sepiaBrown.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: watchlistMovies.length,
                itemBuilder: (context, index) {
                  final movie = watchlistMovies[index];
                  // Preload movie details proactively when card is created
                  MovieCacheService.instance.preloadMovieDetails(movie.id);
                  
                  return WatchlistMovieCard(
                    movie: movie,
                    onRemove: () => _removeFromWatchlist(context, movie),
                    onTap: () => _showMovieDetails(context, movie),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Removes a movie from the watchlist
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

  /// Shows movie details screen
  void _showMovieDetails(BuildContext context, Movie movie) {
    // Preload movie details in background (non-blocking)
    MovieCacheService.instance.preloadMovieDetails(movie.id);
    
    // Navigate immediately - cache will be used if available
    Navigator.of(context).push(
      NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
    );
  }
}

/// Movie card widget for watchlist
class WatchlistMovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const WatchlistMovieCard({
    super.key,
    required this.movie,
    required this.onRemove,
    required this.onTap,
  });

  @override
  State<WatchlistMovieCard> createState() => _WatchlistMovieCardState();
}

class _WatchlistMovieCardState extends State<WatchlistMovieCard> {
  @override
  void initState() {
    super.initState();
    // Preload movie details proactively when card is created
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
              // Movie poster
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
              
              // Movie details
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
                    
                    // Year and rating
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
                        Icon(
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
                    
                    // Genres
                    if (widget.movie.genres != null && widget.movie.genres!.isNotEmpty)
                      Text(
                        widget.movie.genres!.take(2).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Remove button
              IconButton(
                onPressed: widget.onRemove,
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