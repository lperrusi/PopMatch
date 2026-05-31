part of 'swipe_screen.dart';

/// Discover filter menus + mood/genre/platform dialogs, split out of
/// swipe_screen.dart to keep that file manageable. Kept as an extension on
/// _SwipeScreenState (same library via `part`) so the move is verbatim and
/// the call sites + provider/undo logic are untouched.
extension _SwipeFilterSheets on _SwipeScreenState {
  /// Shows filter menu for shows
  void _showShowFilterMenu(ShowProvider showProvider) {
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
                  context.l10n.filtersSectionTitle,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: AppTheme.warmCream,
                    letterSpacing: 1.5,
                  ),
                ),
                if (showProvider.swipeMoods.isNotEmpty ||
                    showProvider.swipeSelectedGenres.isNotEmpty ||
                    showProvider.swipeSelectedPlatforms.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showProvider.clearSwipeFilters();
                      Navigator.pop(context);
                      _reloadShowsWithFilters();
                    },
                    child: Text(
                      context.l10n.clearAllButton,
                      style: const TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFilterMenuItem(
              context.l10n.moodFilterLabel,
              showProvider.swipeMoods.isNotEmpty
                  ? '${showProvider.swipeMoods.length} selected'
                  : context.l10n.selectMoodsHint,
              showProvider.swipeMoods.isNotEmpty,
              () {
                Navigator.pop(context);
                _showMoodDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 12),

            _buildFilterMenuItem(
              context.l10n.genresFilterLabel,
              showProvider.swipeSelectedGenres.isNotEmpty
                  ? '${showProvider.swipeSelectedGenres.length} selected'
                  : context.l10n.selectGenresHint,
              showProvider.swipeSelectedGenres.isNotEmpty,
              () {
                Navigator.pop(context);
                _showGenreDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 12),

            _buildFilterMenuItem(
              context.l10n.platformFilterLabel,
              showProvider.swipeSelectedPlatforms.isNotEmpty
                  ? '${showProvider.swipeSelectedPlatforms.length} selected'
                  : context.l10n.selectPlatformsHint,
              showProvider.swipeSelectedPlatforms.isNotEmpty,
              () {
                Navigator.pop(context);
                _showPlatformDialogForShows(showProvider);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Shows mood selection dialog with multi-select support (TV shows).
  void _showMoodDialogForShows(ShowProvider showProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          return Container(
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
                      context.l10n.selectMoodsTitle,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeMoods.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipeMoods([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: Text(
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: Mood.availableMoods.length,
                    itemBuilder: (context, index) {
                      final mood = Mood.availableMoods[index];
                      final isSelected =
                          showProvider.swipeMoods.any((m) => m.id == mood.id);

                      return GestureDetector(
                        onTap: () {
                          final currentMoods = List<Mood>.from(showProvider.swipeMoods);
                          if (isSelected) {
                            currentMoods.removeWhere((m) => m.id == mood.id);
                          } else {
                            currentMoods.add(mood);
                          }
                          showProvider.setSwipeMoods(currentMoods);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.cinemaRed
                                : AppTheme.fadedCurtain,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.popcornGold
                                  : Colors.transparent,
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
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows genre selection dialog (TV shows).
  void _showGenreDialogForShows(ShowProvider showProvider) {
    final genres = showProvider.genres;
    if (genres.isEmpty) {
      showProvider.loadGenres();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loadingGenresMessage)),
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
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          final genres = showProvider.genres;
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final profileGenreIds = ((authProvider.userData
                          ?.preferences['selectedGenres'] as List<dynamic>?) ??
                      [])
                  .map((g) => g is int ? g : (g as num).toInt())
                  .toSet();
          return Container(
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
                      context.l10n.selectGenresTitle,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeSelectedGenres.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipeGenres([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: Text(
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                if (profileGenreIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 12, color: AppTheme.sepiaBrown),
                    const SizedBox(width: 4),
                    Text(
                      'Brown border = from your profile',
                      style: GoogleFonts.lato(
                          color: AppTheme.sepiaBrown, fontSize: 11),
                    ),
                  ]),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.entries.map((entry) {
                        final genreId = entry.key;
                        final genreName = entry.value;
                        final isSelected = showProvider
                            .swipeSelectedGenres
                            .contains(genreId);
                        final isFromProfile =
                            profileGenreIds.contains(genreId);

                        return GestureDetector(
                          onTap: () {
                            final currentGenres = List<int>.from(
                                showProvider.swipeSelectedGenres);
                            if (isSelected) {
                              currentGenres.remove(genreId);
                            } else {
                              currentGenres.add(genreId);
                            }
                            showProvider.setSwipeGenres(currentGenres);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : isFromProfile
                                        ? AppTheme.sepiaBrown
                                            .withValues(alpha: 0.8)
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  genreName,
                                  style: TextStyle(
                                    color: AppTheme.warmCream,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isFromProfile && !isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.person_outline,
                                      size: 12, color: AppTheme.sepiaBrown),
                                ],
                              ],
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
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows platform selection dialog (TV shows).
  void _showPlatformDialogForShows(ShowProvider showProvider) {
    const platforms = StreamingPlatform.availablePlatforms;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ShowProvider>(
        builder: (context, showProvider, _) {
          return Container(
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
                      context.l10n.selectPlatformsTitle,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.warmCream,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (showProvider.swipeSelectedPlatforms.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          showProvider.setSwipePlatforms([]);
                          Navigator.pop(context);
                          _reloadShowsWithFilters();
                        },
                        child: Text(
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
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
                        final isSelected = showProvider
                            .swipeSelectedPlatforms
                            .contains(platform.id);

                        return GestureDetector(
                          onTap: () {
                            final currentPlatforms = List<String>.from(
                                showProvider.swipeSelectedPlatforms);
                            if (isSelected) {
                              currentPlatforms.remove(platform.id);
                            } else {
                              currentPlatforms.add(platform.id);
                            }
                            showProvider.setSwipePlatforms(currentPlatforms);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              platform.name,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                      _reloadShowsWithFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cinemaRed,
                      foregroundColor: AppTheme.warmCream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
                  context.l10n.filtersSectionTitle,
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
                      context.l10n.clearAllButton,
                      style: const TextStyle(color: AppTheme.popcornGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Mood filter option
            _buildFilterMenuItem(
              context.l10n.moodFilterLabel,
              movieProvider.swipeMoods.isNotEmpty
                  ? '${movieProvider.swipeMoods.length} selected'
                  : context.l10n.selectMoodsHint,
              movieProvider.swipeMoods.isNotEmpty,
              () {
                Navigator.pop(context);
                _showMoodDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Genre filter option
            _buildFilterMenuItem(
              context.l10n.genresFilterLabel,
              movieProvider.swipeSelectedGenres.isNotEmpty
                  ? '${movieProvider.swipeSelectedGenres.length} selected'
                  : context.l10n.selectGenresHint,
              movieProvider.swipeSelectedGenres.isNotEmpty,
              () {
                Navigator.pop(context);
                _showGenreDialog(movieProvider);
              },
            ),
            const SizedBox(height: 12),
            // Platform filter option
            _buildFilterMenuItem(
              context.l10n.platformFilterLabel,
              movieProvider.swipeSelectedPlatforms.isNotEmpty
                  ? '${movieProvider.swipeSelectedPlatforms.length} selected'
                  : context.l10n.selectPlatformsHint,
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
          color: isActive
              ? AppTheme.cinemaRed.withValues(alpha: 0.3)
              : AppTheme.fadedCurtain,
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
                  style: const TextStyle(
                    color: AppTheme.warmCream,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.warmCream.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Icon(
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
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          return Container(
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
                      context.l10n.selectMoodsTitle,
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
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
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
                      final isSelected =
                          movieProvider.swipeMoods.any((m) => m.id == mood.id);

                      return GestureDetector(
                        onTap: () {
                          final currentMoods =
                              List<Mood>.from(movieProvider.swipeMoods);
                          if (isSelected) {
                            currentMoods.removeWhere((m) => m.id == mood.id);
                          } else {
                            currentMoods.add(mood);
                          }
                          movieProvider.setSwipeMoods(currentMoods);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.cinemaRed
                                : AppTheme.fadedCurtain,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.popcornGold
                                  : Colors.transparent,
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
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
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
        SnackBar(content: Text(context.l10n.loadingGenresMessage)),
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
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          final genres = movieProvider.genres;
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final profileGenreIds = ((authProvider.userData
                          ?.preferences['selectedGenres'] as List<dynamic>?) ??
                      [])
                  .map((g) => g is int ? g : (g as num).toInt())
                  .toSet();
          return Container(
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
                      context.l10n.selectGenresTitle,
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
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
                        ),
                      ),
                  ],
                ),
                if (profileGenreIds.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 12, color: AppTheme.sepiaBrown),
                    const SizedBox(width: 4),
                    Text(
                      'Brown border = from your profile',
                      style: GoogleFonts.lato(
                          color: AppTheme.sepiaBrown, fontSize: 11),
                    ),
                  ]),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genres.entries.map((entry) {
                        final genreId = entry.key;
                        final genreName = entry.value;
                        final isSelected =
                            movieProvider.swipeSelectedGenres.contains(genreId);
                        final isFromProfile =
                            profileGenreIds.contains(genreId);

                        return GestureDetector(
                          onTap: () {
                            final currentGenres =
                                List<int>.from(movieProvider.swipeSelectedGenres);
                            if (isSelected) {
                              currentGenres.remove(genreId);
                            } else {
                              currentGenres.add(genreId);
                            }
                            movieProvider.setSwipeGenres(currentGenres);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : isFromProfile
                                        ? AppTheme.sepiaBrown
                                            .withValues(alpha: 0.8)
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  genreName,
                                  style: TextStyle(
                                    color: AppTheme.warmCream,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isFromProfile && !isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.person_outline,
                                      size: 12, color: AppTheme.sepiaBrown),
                                ],
                              ],
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
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows platform selection dialog
  void _showPlatformDialog(MovieProvider movieProvider) {
    const platforms = StreamingPlatform.availablePlatforms;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.filmStripBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<MovieProvider>(
        builder: (context, movieProvider, _) {
          return Container(
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
                      context.l10n.selectPlatformsTitle,
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
                          context.l10n.clearAllButton,
                          style: const TextStyle(color: AppTheme.popcornGold),
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
                        final isSelected = movieProvider.swipeSelectedPlatforms
                            .contains(platform.id);

                        return GestureDetector(
                          onTap: () {
                            final currentPlatforms = List<String>.from(
                                movieProvider.swipeSelectedPlatforms);
                            if (isSelected) {
                              currentPlatforms.remove(platform.id);
                            } else {
                              currentPlatforms.add(platform.id);
                            }
                            movieProvider.setSwipePlatforms(currentPlatforms);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cinemaRed
                                  : AppTheme.fadedCurtain,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.popcornGold
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              platform.name,
                              style: TextStyle(
                                color: AppTheme.warmCream,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                    child: Text(context.l10n.applyButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
