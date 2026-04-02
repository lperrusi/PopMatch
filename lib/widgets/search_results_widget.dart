import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../utils/theme.dart';

/// Widget for displaying search results in a grid or list format
class SearchResultsWidget extends StatefulWidget {
  final List<Movie> movies;
  final bool isLoading;
  final String? error;
  final Function(Movie) onMovieTap;
  final bool isGridView;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;

  const SearchResultsWidget({
    super.key,
    required this.movies,
    this.isLoading = false,
    this.error,
    required this.onMovieTap,
    this.isGridView = true,
    this.onRetry,
    this.onLoadMore,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  late bool _isGridView;

  @override
  void initState() {
    super.initState();
    _isGridView = widget.isGridView;
  }

  @override
  void didUpdateWidget(SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGridView != widget.isGridView) {
      _isGridView = widget.isGridView;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.movies.isEmpty) {
      return _buildLoadingState();
    }

    if (widget.error != null && widget.movies.isEmpty) {
      return _buildErrorState(context);
    }

    if (widget.movies.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildResultsList(context);
  }

  /// Builds the loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
          ),
          const SizedBox(height: 16),
          const Text(
            'Searching for movies...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error state
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.primaryRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Search Error',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.error ?? 'An error occurred while searching',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.onRetry != null)
            ElevatedButton(
              onPressed: widget.onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Builds the empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No movies found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the results list
  Widget _buildResultsList(BuildContext context) {
    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${widget.movies.length} result${widget.movies.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // View toggle: grid vs list
              IconButton(
                onPressed: () {
                  setState(() => _isGridView = !_isGridView);
                },
                icon: Icon(
                  _isGridView ? Icons.view_list : Icons.grid_view,
                  color: AppTheme.primaryRed,
                ),
                tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
              ),
            ],
          ),
        ),
        
        // Results grid/list
        Expanded(
          child: _isGridView
              ? _buildGridView(context)
              : _buildListView(context),
        ),
        
        // Load more button
        if (widget.onLoadMore != null && !widget.isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onLoadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Load More'),
              ),
            ),
          ),
        
        // Loading indicator for load more
        if (widget.isLoading && widget.movies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
          ),
      ],
    );
  }

  /// Builds the grid view
  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.movies.length,
      itemBuilder: (context, index) {
        return _buildGridItem(context, widget.movies[index]);
      },
    );
  }

  /// Builds the list view
  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.movies.length,
      itemBuilder: (context, index) {
        return _buildListItem(context, widget.movies[index]);
      },
    );
  }

  /// Builds a grid item
  Widget _buildGridItem(BuildContext context, Movie movie) {
    return GestureDetector(
      onTap: () => widget.onMovieTap(movie),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie poster
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: TMDBService.getImageUrl(movie.posterPath, size: 'w300'),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            
            // Movie info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  if (movie.year != null) ...[
                    Text(
                      movie.year!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  if (movie.voteAverage != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          movie.voteAverage!.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a list item
  Widget _buildListItem(BuildContext context, Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 90,
            child: CachedNetworkImage(
              imageUrl: TMDBService.getImageUrl(movie.posterPath, size: 'w200'),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
            ),
          ),
        ),
        title: Text(
          movie.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movie.year != null) ...[
              Text(
                movie.year!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (movie.voteAverage != null)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage!.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (movie.overview != null) ...[
              const SizedBox(height: 4),
              Text(
                movie.overview!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: () => widget.onMovieTap(movie),
      ),
    );
  }
} 