import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie.dart';
import '../../models/user.dart';
import '../../models/mood.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recommendations_provider.dart';
import '../../services/tmdb_service.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import 'movie_detail_screen.dart';

/// Screen for displaying personalized movie recommendations
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  
  // Filter states - allow multiple selections
  Set<String> _selectedFilters = {'forYou'}; // Default to 'For You'
  
  // Enhanced recommendation features
  bool _showRecommendationExplanations = false;
  Map<String, dynamic> _smartFilters = {};
  bool _isRefiningRecommendations = false;
  
  // Animation controllers for smooth removals
  final Map<int, AnimationController> _removalControllers = {};
  final Map<int, Animation<double>> _removalAnimations = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    
    // Dispose all animation controllers
    for (final controller in _removalControllers.values) {
      controller.dispose();
    }
    _removalControllers.clear();
    _removalAnimations.clear();
    
    super.dispose();
  }

  /// Loads recommendations for the current user
  Future<void> _loadRecommendations() async {
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final recommendationsProvider = Provider.of<RecommendationsProvider>(context, listen: false);
      
      if (authProvider.userData != null) {
        recommendationsProvider.setCurrentUser(authProvider.userData!);
        
        // Only load if we don't have recommendations yet (show cached data immediately)
        if (recommendationsProvider.recommendations.isEmpty) {
        await recommendationsProvider.loadPersonalizedRecommendations();
        } else {
          // User already has recommendations cached, refresh in background
          recommendationsProvider.loadPersonalizedRecommendations(refresh: true);
        }
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
    final recommendationsProvider = Provider.of<RecommendationsProvider>(context, listen: false);
    
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
    final recommendationsProvider = Provider.of<RecommendationsProvider>(context, listen: false);
    
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
      final recommendationsProvider = Provider.of<RecommendationsProvider>(context, listen: false);
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
          'Discover Movies',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        actions: [
          // Enhanced recommendation controls
          IconButton(
            icon: const Icon(
              Icons.tune,
              color: Colors.white,
            ),
            onPressed: _showSmartFilters,
            tooltip: 'Smart filters',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _refineRecommendations,
            tooltip: 'Refine recommendations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Smart filters bar
          if (_smartFilters.isNotEmpty) _buildSmartFiltersBar(),
          
          // Filter selector (multi-select)
          _buildFilterSelector(),
          
          // Main content - single list based on selected filters
          Expanded(
            child: Consumer<RecommendationsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildEnhancedLoadingState();
                }
                
                if (provider.error != null) {
                  return _buildErrorState(provider.error!);
                }
                
                return _buildFilteredRecommendationsList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds smart filters bar
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
            backgroundColor: AppTheme.primaryRed.withOpacity(0.2),
            labelStyle: const TextStyle(color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  /// Builds filter selector with multi-select capability (navbar style)
  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cinemaRed,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  color: AppTheme.primaryRed.withOpacity(0.7),
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
  Widget _buildFilteredRecommendationsList(RecommendationsProvider provider) {
    // Combine movies from selected filters
    final Set<int> seenIds = {};
    final List<Movie> combinedMovies = [];
    
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
    
    // Determine the type label based on selected filters
    String typeLabel = 'Recommendations';
    if (_selectedFilters.length == 1) {
      if (_selectedFilters.contains('forYou')) typeLabel = 'For You';
      else if (_selectedFilters.contains('trending')) typeLabel = 'Trending';
      else if (_selectedFilters.contains('mood')) typeLabel = 'Mood';
      else if (_selectedFilters.contains('similar')) typeLabel = 'Similar';
    } else {
      typeLabel = 'Filtered';
    }
    
    return _buildRecommendationsList(combinedMovies, typeLabel);
  }

  /// Builds enhanced recommendations list with explanations
  Widget _buildRecommendationsList(List<Movie> movies, String type) {
    if (movies.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _buildEnhancedMovieCard(movie, type, index);
      },
    );
  }

  /// Builds enhanced movie card with recommendation explanations
  Widget _buildEnhancedMovieCard(Movie movie, String type, int index) {
    final isAnimating = _removalAnimations.containsKey(movie.id);
    final animation = isAnimating ? _removalAnimations[movie.id]! : null;
    
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.2),
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
      default:
        return 'AI-powered recommendation for you';
    }
  }

  /// Gets genre name from ID
  String _getGenreName(int genreId) {
    final genreMap = {
      28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy',
      80: 'Crime', 99: 'Documentary', 18: 'Drama', 10751: 'Family',
      14: 'Fantasy', 36: 'History', 27: 'Horror', 10402: 'Music',
      9648: 'Mystery', 10749: 'Romance', 878: 'Sci-Fi', 10770: 'TV Movie',
      53: 'Thriller', 10752: 'War', 37: 'Western'
    };
    return genreMap[genreId] ?? 'Unknown';
  }

  /// Shows smart filters dialog
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
    final provider = Provider.of<RecommendationsProvider>(context, listen: false);
    // This would filter the recommendations based on smart filters
    // Implementation depends on your filtering logic
  }

  /// Refines recommendations with AI
  void _refineRecommendations() {
    setState(() {
      _isRefiningRecommendations = true;
    });
    
    final provider = Provider.of<RecommendationsProvider>(context, listen: false);
    provider.loadPersonalizedRecommendations(refresh: true).then((_) {
      setState(() {
        _isRefiningRecommendations = false;
      });
    });
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
          Text(
            'Error loading recommendations',
            style: const TextStyle(
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
              final provider = Provider.of<RecommendationsProvider>(context, listen: false);
              provider.loadPersonalizedRecommendations(refresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
} 