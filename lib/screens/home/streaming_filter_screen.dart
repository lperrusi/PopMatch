import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
// import '../../models/streaming_platform.dart'; // Unused import
import '../../providers/streaming_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/streaming_platform_widget.dart';
import '../../widgets/search_results_widget.dart';

/// Screen for filtering movies by streaming platform
class StreamingFilterScreen extends StatefulWidget {
  const StreamingFilterScreen({super.key});

  @override
  State<StreamingFilterScreen> createState() => _StreamingFilterScreenState();
}

class _StreamingFilterScreenState extends State<StreamingFilterScreen> {
  List<Movie> _allMovies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  /// Loads all movies and applies streaming filters
  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final streamingProvider = Provider.of<StreamingProvider>(context, listen: false);
      
      // Get popular movies
      await movieProvider.loadPopularMovies();
      _allMovies = movieProvider.movies;
      
      // Apply streaming filters if any platforms are selected
      if (streamingProvider.selectedPlatformIds.isNotEmpty) {
        await streamingProvider.filterMoviesByPlatforms(_allMovies);
        _filteredMovies = streamingProvider.filteredMovies;
      } else {
        _filteredMovies = _allMovies;
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Applies streaming platform filters
  Future<void> _applyFilters() async {
    final streamingProvider = Provider.of<StreamingProvider>(context, listen: false);
    
    if (streamingProvider.selectedPlatformIds.isEmpty) {
      setState(() {
        _filteredMovies = _allMovies;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await streamingProvider.filterMoviesByPlatforms(_allMovies);
      setState(() {
        _filteredMovies = streamingProvider.filteredMovies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Filters'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          Consumer<StreamingProvider>(
            builder: (context, streamingProvider, child) {
              if (streamingProvider.selectedPlatformIds.isNotEmpty) {
                return IconButton(
                  onPressed: () {
                    streamingProvider.clearSelectedPlatforms();
                    _applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear filters',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Streaming platform filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Streaming Platform',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<StreamingProvider>(
                  builder: (context, streamingProvider, child) {
                    return StreamingPlatformFilterChips(
                      platforms: streamingProvider.availablePlatforms,
                      selectedPlatformIds: streamingProvider.selectedPlatformIds,
                      onPlatformSelected: (platformId) {
                        streamingProvider.selectPlatform(platformId);
                        _applyFilters();
                      },
                      onPlatformDeselected: (platformId) {
                        streamingProvider.deselectPlatform(platformId);
                        _applyFilters();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Results section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.primaryRed,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load movies',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMovies,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredMovies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tv_off,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No movies found',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try selecting different streaming platforms',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Results header
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Text(
                                      '${_filteredMovies.length} movies found',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Consumer<StreamingProvider>(
                                      builder: (context, streamingProvider, child) {
                                        if (streamingProvider.selectedPlatformIds.isNotEmpty) {
                                          return Text(
                                            'Filtered by ${streamingProvider.selectedPlatformIds.length} platform${streamingProvider.selectedPlatformIds.length > 1 ? 's' : ''}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Movie results
                              Expanded(
                                child: SearchResultsWidget(
                                  movies: _filteredMovies,
                                  onMovieTap: (movie) {
                                    Navigator.pushNamed(
                                      context,
                                      '/movie-detail',
                                      arguments: movie,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
} 