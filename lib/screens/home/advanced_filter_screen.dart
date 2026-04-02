import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../services/filter_service.dart';
import '../../utils/theme.dart';

/// Advanced filter screen with comprehensive filtering and sorting options
class AdvancedFilterScreen extends StatefulWidget {
  final List<Movie> movies;
  final Function(List<Movie>) onFilterApplied;
  final Map<String, dynamic>? initialFilters;

  const AdvancedFilterScreen({
    super.key,
    required this.movies,
    required this.onFilterApplied,
    this.initialFilters,
  });

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Filter states
  Map<String, dynamic> _filters = {};
  List<Movie> _filteredMovies = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filters =
        widget.initialFilters ?? FilterService.instance.getDefaultFilters();
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Applies current filters to movies
  void _applyFilters() {
    setState(() {
      _isFiltering = true;
    });

    // Apply filters
    _filteredMovies = FilterService.instance.filterMovies(
      widget.movies,
      genres: _filters['genres'] as List<int>?,
      minYear: _filters['minYear'] as int?,
      maxYear: _filters['maxYear'] as int?,
      minRating: _filters['minRating'] as double?,
      maxRating: _filters['maxRating'] as double?,
      minRuntime: _filters['minRuntime'] as int?,
      maxRuntime: _filters['maxRuntime'] as int?,
      languages: _filters['languages'] as List<String>?,
      includeAdult: _filters['includeAdult'] as bool?,
      availableOnly: _filters['availableOnly'] as bool?,
    );

    // Apply sorting
    _filteredMovies = FilterService.instance.sortMovies(
      _filteredMovies,
      _filters['sortBy'] as String,
      ascending: _filters['ascending'] as bool,
    );

    setState(() {
      _isFiltering = false;
    });
  }

  /// Updates a filter value
  void _updateFilter(String key, dynamic value) {
    setState(() {
      _filters[key] = value;
    });
    _applyFilters();
  }

  /// Resets all filters
  void _resetFilters() {
    setState(() {
      _filters = FilterService.instance.getDefaultFilters();
    });
    _applyFilters();
  }

  /// Applies filters and returns to previous screen
  void _applyAndReturn() {
    widget.onFilterApplied(_filteredMovies);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Advanced Filters'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(color: AppTheme.primaryRed),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter summary
          _buildFilterSummary(),

          // Tab bar
          _buildTabBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFilterTab(),
                _buildSortTab(),
                _buildResultsTab(),
              ],
            ),
          ),

          // Apply button
          _buildApplyButton(),
        ],
      ),
    );
  }

  /// Builds the filter summary
  Widget _buildFilterSummary() {
    final summary = FilterService.instance.createFilterSummary(
      genres: _filters['genres'] as List<int>?,
      minYear: _filters['minYear'] as int?,
      maxYear: _filters['maxYear'] as int?,
      minRating: _filters['minRating'] as double?,
      maxRating: _filters['maxRating'] as double?,
      languages: _filters['languages'] as List<String>?,
      includeAdult: _filters['includeAdult'] as bool?,
      availableOnly: _filters['availableOnly'] as bool?,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: AppTheme.primaryRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '${_filteredMovies.length} results',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        tabs: const [
          Tab(text: 'Filters'),
          Tab(text: 'Sort'),
          Tab(text: 'Results'),
        ],
      ),
    );
  }

  /// Builds the filters tab
  Widget _buildFilterTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre filter
          _buildGenreFilter(),

          const SizedBox(height: 24),

          // Year filter
          _buildYearFilter(),

          const SizedBox(height: 24),

          // Rating filter
          _buildRatingFilter(),

          const SizedBox(height: 24),

          // Language filter
          _buildLanguageFilter(),

          const SizedBox(height: 24),

          // Content filter
          _buildContentFilter(),

          const SizedBox(height: 24),

          // Availability filter
          _buildAvailabilityFilter(),
        ],
      ),
    );
  }

  /// Builds the sort tab
  Widget _buildSortTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          ...FilterService.sortOptions
              .map((option) => _buildSortOption(option)),

          const SizedBox(height: 24),

          // Sort direction
          Row(
            children: [
              Text(
                'Sort Direction:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Descending'),
                selected: !(_filters['ascending'] as bool),
                onSelected: (selected) {
                  if (selected) _updateFilter('ascending', false);
                },
                selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryRed,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ascending'),
                selected: _filters['ascending'] as bool,
                onSelected: (selected) {
                  if (selected) _updateFilter('ascending', true);
                },
                selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the results tab
  Widget _buildResultsTab() {
    if (_isFiltering) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
        ),
      );
    }

    if (_filteredMovies.isEmpty) {
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
              'No movies match your filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMovies.length,
      itemBuilder: (context, index) {
        return _buildMovieListItem(_filteredMovies[index]);
      },
    );
  }

  /// Builds the apply button
  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applyAndReturn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Apply Filters (${_filteredMovies.length} movies)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// Builds genre filter
  Widget _buildGenreFilter() {
    final movieProvider = Provider.of<MovieProvider>(context);
    final genres = movieProvider.genres;
    final selectedGenres = _filters['genres'] as List<int>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.entries.map((entry) {
            final isSelected = selectedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                final newGenres = List<int>.from(selectedGenres);
                if (selected) {
                  newGenres.add(entry.key);
                } else {
                  newGenres.remove(entry.key);
                }
                _updateFilter('genres', newGenres);
              },
              selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryRed,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds year filter
  Widget _buildYearFilter() {
    final years = FilterService.instance.getAvailableYears(widget.movies);
    final minYear = _filters['minYear'] as int?;
    final maxYear = _filters['maxYear'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: minYear,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...years.map((year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      )),
                ],
                onChanged: (value) => _updateFilter('minYear', value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: maxYear,
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...years.map((year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      )),
                ],
                onChanged: (value) => _updateFilter('maxYear', value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds rating filter
  Widget _buildRatingFilter() {
    final ratings = FilterService.instance.getAvailableRatings(widget.movies);
    final minRating = _filters['minRating'] as double?;
    final maxRating = _filters['maxRating'] as double?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: minRating,
                decoration: const InputDecoration(
                  labelText: 'Min Rating',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<double>(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...ratings.map((rating) => DropdownMenuItem<double>(
                        value: rating,
                        child: Text('${rating.toStringAsFixed(1)}+'),
                      )),
                ],
                onChanged: (value) => _updateFilter('minRating', value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<double>(
                initialValue: maxRating,
                decoration: const InputDecoration(
                  labelText: 'Max Rating',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<double>(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...ratings.map((rating) => DropdownMenuItem<double>(
                        value: rating,
                        child: Text('Up to ${rating.toStringAsFixed(1)}'),
                      )),
                ],
                onChanged: (value) => _updateFilter('maxRating', value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds language filter
  Widget _buildLanguageFilter() {
    final languages =
        FilterService.instance.getAvailableLanguages(widget.movies);
    final selectedLanguages = _filters['languages'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((language) {
            final isSelected = selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                final newLanguages = List<String>.from(selectedLanguages);
                if (selected) {
                  newLanguages.add(language);
                } else {
                  newLanguages.remove(language);
                }
                _updateFilter('languages', newLanguages);
              },
              selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryRed,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds content filter
  Widget _buildContentFilter() {
    final includeAdult = _filters['includeAdult'] as bool?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ChoiceChip(
              label: const Text('All Content'),
              selected: includeAdult == null,
              onSelected: (selected) {
                if (selected) _updateFilter('includeAdult', null);
              },
              selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryRed,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Family Friendly'),
              selected: includeAdult == false,
              onSelected: (selected) {
                if (selected) _updateFilter('includeAdult', false);
              },
              selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryRed,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Adult Content'),
              selected: includeAdult == true,
              onSelected: (selected) {
                if (selected) _updateFilter('includeAdult', true);
              },
              selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryRed,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds availability filter
  Widget _buildAvailabilityFilter() {
    final availableOnly = _filters['availableOnly'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show only available to stream'),
          subtitle:
              const Text('Temporarily unavailable in this build'),
          value: availableOnly,
          onChanged: null,
          activeThumbColor: AppTheme.primaryRed,
        ),
      ],
    );
  }

  /// Builds sort option
  Widget _buildSortOption(String option) {
    final displayName = _getSortDisplayName(option);

    return RadioListTile<String>(
      title: Text(displayName),
      value: option,
      // ignore: deprecated_member_use
      groupValue: _filters['sortBy'] as String,
      // ignore: deprecated_member_use
      onChanged: (value) {
        if (value != null) _updateFilter('sortBy', value);
      },
      activeColor: AppTheme.primaryRed,
    );
  }

  /// Gets display name for sort option
  String _getSortDisplayName(String option) {
    switch (option) {
      case 'relevance':
        return 'Relevance';
      case 'rating':
        return 'Rating';
      case 'year':
        return 'Year';
      case 'title':
        return 'Title';
      case 'popularity':
        return 'Popularity';
      case 'runtime':
        return 'Runtime';
      case 'release_date':
        return 'Release Date';
      default:
        return option;
    }
  }

  /// Builds movie list item
  Widget _buildMovieListItem(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 50,
            height: 75,
            child: Image.network(
              movie.posterUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.movie, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        title: Text(
          movie.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movie.year != null) Text(movie.year!),
            if (movie.voteAverage != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(movie.voteAverage!.toStringAsFixed(1)),
                ],
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
