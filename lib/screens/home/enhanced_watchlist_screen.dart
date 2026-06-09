import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Unused import
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../models/watchlist_list.dart';
import '../../providers/social_provider.dart';
// import '../../providers/auth_provider.dart'; // Unused import
// import '../../providers/movie_provider.dart'; // Unused import
import '../../services/watchlist_service.dart';
import '../../services/tmdb_service.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import '../../utils/l10n_extension.dart';
import '../../services/movie_cache_service.dart';
import 'movie_detail_screen.dart';
import 'advanced_filter_screen.dart';

/// Enhanced watchlist screen with custom lists and organization features
class EnhancedWatchlistScreen extends StatefulWidget {
  const EnhancedWatchlistScreen({super.key});

  @override
  State<EnhancedWatchlistScreen> createState() =>
      _EnhancedWatchlistScreenState();
}

class _EnhancedWatchlistScreenState extends State<EnhancedWatchlistScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<WatchlistList> _lists = [];
  WatchlistList? _selectedList;
  List<Movie> _movies = [];
  Map<String, List<String>> _movieTags = {};
  List<String> _allTags = [];
  bool _isLoading = true;
  String? _error;

  // Filter and search
  String _searchQuery = '';
  String _selectedTag = '';
  final String _sortBy = 'date_added';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads all watchlist data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load lists
      final lists = await WatchlistService.instance.getLists();

      // Load tags
      final movieTags = await WatchlistService.instance.getMovieTags();
      final allTags = await WatchlistService.instance.getAllTags();

      setState(() {
        _lists = lists;
        _selectedList = lists.isNotEmpty ? lists.first : null;
        _movieTags = movieTags;
        _allTags = allTags;
      });

      await _loadMoviesForSelectedList();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads movies for the selected list
  Future<void> _loadMoviesForSelectedList() async {
    if (_selectedList == null) return;

    try {
      final movieIds = _selectedList!.movieIds;
      final movies = <Movie>[];

      for (final movieId in movieIds) {
        try {
          final movie = await TMDBService().getMovieDetails(int.parse(movieId));
          movies.add(movie);
        } catch (e) {
          // Skip movies that can't be loaded
        }
      }

      // Apply sorting
      movies.sort((a, b) {
        switch (_sortBy) {
          case 'title':
            return a.title.compareTo(b.title);
          case 'year':
            final yearA = int.tryParse(a.year ?? '0') ?? 0;
            final yearB = int.tryParse(b.year ?? '0') ?? 0;
            return yearB.compareTo(yearA);
          case 'rating':
            final ratingA = a.voteAverage ?? 0.0;
            final ratingB = b.voteAverage ?? 0.0;
            return ratingB.compareTo(ratingA);
          case 'date_added':
          default:
            // Keep original order for date added
            return 0;
        }
      });

      setState(() {
        _movies = movies;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  /// Filters movies based on search and tag
  List<Movie> get _filteredMovies {
    return _movies.where((movie) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!movie.title.toLowerCase().contains(query) &&
            !(movie.overview?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Tag filter
      if (_selectedTag.isNotEmpty) {
        final movieTags = _movieTags[movie.id.toString()] ?? [];
        if (!movieTags.contains(_selectedTag)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Handles movie tap
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

  /// Handles list selection
  void _onListSelected(WatchlistList list) {
    setState(() {
      _selectedList = list;
    });
    _loadMoviesForSelectedList();
  }

  /// Creates a new list
  Future<void> _createNewList() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CreateListDialog(),
    );

    if (result != null) {
      final newList = await WatchlistService.instance.createList(
        name: result['name']!,
        description: result['description'],
        color: result['color'],
      );

      if (newList != null) {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.createdListSnackbar(newList.name)),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  /// Shows advanced filters
  void _showAdvancedFilters() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvancedFilterScreen(
          movies: _movies,
          onFilterApplied: (filteredMovies) {
            setState(() {
              _movies = filteredMovies;
            });
          },
        ),
      ),
    );
  }

  /// Exports watchlist data
  Future<void> _exportData() async {
    try {
      await WatchlistService.instance.exportWatchlistData();
      // In a real app, you would share this data or save it to a file
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.exportDataLocalSnackbar),
          backgroundColor: AppTheme.fadedCurtain,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.failedToExportSnackbar(e.toString())),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  /// Shares the currently selected list with a followed friend (chosen from a
  /// bottom sheet). The list snapshot is sent via the shareWatchlist CF.
  Future<void> _shareSelectedList() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final list = _selectedList;
    if (list == null || (list.movieIds.isEmpty && list.showIds.isEmpty)) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.shareListEmptySnackbar),
        backgroundColor: AppTheme.primaryRed,
      ));
      return;
    }

    final social = context.read<SocialProvider>();
    await social.loadFollowing();
    if (!mounted) return;
    final following = social.following;
    if (following.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.shareListNoFriendsSnackbar),
        backgroundColor: AppTheme.primaryRed,
      ));
      return;
    }

    final recipient = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.vintagePaper,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.shareListPickFriendTitle,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: following.map((u) {
                  final name = (u['displayName']?.toString().isNotEmpty ?? false)
                      ? u['displayName'].toString()
                      : l10n.sharedByFallbackName;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(name[0].toUpperCase()),
                    ),
                    title: Text(name),
                    onTap: () => Navigator.of(sheetCtx).pop(u),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (recipient == null || !mounted) return;

    final recipientUid = recipient['uid']?.toString() ?? '';
    final recipientName =
        (recipient['displayName']?.toString().isNotEmpty ?? false)
            ? recipient['displayName'].toString()
            : l10n.sharedByFallbackName;
    if (recipientUid.isEmpty) return;

    try {
      await social.shareWatchlist(
        recipientUid: recipientUid,
        list: {
          'name': list.name,
          'description': list.description,
          'color': list.color,
          'movieIds': list.movieIds,
          'showIds': list.showIds,
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.listSharedSnackbar(recipientName)),
        backgroundColor: AppTheme.popcornGold,
      ));
    } catch (e) {
      debugPrint('shareSelectedList failed: $e');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.shareListFailedSnackbar),
        backgroundColor: AppTheme.primaryRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search and filters
            _buildSearchAndFilters(),

            // Tab bar
            _buildTabBar(),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListsTab(),
                  _buildMoviesTab(),
                  _buildTagsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'watchlist_add_button',
        onPressed: _createNewList,
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Builds the header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(
            Icons.bookmark,
            color: AppTheme.primaryRed,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.myWatchlistTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_movies.length} movies in ${_lists.length} lists',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'filters':
                  _showAdvancedFilters();
                  break;
                case 'share':
                  _shareSelectedList();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.ios_share_rounded),
                    const SizedBox(width: 8),
                    Text(context.l10n.shareListMenuItem),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filters',
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    Text(context.l10n.advancedFiltersTitle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    Text(context.l10n.exportDataButton),
                  ],
                ),
              ),
            ],
            child: Icon(
              Icons.more_vert,
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds search and filters
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: context.l10n.searchMoviesHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // Tag filter
          if (_allTags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(context.l10n.allTagsFilter),
                    selected: _selectedTag.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTag = '';
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  ..._allTags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: _selectedTag == tag,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = selected ? tag : '';
                            });
                          },
                          selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.primaryRed,
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the tab bar
  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryRed,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: AppTheme.primaryRed,
        tabs: [
          Tab(text: context.l10n.listsTab),
          Tab(text: context.l10n.moviesTab),
          Tab(text: context.l10n.tagsTab),
        ],
      ),
    );
  }

  /// Builds the lists tab
  Widget _buildListsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
        ),
      );
    }

    if (_error != null) {
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
              context.l10n.errorLoadingLists,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(context.l10n.retryButton),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lists.length,
      itemBuilder: (context, index) {
        final list = _lists[index];
        final isSelected = _selectedList?.id == list.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryRed.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryRed
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryRed,
              child: Text(
                list.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              list.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(list.displayDescription),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${list.movieCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            onTap: () => _onListSelected(list),
          ),
        );
      },
    );
  }

  /// Builds the movies tab
  Widget _buildMoviesTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
        ),
      );
    }

    final filteredMovies = _filteredMovies;

    if (filteredMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedTag.isNotEmpty
                  ? context.l10n.noMoviesMatchFiltersShort
                  : context.l10n.noMoviesInList,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedTag.isNotEmpty
                  ? context.l10n.tryAdjustingSearchOrFilters
                  : context.l10n.addSomeMovies,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
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
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredMovies.length,
      itemBuilder: (context, index) {
        return _buildMovieCard(filteredMovies[index]);
      },
    );
  }

  /// Builds the tags tab
  Widget _buildTagsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
        ),
      );
    }

    if (_allTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noTagsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.addTagsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allTags.length,
      itemBuilder: (context, index) {
        final tag = _allTags[index];
        final moviesWithTag =
            _movieTags.values.where((tags) => tags.contains(tag)).length;

        return ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
            child: Icon(
              Icons.label,
              color: AppTheme.primaryRed,
            ),
          ),
          title: Text(
            tag,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle:
              Text('$moviesWithTag movie${moviesWithTag == 1 ? '' : 's'}'),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          onTap: () {
            setState(() {
              _selectedTag = tag;
            });
            _tabController.animateTo(1); // Switch to movies tab
          },
        );
      },
    );
  }

  /// Builds a movie card
  Widget _buildMovieCard(Movie movie) {
    final movieTags = _movieTags[movie.id.toString()] ?? [];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie poster
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: TMDBService.getImageUrl(movie.posterPath,
                            size: 'w300'),
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

                  // Tags indicator
                  if (movieTags.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${movieTags.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Rating badge
                  if (movie.voteAverage != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              movie.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Tags preview
                  if (movieTags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: movieTags
                          .take(2)
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: AppTheme.primaryRed,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a new list
class _CreateListDialog extends StatefulWidget {
  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#FF0000';

  final List<String> _colors = [
    '#FF0000',
    '#00FF00',
    '#0000FF',
    '#FFFF00',
    '#FF00FF',
    '#00FFFF',
    '#FFA500',
    '#800080',
    '#008000',
    '#FFC0CB',
    '#A52A2A',
    '#808080',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.createNewListTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.listNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.listNameError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.listDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Choose a color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors
                  .map((color) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                Color(int.parse(color.replaceAll('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'description': _descriptionController.text,
                'color': _selectedColor,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.createButton),
        ),
      ],
    );
  }
}
