import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/mood.dart';
import '../../models/streaming_platform.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../services/movie_cache_service.dart';
import '../../services/user_preference_analyzer.dart';
import '../../services/behavior_tracking_service.dart';
import '../../services/collaborative_filtering_service.dart';
import '../../services/adaptive_weighting_service.dart';
import 'movie_detail_screen.dart';
import '../../widgets/retro_cinema_movie_card.dart';
import '../../widgets/retro_cinema_show_card.dart';
import '../../widgets/match_success_screen.dart';

/// Main swiping screen with Retro Cinema aesthetic
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> with SingleTickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  late TabController _tabController;
  int _currentTabIndex = 0; // 0 = Movies, 1 = Shows
  
  /// Reloads movies when filters change
  Future<void> _reloadMoviesWithFilters() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();
      
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        // Use curated starter movies for new users
        await movieProvider.loadCuratedStarterMovies(refresh: true);
      }
    } else {
      // Use curated starter movies for users not logged in
      await movieProvider.loadCuratedStarterMovies(refresh: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Load content for the selected tab
        if (_tabController.index == 0) {
          _loadMovies();
        } else {
          _loadShows();
        }
      }
    });
    // Defer movie loading until after screen renders to prevent freezing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMovies();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads movies for swiping - deferred until after screen renders
  Future<void> _loadMovies() async {
    if (!mounted) return;
    
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Small delay to ensure transition completes and auth is initialized
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!mounted) return;
    
    // Ensure auth provider is initialized (user data might still be loading)
    if (authProvider.isLoading) {
      // Wait a bit more for auth to finish loading
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;
    
    // Always check user preferences and load appropriate recommendations
    // This ensures personalized recommendations are loaded even after app restart
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      
      // Auto-apply streaming platforms from user preferences if not already set
      final selectedPlatforms = user.preferences['selectedPlatforms'] as List<dynamic>?;
      if (selectedPlatforms != null && selectedPlatforms.isNotEmpty) {
        final platformList = selectedPlatforms.map((p) => p.toString()).toList();
        // Only set if not already set (to avoid overriding manual filter changes)
        if (movieProvider.swipeSelectedPlatforms.isEmpty) {
          movieProvider.setSwipePlatforms(platformList);
        }
      }
      
      final analyzer = UserPreferenceAnalyzer();
      
      // Always use personalized recommendations if user has enough data
      // This ensures the app shows personalized content even after restart
      // Use refresh: true to replace any existing movies (like popular movies from splash)
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        // For new users, use curated starter movies to maximize learning efficiency
        // This provides diverse genres, time periods, and ratings for better preference learning
        // Always refresh to replace any popular movies loaded during initialization
        await movieProvider.loadCuratedStarterMovies(refresh: true);
      }
    } else {
      // No user logged in, use curated starter movies for better initial experience
      // Always refresh to replace any popular movies loaded during initialization
      await movieProvider.loadCuratedStarterMovies(refresh: true);
    }
  }

  /// Handles movie swipe actions:
  /// - Right swipe = Like
  /// - Left swipe = Dislike
  /// - Up swipe = Match (shows match screen with options)
  /// - Down swipe = Skip (neutral action, doesn't like or dislike)
  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    // Allow left, right, up, and down swipes
    if (direction != CardSwiperDirection.left && 
        direction != CardSwiperDirection.right && 
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false; // Block other directions
    }

    if (previousIndex >= 0) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (previousIndex < movieProvider.filteredMovies.length) {
        final movie = movieProvider.filteredMovies[previousIndex];
        
        if (direction == CardSwiperDirection.right) {
          // Like action - add to liked movie
          final likedCountBefore = authProvider.userData?.likedMovies.length ?? 0;
          authProvider.addLikedMovie(movie.id.toString());
          
          // Track behavior and collaborative filtering
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'like');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);
          
          // ENHANCED: Record feedback for adaptive weighting
          final user = authProvider.userData;
          if (user != null) {
            // Determine which strategy likely led to this recommendation
            // For now, record as 'contentBased' (can be enhanced to track actual strategy)
            AdaptiveWeightingService().recordFeedback(
              strategy: 'contentBased', // TODO: Track actual strategy used
              liked: true,
              user: user,
            );
          }
          
          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);
            
            // If user just crossed 3+ likes threshold or has enough data, refresh immediately
            if (hasEnoughData && (likedCountBefore < 3 || updatedUser.likedMovies.length <= 5)) {
              // Refresh recommendations in background without disrupting current view
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false, // Add to end, not front
                    backgroundLoad: true, // Load in background without UI disruption
                  );
                }
              });
            } else {
              // Otherwise, use the standard refresh logic
              _refreshRecommendationsIfNeeded();
            }
          }
        } else if (direction == CardSwiperDirection.left) {
          // Dislike action - add to disliked movies
          authProvider.addDislikedMovie(movie.id.toString());
          
          // Track behavior
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'dislike');
          CollaborativeFilteringService().recordUserDislike(userId, movie.id);
          
          // ENHANCED: Record negative feedback for adaptive weighting
          final user = authProvider.userData;
          if (user != null) {
            AdaptiveWeightingService().recordFeedback(
              strategy: 'contentBased', // TODO: Track actual strategy used
              liked: false,
              user: user,
            );
          }
        } else if (direction == CardSwiperDirection.bottom) {
          // Skip action - neutral, doesn't like or dislike
          // Just track the skip behavior for learning
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'skip');
          // Don't add to liked/disliked lists, don't trigger recommendations
        } else if (direction == CardSwiperDirection.top) {
          // Match action - show match success screen with options
          final likedCountBefore = authProvider.userData?.likedMovies.length ?? 0;
          authProvider.addLikedMovie(movie.id.toString());
          
          // Track behavior and collaborative filtering
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, movie.id, 'match');
          CollaborativeFilteringService().recordUserLike(userId, movie.id);
          
          // Get updated user to check if we crossed threshold
          final updatedUser = authProvider.userData;
          if (updatedUser != null) {
            final analyzer = UserPreferenceAnalyzer();
            final hasEnoughData = analyzer.hasEnoughData(updatedUser);
            
            // If user just crossed 3+ likes threshold or has enough data, refresh immediately
            if (hasEnoughData && (likedCountBefore < 3 || updatedUser.likedMovies.length <= 5)) {
              // Refresh recommendations in background without disrupting current view
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  movieProvider.loadPersonalizedRecommendations(
                    updatedUser,
                    refresh: false,
                    insertAtFront: false, // Add to end, not front
                    backgroundLoad: true, // Load in background without UI disruption
                  );
                }
              });
            } else {
              // Otherwise, use the standard refresh logic
              _refreshRecommendationsIfNeeded();
            }
        }
        
          // Show match success screen after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              showMatchSuccessScreen(
                context,
                movie,
                onContinue: () {
                  Navigator.of(context).pop();
                },
                onViewDetails: () async {
                  // Preload movie details before navigation
                  await MovieCacheService.instance.preloadMovieDetails(movie.id);
                  
                  // Replace match success screen with movie detail screen directly
                  // This avoids the delay from pop animation + push animation
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
                    );
                  }
                },
                onAddToWatchlist: () {
                  Navigator.of(context).pop();
                  authProvider.addToWatchlist(movie.id.toString());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${movie.title} to watchlist'),
                      backgroundColor: AppTheme.fadedCurtain,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            }
          });
        }
      }
    }
    
    return true; // Allow the swipe to complete
  }

  /// Refreshes recommendations if user has enough data and we're running low on movies
  void _refreshRecommendationsIfNeeded() {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only refresh if user is logged in
    if (authProvider.userData == null) return;
    
    final user = authProvider.userData!;
    final analyzer = UserPreferenceAnalyzer();
    
    // Check if user just crossed the threshold for personalized recommendations
    final hasEnoughData = analyzer.hasEnoughData(user);
    final remainingMovies = movieProvider.filteredMovies.length;
    
    // Refresh more aggressively:
    // 1. If user just reached 3+ likes (crossed threshold), refresh immediately
    // 2. If user has enough data and less than 15 movies left, refresh
    // 3. Load in background and add to end so they appear behind current cards
    if (hasEnoughData && (remainingMovies < 15 || user.likedMovies.length == 3)) {
      // Refresh in background without disrupting current view
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Load in background and add to end so current card doesn't disappear
          movieProvider.loadPersonalizedRecommendations(
            user, 
            refresh: false, 
            insertAtFront: false, // Add to end, not front
            backgroundLoad: true, // Load in background without UI disruption
          );
        }
      });
    }
  }

  /// Handles movie card tap to show details
  void _onMovieTap(Movie movie) async {
    // Preload movie details in the background before navigation
    // This way the detail screen can use cached data instantly
    MovieCacheService.instance.preloadMovieDetails(movie.id);
    
    // Small delay to allow preload to start, then navigate
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (mounted) {
    Navigator.of(context).push(
        NavigationUtils.fastSlideRoute(MovieDetailScreen(movie: movie)),
    );
    }
  }

  /// Loads shows for swiping
  Future<void> _loadShows() async {
    if (!mounted) return;
    
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (!mounted) return;
    
    if (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;
    
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();
      
      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        await showProvider.loadCuratedStarterShows(refresh: true);
      }
    } else {
      await showProvider.loadCuratedStarterShows(refresh: true);
    }
  }

  /// Refreshes the movie list
  Future<void> _refreshMovies() async {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();
      
      if (analyzer.hasEnoughData(user)) {
        await movieProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        // New users get curated starter movies
        await movieProvider.loadCuratedStarterMovies(refresh: true);
      }
    } else {
      // No user logged in, use curated starter movies
      await movieProvider.loadCuratedStarterMovies(refresh: true);
    }
  }

  /// Refreshes the show list
  Future<void> _refreshShows() async {
    final showProvider = Provider.of<ShowProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userData != null) {
      final user = authProvider.userData!;
      final analyzer = UserPreferenceAnalyzer();
      
      if (analyzer.hasEnoughData(user)) {
        await showProvider.loadPersonalizedRecommendations(user, refresh: true);
      } else {
        await showProvider.loadCuratedStarterShows(refresh: true);
      }
    } else {
      await showProvider.loadCuratedStarterShows(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper, // Changed to Vintage Paper from guide
      appBar: AppBar(
        title: Text(
          'DISCOVER',
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
        actions: [
          // Filter icon with badge if filters are active
          _currentTabIndex == 0
              ? Consumer<MovieProvider>(
                  builder: (context, movieProvider, child) {
                    final hasActiveFilters = movieProvider.swipeMoods.isNotEmpty ||
                        movieProvider.swipeSelectedGenres.isNotEmpty ||
                        movieProvider.swipeSelectedPlatforms.isNotEmpty;
                    
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: AppTheme.warmCream,
                          ),
                          onPressed: () => _showFilterMenu(movieProvider),
                          tooltip: 'Filters',
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.popcornGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                )
              : Consumer<ShowProvider>(
                  builder: (context, showProvider, child) {
                    final hasActiveFilters = showProvider.swipeMoods.isNotEmpty ||
                        showProvider.swipeSelectedGenres.isNotEmpty ||
                        showProvider.swipeSelectedPlatforms.isNotEmpty;
                    
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.tune,
                            color: AppTheme.warmCream,
                          ),
                          onPressed: () => _showShowFilterMenu(showProvider),
                          tooltip: 'Filters',
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.popcornGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
          // Refresh button
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.warmCream,
            ),
            onPressed: () => _currentTabIndex == 0 ? _refreshMovies() : _refreshShows(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe-to-switch tabs to prevent interference with card swiping
          children: [
            // Movies Tab
            _buildMoviesTab(),
            // Shows Tab
            _buildShowsTab(),
          ],
        ),
      ),
    );
  }

  /// Builds the movies tab content
  Widget _buildMoviesTab() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
            // Show screen immediately even while loading
            // Cards will appear as soon as movies are loaded
            if (movieProvider.isLoading && movieProvider.filteredMovies.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cinemaRed),
          ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading movies...',
                      style: TextStyle(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
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
                      Icons.movie_outlined,
                    size: 64,
                      color: AppTheme.filmStripBlack.withValues(alpha: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No movies found',
                      style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Try refreshing to load more movies',
                      style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshMovies,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

            return Column(
              children: [
                // Swipe cards area with stacked cards effect
                Expanded(
                  child: Container(
                    color: AppTheme.vintagePaper, // Background color from guide
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: CardSwiper(
                        controller: controller,
                        cardsCount: movieProvider.filteredMovies.length,
                        onSwipe: _onSwipe,
                        numberOfCardsDisplayed: 3, // Show 3 cards stacked
                        threshold: 50, // Minimum distance to trigger swipe
                        isLoop: false,
                        duration: const Duration(milliseconds: 400), // Smoother animation duration
                        scale: 0.92, // Scale of cards behind the front card (slightly larger for better visibility)
                        backCardOffset: const Offset(0, 8), // Small vertical offset for depth
                        allowedSwipeDirection: const AllowedSwipeDirection.only(
                          left: true,
                          right: true,
                          up: true,
                          down: true,
                        ),
                        cardBuilder: (context, index, horizontalThresholdPercentage,
                            verticalThresholdPercentage) {
                          final movie = movieProvider.filteredMovies[index];
                          
                          // Track movie view for behavior analysis
                          BehaviorTrackingService().recordMovieView(movie.id);
                          
                          return RetroCinemaMovieCard(
                            movie: movie,
                            onTap: () {
                              // Track detail view
                              final startTime = DateTime.now();
                              BehaviorTrackingService().recordDetailView(movie.id, startTime: startTime);
                              _onMovieTap(movie);
                            },
                            onLike: () => controller.swipeRight(),
                            onDislike: () => controller.swipeLeft(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  /// Builds the shows tab content
  Widget _buildShowsTab() {
    return Consumer<ShowProvider>(
      builder: (context, showProvider, child) {
        if (showProvider.isLoading && showProvider.filteredShows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cinemaRed),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading shows...',
                  style: TextStyle(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (showProvider.filteredShows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv_outlined,
                  size: 64,
                  color: AppTheme.filmStripBlack.withValues(alpha: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No shows found',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try refreshing to load more shows',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshShows,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.vintagePaper,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                  child: CardSwiper(
                    controller: controller,
                    cardsCount: showProvider.filteredShows.length,
                    onSwipe: _onShowSwipe,
                    numberOfCardsDisplayed: 3,
                    threshold: 50,
                    isLoop: false,
                    duration: const Duration(milliseconds: 400),
                    scale: 0.92,
                    backCardOffset: const Offset(0, 8),
                    allowedSwipeDirection: const AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                      up: true,
                      down: true,
                    ),
                    cardBuilder: (context, index, horizontalThresholdPercentage,
                        verticalThresholdPercentage) {
                      final show = showProvider.filteredShows[index];
                      
                      BehaviorTrackingService().recordMovieView(show.id);
                      
                      return RetroCinemaShowCard(
                        show: show,
                        onTap: () {
                          final startTime = DateTime.now();
                          BehaviorTrackingService().recordDetailView(show.id, startTime: startTime);
                          _onShowTap(show);
                        },
                        onLike: () => controller.swipeRight(),
                        onDislike: () => controller.swipeLeft(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handles show swipe actions
  Future<bool> _onShowSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (direction != CardSwiperDirection.left && 
        direction != CardSwiperDirection.right && 
        direction != CardSwiperDirection.top &&
        direction != CardSwiperDirection.bottom) {
      return false;
    }

    if (previousIndex >= 0) {
      final showProvider = Provider.of<ShowProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (previousIndex < showProvider.filteredShows.length) {
        final show = showProvider.filteredShows[previousIndex];
        
        if (direction == CardSwiperDirection.right) {
          authProvider.addLikedShow(show.id.toString());
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, show.id, 'like');
        } else if (direction == CardSwiperDirection.left) {
          authProvider.addDislikedShow(show.id.toString());
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, show.id, 'dislike');
        } else if (direction == CardSwiperDirection.bottom) {
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, show.id, 'skip');
        } else if (direction == CardSwiperDirection.top) {
          authProvider.addLikedShow(show.id.toString());
          final userId = authProvider.userData?.id ?? '';
          BehaviorTrackingService().recordSwipe(userId, show.id, 'match');
        }
      }
    }
    
    return true;
  }

  /// Handles show card tap
  void _onShowTap(TvShow show) async {
    // TODO: Navigate to show detail screen when created
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Show details coming soon: ${show.name}'),
        backgroundColor: AppTheme.fadedCurtain,
      ),
    );
  }

  /// Shows filter menu for shows
  void _showShowFilterMenu(ShowProvider showProvider) {
    // Similar to _showFilterMenu but for shows
    // For now, use the same filter menu structure
    _showFilterMenu(Provider.of<MovieProvider>(context, listen: false));
  }

  /// Shows filter menu with all filter options
  void _showFilterMenu(MovieProvider movieProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (movieProvider.swipeMoods.isNotEmpty ||
                    movieProvider.swipeSelectedGenres.isNotEmpty ||
                    movieProvider.swipeSelectedPlatforms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      movieProvider.clearSwipeFilters();
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Mood filter option
            _buildFilterMenuItem(
              'Mood',
              movieProvider.swipeMoods.isNotEmpty
                  ? '${movieProvider.swipeMoods.length} selected'
                  : 'Select moods',
              movieProvider.swipeMoods.isNotEmpty,
              () {
                Navigator.pop(context);
                _showMoodDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Genre filter option
            _buildFilterMenuItem(
              'Genres',
              movieProvider.swipeSelectedGenres.isNotEmpty
                  ? '${movieProvider.swipeSelectedGenres.length} selected'
                  : 'Select genres',
              movieProvider.swipeSelectedGenres.isNotEmpty,
              () {
                Navigator.pop(context);
                _showGenreDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Platform filter option
            _buildFilterMenuItem(
              'Platform',
              movieProvider.swipeSelectedPlatforms.isNotEmpty
                  ? '${movieProvider.swipeSelectedPlatforms.length} selected'
                  : 'Select platforms',
              movieProvider.swipeSelectedPlatforms.isNotEmpty,
              () {
                Navigator.pop(context);
                _showPlatformDialog(movieProvider);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a filter menu item
  Widget _buildFilterMenuItem(
    String title,
    String subtitle,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.cinemaRed.withOpacity(0.3) : AppTheme.fadedCurtain,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.popcornGold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.warmCream,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.warmCream.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.warmCream,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows mood selection dialog with multi-select support
  void _showMoodDialog(MovieProvider movieProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Moods',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (movieProvider.swipeMoods.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      movieProvider.setSwipeMoods([]);
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: Mood.availableMoods.length,
                itemBuilder: (context, index) {
                  final mood = Mood.availableMoods[index];
                  final isSelected = movieProvider.swipeMoods.any((m) => m.id == mood.id);
                  
                  return GestureDetector(
                    onTap: () {
                      final currentMoods = List<Mood>.from(movieProvider.swipeMoods);
                      if (isSelected) {
                        currentMoods.removeWhere((m) => m.id == mood.id);
                      } else {
                        currentMoods.add(mood);
                      }
                      movieProvider.setSwipeMoods(currentMoods);
                      setState(() {}); // Update UI
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.cinemaRed : AppTheme.fadedCurtain,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.popcornGold : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              mood.name,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reloadMoviesWithFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cinemaRed,
                  foregroundColor: AppTheme.warmCream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows genre selection dialog
  void _showGenreDialog(MovieProvider movieProvider) {
    final genres = movieProvider.genres;
    if (genres.isEmpty) {
      // Load genres if not loaded
      movieProvider.loadGenres();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading genres...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Genres',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (movieProvider.swipeSelectedGenres.isNotEmpty)
          TextButton(
            onPressed: () {
                      movieProvider.setSwipeGenres([]);
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
            },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
          ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.entries.map((entry) {
                    final genreId = entry.key;
                    final genreName = entry.value;
                    final isSelected = movieProvider.swipeSelectedGenres.contains(genreId);
                    
                    return GestureDetector(
                      onTap: () {
                        final currentGenres = List<int>.from(movieProvider.swipeSelectedGenres);
                        if (isSelected) {
                          currentGenres.remove(genreId);
                        } else {
                          currentGenres.add(genreId);
                        }
                        movieProvider.setSwipeGenres(currentGenres);
                        setState(() {}); // Update UI
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.cinemaRed : AppTheme.fadedCurtain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.popcornGold : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          genreName,
                          style: TextStyle(
                            color: AppTheme.warmCream,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
          ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
            onPressed: () {
                  Navigator.pop(context);
                  _reloadMoviesWithFilters();
            },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cinemaRed,
                  foregroundColor: AppTheme.warmCream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply'),
              ),
          ),
        ],
        ),
      ),
    );
  }

  /// Shows platform selection dialog
  void _showPlatformDialog(MovieProvider movieProvider) {
    final platforms = StreamingPlatform.availablePlatforms;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Platforms',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (movieProvider.swipeSelectedPlatforms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      movieProvider.setSwipePlatforms([]);
                      Navigator.pop(context);
                      _reloadMoviesWithFilters();
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: platforms.map((platform) {
                    final isSelected = movieProvider.swipeSelectedPlatforms.contains(platform.id);
                    
                    return GestureDetector(
                      onTap: () {
                        final currentPlatforms = List<String>.from(movieProvider.swipeSelectedPlatforms);
                        if (isSelected) {
                          currentPlatforms.remove(platform.id);
                        } else {
                          currentPlatforms.add(platform.id);
                        }
                        movieProvider.setSwipePlatforms(currentPlatforms);
                        setState(() {}); // Update UI
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.cinemaRed : AppTheme.fadedCurtain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.popcornGold : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          platform.name,
                          style: TextStyle(
                            color: AppTheme.warmCream,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
            onPressed: () {
                  Navigator.pop(context);
                  _reloadMoviesWithFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cinemaRed,
                  foregroundColor: AppTheme.warmCream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply'),
              ),
          ),
        ],
        ),
      ),
    );
  }
} 
