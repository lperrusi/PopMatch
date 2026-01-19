import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie.dart';
import '../../providers/movie_provider.dart';
// import '../../providers/auth_provider.dart'; // Unused import
import '../../providers/streaming_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/tmdb_service.dart';
import '../../services/search_service.dart';
import '../../services/movie_cache_service.dart';
// import '../../widgets/movie_card.dart'; // Unused import
import '../../widgets/streaming_platform_widget.dart';
import 'movie_detail_screen.dart';

/// Search screen with advanced filtering and search history
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _showFilters = false;
  bool _isSearching = false;
  
  // Filter states
  int? _selectedGenreId;
  int? _selectedYear;
  String _selectedSortBy = 'relevance';
  bool _showOnlyAvailable = false;
  List<String> _selectedStreamingPlatforms = [];
  
  // Search history
  final List<String> _searchHistory = [];
  static const int _maxHistoryItems = 10;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Loads search history from shared preferences
  Future<void> _loadSearchHistory() async {
    final history = await SearchService.instance.loadSearchHistory();
    setState(() {
      _searchHistory.clear();
      _searchHistory.addAll(history);
    });
  }

  /// Saves search query to history
  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    await SearchService.instance.addToHistory(query);
    await _loadSearchHistory();
  }

  /// Performs search with current filters
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (!SearchService.instance.isValidSearchQuery(query)) return;
    
    await _saveToHistory(query);
    _searchFocusNode.unfocus();
    
    setState(() {
      _isSearching = true;
    });
    
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    await movieProvider.searchMovies(
      SearchService.instance.sanitizeQuery(query),
      genreId: _selectedGenreId,
      year: _selectedYear,
      sortBy: _selectedSortBy,
      showOnlyAvailable: _showOnlyAvailable,
    );
    
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Clears search and filters
  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    
    setState(() {
      _selectedGenreId = null;
      _selectedYear = null;
      _selectedSortBy = 'relevance';
      _showOnlyAvailable = false;
      _selectedStreamingPlatforms.clear();
    });
    
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    movieProvider.clearFilters();
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

  /// Handles search history item tap
  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch();
  }

  /// Removes item from search history
  Future<void> _removeFromHistory(String query) async {
    await SearchService.instance.removeFromHistory(query);
    await _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            _buildSearchHeader(),
            
            // Filters section
            if (_showFilters) 
              Flexible(
                child: _buildFiltersSection(),
              ),
            
            // Search results or history
            Expanded(
              child: Consumer<MovieProvider>(
                builder: (context, movieProvider, child) {
                  if (_searchController.text.isEmpty) {
                    return _buildSearchHistory();
                  } else {
                    return _buildSearchResults(movieProvider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the search header with search bar and filter toggle
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryRed.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search movies, actors, or genres...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.primaryRed,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppTheme.primaryRed,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  final movieProvider = Provider.of<MovieProvider>(context, listen: false);
                  movieProvider.clearFilters();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Filter toggle and search button
          Row(
            children: [
              // Filter toggle
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                    if (_showFilters) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showFilters ? AppTheme.primaryRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryRed,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 18,
                          color: _showFilters ? Colors.white : AppTheme.primaryRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: _showFilters ? Colors.white : AppTheme.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Search button
              ElevatedButton(
                onPressed: _isSearching ? null : _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the filters section
  Widget _buildFiltersSection() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35, // Reduced from 0.4 to 0.35
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2), // Updated to use withValues
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10), // Reduced from 12 to 10
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  
                  // Genre filter
                  Consumer<MovieProvider>(
                    builder: (context, movieProvider, child) {
                      final genres = movieProvider.genres.entries.toList();
                      return _buildFilterDropdown(
                        label: 'Genre',
                        value: _selectedGenreId,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Genres'),
                          ),
                          ...genres.map((entry) => DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(entry.value),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGenreId = value;
                          });
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 4), // Reduced from 6 to 4
                  
                  // Year filter
                  _buildFilterDropdown(
                    label: 'Year',
                    value: _selectedYear,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Years'),
                      ),
                      ...List.generate(20, (index) { // Reduced from 25 to 20
                        final year = DateTime.now().year - index;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 4), // Reduced from 6 to 4
                  
                  // Sort by filter
                  _buildFilterDropdown(
                    label: 'Sort By',
                    value: _selectedSortBy,
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'relevance',
                        child: Text('Relevance'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'rating',
                        child: Text('Rating'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'year',
                        child: Text('Year'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'title',
                        child: Text('Title'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSortBy = value ?? 'relevance';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  
                  // Available only checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyAvailable = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryRed,
                      ),
                      const Expanded(
                        child: Text('Show only available on streaming'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4), // Reduced from 6 to 4
                  
                  // Streaming platform filters
                  Text(
                    'Streaming Platforms',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3), // Reduced from 4 to 3
                  Consumer<StreamingProvider>(
                    builder: (context, streamingProvider, child) {
                      return StreamingPlatformFilterChips(
                        platforms: streamingProvider.availablePlatforms,
                        selectedPlatformIds: _selectedStreamingPlatforms,
                        onPlatformSelected: (platformId) {
                          setState(() {
                            if (!_selectedStreamingPlatforms.contains(platformId)) {
                              _selectedStreamingPlatforms.add(platformId);
                            }
                          });
                        },
                        onPlatformDeselected: (platformId) {
                          setState(() {
                            _selectedStreamingPlatforms.remove(platformId);
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a filter dropdown widget
  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), // Updated to use withValues
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryRed),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the search history section
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 40, // Reduced from 48
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), // Updated to use withValues
            ),
            const SizedBox(height: 8), // Reduced from 12
            Text(
              'Search for movies, actors, or genres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), // Updated to use withValues
              ),
            ),
            const SizedBox(height: 4), // Reduced from 6
            Text(
              'Your recent searches will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), // Updated to use withValues
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(6), // Reduced from 8
      children: [
        Text(
          'Recent Searches',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4), // Reduced from 6
        ..._searchHistory.map((query) => _buildHistoryItem(query)),
      ],
    );
  }

  /// Builds a search history item
  Widget _buildHistoryItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3), // Reduced from 4
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2), // Updated to use withValues
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: AppTheme.primaryRed,
          size: 20, // Reduced size
        ),
        title: Text(
          query,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16), // Reduced from 18
          onPressed: () => _removeFromHistory(query),
        ),
        onTap: () => _onHistoryItemTap(query),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reduced padding
      ),
    );
  }

  /// Builds the search results section
  Widget _buildSearchResults(MovieProvider movieProvider) {
    if (movieProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
        ),
      );
    }

    if (movieProvider.error != null) {
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
              movieProvider.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (movieProvider.filteredMovies.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movieProvider.filteredMovies.length,
      itemBuilder: (context, index) {
        final movie = movieProvider.filteredMovies[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildSearchResultItem(movie),
        );
      },
    );
  }

  /// Builds a search result item
  Widget _buildSearchResultItem(Movie movie) {
    return GestureDetector(
      onTap: () => _onMovieTap(movie),
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
        child: Row(
          children: [
            // Movie poster
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 120,
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
            
            // Movie details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    
                    if (movie.voteAverage != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
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
                      const SizedBox(height: 4),
                    ],
                    
                    if (movie.overview != null) ...[
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
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
} 