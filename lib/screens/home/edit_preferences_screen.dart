import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/streaming_platform.dart';
import '../../providers/auth_provider.dart';
import '../../providers/movie_provider.dart';
import '../../utils/theme.dart';
import '../../utils/l10n_extension.dart';

/// Screen for editing user preferences (genres and streaming platforms)
class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selected preferences (loaded from user data). Platforms are canonical ids.
  late Set<int> _selectedGenres;
  late Set<String> _selectedPlatforms;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Loads user preferences from auth provider
  void _loadUserPreferences() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userData;

    if (user != null) {
      // Load genres
      final savedGenres = user.preferences['selectedGenres'] as List<dynamic>?;
      _selectedGenres = savedGenres != null
          ? Set<int>.from(savedGenres.map((g) => g as int))
          : <int>{};

      // Load platforms, normalizing any legacy display-name values to canonical
      // ids so the checked-state matches StreamingPlatform.availablePlatforms.
      final savedPlatforms =
          user.preferences['selectedPlatforms'] as List<dynamic>?;
      _selectedPlatforms = savedPlatforms != null
          ? savedPlatforms
              .map((p) => StreamingPlatform.idFromNameOrId(p.toString()))
              .whereType<String>()
              .toSet()
          : <String>{};
    } else {
      _selectedGenres = <int>{};
      _selectedPlatforms = <String>{};
    }
  }

  /// Saves user preferences and navigates back
  Future<void> _savePreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get current preferences and merge with new selections
    final currentPreferences =
        Map<String, dynamic>.from(authProvider.userData?.preferences ?? {});
    currentPreferences['selectedGenres'] = _selectedGenres.toList();
    currentPreferences['selectedPlatforms'] = _selectedPlatforms.toList();

    // Save preferences
    await authProvider.updatePreferences(currentPreferences);
    if (!mounted) return;

    // Apply streaming platforms to movie provider if any are selected
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    if (_selectedPlatforms.isNotEmpty) {
      movieProvider.setSwipePlatforms(_selectedPlatforms.toList());
    } else {
      // Clear platforms if none selected
      movieProvider.clearSwipeFilters();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.preferencesSavedSnackbar),
          backgroundColor: AppTheme.fadedCurtain,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  /// Toggles genre selection
  void _toggleGenre(int genreId) {
    setState(() {
      if (_selectedGenres.contains(genreId)) {
        _selectedGenres.remove(genreId);
      } else {
        _selectedGenres.add(genreId);
      }
    });
  }

  /// Toggles platform selection
  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppTheme.deepMidnightBrown,
      appBar: AppBar(
        title: Text(l10n.editPreferencesAppBarTitle),
        backgroundColor: AppTheme.deepMidnightBrown,
        foregroundColor: AppTheme.warmCream,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 2,
              backgroundColor: AppTheme.warmCream.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildGenreSelectionPage(),
                  _buildPlatformSelectionPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.fadedCurtain,
                        foregroundColor: AppTheme.filmStripBlack,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(l10n.backButton),
                    )
                  else
                    const SizedBox(width: 80),
                  Text(
                    l10n.pageIndicatorOf2(_currentPage + 1),
                    style: TextStyle(
                      color: AppTheme.warmCream.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _currentPage == 1
                        ? _savePreferences
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_currentPage == 1 ? l10n.saveButton : l10n.nextButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genre selection page
  Widget _buildGenreSelectionPage() {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.genrePageTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warmCream,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.genrePageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.warmCream.withValues(alpha: 0.9),
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: movieProvider.genres.length,
                  itemBuilder: (context, index) {
                    final genre = movieProvider.genres.entries.elementAt(index);
                    final isSelected = _selectedGenres.contains(genre.key);

                    return GestureDetector(
                      onTap: () => _toggleGenre(genre.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryRed.withValues(alpha: 0.25)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryRed
                                : AppTheme.warmCream.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            genre.value,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.popcornGold
                                  : AppTheme.warmCream,
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
          ),
        );
      },
    );
  }

  /// Platform selection page
  Widget _buildPlatformSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.platformPageTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warmCream,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.platformPageSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warmCream.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: StreamingPlatform.availablePlatforms.length,
              itemBuilder: (context, index) {
                final platform = StreamingPlatform.availablePlatforms[index];
                final isSelected = _selectedPlatforms.contains(platform.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryRed.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.warmCream.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.warmCream.withValues(alpha: 0.7),
                    ),
                    title: Text(
                      platform.name,
                      style: const TextStyle(
                        color: AppTheme.warmCream,
                      ),
                    ),
                    onTap: () => _togglePlatform(platform.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
