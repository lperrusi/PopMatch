import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/detail/detail_action_buttons.dart';
import '../../widgets/detail/detail_header_hero.dart';
import '../../widgets/detail/detail_why_line.dart';
import '../../utils/detail_actions.dart';
import '../../widgets/detail/detail_videos_section.dart';
import '../../widgets/detail/detail_cast_crew_section.dart';
import '../../widgets/detail/detail_inline_streaming.dart';
import '../../widgets/detail/detail_similar_section.dart';
import '../../widgets/detail/detail_color_extraction.dart';
import '../../widgets/detail/detail_screen_skeleton.dart';
import '../../models/movie.dart'; // For CastMember, CrewMember
import '../../utils/navigation_utils.dart';
import '../../services/tmdb_service.dart';
import '../../services/movie_cache_service.dart';
import '../../widgets/retro_cinema_bottom_nav.dart';
import '../../utils/l10n_extension.dart';

/// Retro Cinema styled TV show detail screen
class ShowDetailScreen extends StatefulWidget {
  final TvShow show;

  const ShowDetailScreen({
    super.key,
    required this.show,
  });

  @override
  State<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends State<ShowDetailScreen>
    with DetailColorExtractionMixin {
  TvShow? _loadedShow;
  bool _isSynopsisExpanded = false;
  bool _detailsLoading = true;
  bool _forceReady = false;
  Timer? _showDetailsTimer;
  Timer? _colorExtractionTimer;
  Timer? _revealFallbackTimer;

  /// "Reveal when ready": hold a skeleton until core details and the poster
  /// colour have both resolved, then cross-fade to the real content.
  /// [_forceReady] is a safety net so a hung load can never strand the skeleton.
  bool get _isReady => _forceReady || (!_detailsLoading && !isLoadingColor);

  @override
  void initState() {
    super.initState();

    // A cached show may be list-level: getShowDetails() (unlike getMovieDetails)
    // does not append credits, so a cached TvShow can have no cast/crew. Reveal
    // it immediately, but still load full credits below when cast is missing so
    // the Cast & Crew section appears.
    final cachedShow = MovieCacheService.instance.getCachedShow(widget.show.id);
    final cachedHasCast = cachedShow?.cast?.isNotEmpty ?? false;
    if (cachedShow != null) {
      _loadedShow = cachedShow;
      _detailsLoading = false;
    }

    // Defer ALL heavy operations until after the screen fully renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load eagerly (no artificial delay) so the seasons/episodes counts —
      // which only come from getShowDetails — arrive with the rest of the header
      // instead of popping in late. Still cancellable on quick back-navigation.
      _showDetailsTimer = Timer(Duration.zero, () {
        if (mounted && !isDisposed && !cachedHasCast) {
          _loadShowDetails();
        }
      });
      
      // Extract colour early (behind the skeleton) so the reveal isn't delayed.
      _colorExtractionTimer = Timer(Duration.zero, () {
        if (mounted && !isDisposed) {
          if (widget.show.backdropUrl != null || widget.show.posterUrl != null) {
            extractColorFromImageUrl(
                _displayShow.backdropUrl ?? _displayShow.posterUrl);
          } else {
            setState(() {
              isLoadingColor = false;
              isLightBackground = false;
            });
          }
        }
      });

      // Safety net: never strand the skeleton if a load hangs.
      _revealFallbackTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !isDisposed && !_forceReady) {
          setState(() => _forceReady = true);
        }
      });
    });
  }

  /// Loads full show details including cast and crew
  Future<void> _loadShowDetails() async {
    // Only load if we don't already have full details with cast/crew
    if (_loadedShow != null &&
        _loadedShow!.cast != null &&
        _loadedShow!.cast!.isNotEmpty) {
      if (mounted && !isDisposed) setState(() => _detailsLoading = false);
      return; // Already have full details
    }

    try {
      final tmdbService = TMDBService();
      
      // Load show details
      final showDetails = await tmdbService.getShowDetails(widget.show.id);
      
      // Load credits
      final credits = await tmdbService.getShowCredits(widget.show.id);
      
      // Combine show details with credits
      final loadedShow = showDetails.copyWith(
        cast: credits['cast'] != null
            ? List<CastMember>.from(
                (credits['cast'] as List).map((c) => CastMember.fromJson(c)))
            : null,
        crew: credits['crew'] != null
            ? List<CrewMember>.from(
                (credits['crew'] as List).map((c) => CrewMember.fromJson(c)))
            : null,
      );
      
      // Schedule setState on next frame to avoid blocking
      if (mounted && !isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !isDisposed) {
            setState(() {
              _loadedShow = loadedShow;
              _detailsLoading = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading show details: $e');
      if (mounted && !isDisposed) setState(() => _detailsLoading = false);
    }
  }

  /// Gets the show to display (loaded show with cast/crew, or fallback to original)
  TvShow get _displayShow => _loadedShow ?? widget.show;

  /// Shimmer placeholder for the seasons/episodes counts while show details load,
  /// so the header reserves the slot instead of growing when the counts arrive.
  Widget _buildSeasonsEpisodesPlaceholder() {
    Widget bar(double width) => Container(
          width: width,
          height: 13,
          decoration: BoxDecoration(
            color: textColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Shimmer.fromColors(
      baseColor: textColor.withValues(alpha: 0.20),
      highlightColor: textColor.withValues(alpha: 0.45),
      child: Row(
        children: [
          bar(84),
          const SizedBox(width: 16),
          bar(96),
        ],
      ),
    );
  }


  /// Loads "Shows Like This": merges TMDB similar + recommended shows, de-dupes
  /// (excluding the current show), and maps the top 6 to [DetailSimilarItem]s.
  Future<List<DetailSimilarItem>> _loadSimilarShowItems(
      BuildContext context) async {
    final tmdb = TMDBService();
    List<TvShow> similar = [];
    List<TvShow> recommended = [];
    try {
      similar = await tmdb.getSimilarShows(_displayShow.id);
    } catch (e) {
      debugPrint('Error loading similar shows: $e');
    }
    try {
      recommended = await tmdb.getShowRecommendations(_displayShow.id);
    } catch (e) {
      debugPrint('Error loading recommended shows: $e');
    }

    final all = <TvShow>[];
    final seen = <int>{};
    for (final s in [...similar, ...recommended]) {
      if (s.id != _displayShow.id && seen.add(s.id)) {
        all.add(s);
      }
    }

    return all
        .take(6)
        .map((s) => DetailSimilarItem(
              posterUrl: s.posterUrl,
              title: s.name,
              year: s.year,
              rating: s.voteAverage != null ? s.formattedRating : null,
              onTap: () {
                if (context.mounted) {
                  Navigator.of(context).push(
                    NavigationUtils.fastSlideRoute(ShowDetailScreen(show: s)),
                  );
                }
              },
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          isDisposed = true;
          _showDetailsTimer?.cancel();
          _colorExtractionTimer?.cancel();
          _revealFallbackTimer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.vintagePaper,
        body: DefaultTabController(
          length: 2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isReady
                ? KeyedSubtree(
                    key: const ValueKey('content'),
                    child: _buildContent(),
                  )
                : const DetailScreenSkeleton(key: ValueKey('skeleton')),
          ),
        ),
        bottomNavigationBar: RetroCinemaBottomNav(
          currentIndex: _getCurrentTabIndex(),
          onTap: (index) {
            _handleNavigationTap(index);
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Retro Cinema App Bar with show poster
          DetailHeaderHero(
            imageUrl: _displayShow.backdropUrl ?? _displayShow.posterUrl,
            title: _displayShow.name,
            textColor: textColor,
            overlayColor: overlayColor,
            fallbackIcon: Icons.tv_outlined,
            // Extra bottom padding so the tab bar doesn't hide "Where to watch".
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
            onBack: () {
              isDisposed = true;
              _showDetailsTimer?.cancel();
              _colorExtractionTimer?.cancel();
              Navigator.of(context).pop();
            },
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.vintagePaper,
                child: TabBar(
                  indicatorColor: AppTheme.brickRed,
                  labelColor: AppTheme.filmStripBlack,
                  unselectedLabelColor: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                  labelStyle: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1),
                  tabs: [
                    Tab(text: context.l10n.overviewTab),
                    Tab(text: context.l10n.seasonsEpisodesTab),
                  ],
                ),
              ),
            ),
            children: [
                          // Year, Rating, Seasons/Episodes row
                          Row(
                            children: [
                              if (_displayShow.year != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brickRed,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: textColor.withValues(alpha: 30),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _displayShow.year!,
                                    style: GoogleFonts.lato(
                                      color: AppTheme.warmCream,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(
                                Icons.star_rounded,
                                color: AppTheme.brickRed,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _displayShow.formattedRating,
                                style: GoogleFonts.lato(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_displayShow.voteCount != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(${_displayShow.voteCount} votes)',
                                  style: GoogleFonts.lato(
                                    color: textColor.withValues(alpha: 70),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_displayShow.numberOfSeasons != null || _displayShow.numberOfEpisodes != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_displayShow.numberOfSeasons != null) ...[
                                  Icon(
                                    Icons.layers_rounded,
                                    color: textColor.withValues(alpha: 80),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_displayShow.numberOfSeasons} ${_displayShow.numberOfSeasons == 1 ? 'Season' : 'Seasons'}',
                                    style: GoogleFonts.lato(
                                      color: textColor.withValues(alpha: 80),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (_displayShow.numberOfSeasons != null && _displayShow.numberOfEpisodes != null) ...[
                                  const SizedBox(width: 16),
                                ],
                                if (_displayShow.numberOfEpisodes != null) ...[
                                  Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: textColor.withValues(alpha: 80),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l10n.episodesLabel(_displayShow.numberOfEpisodes!),
                                    style: GoogleFonts.lato(
                                      color: textColor.withValues(alpha: 80),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ] else if (_detailsLoading) ...[
                            // Reserve the seasons/episodes slot while details load
                            // so the row fills in instead of popping in late.
                            const SizedBox(height: 8),
                            _buildSeasonsEpisodesPlaceholder(),
                          ],
                          DetailWhyLine(
                            strategy: _displayShow.recommendationStrategy,
                            genreIds: _displayShow.genreIds,
                            genreNames: _displayShow.genres,
                            genres: context.read<ShowProvider>().genres,
                            castNames: _displayShow.cast
                                ?.take(6)
                                .map((c) => c.name)
                                .toList(),
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // Watchlist, Like, Dislike and Share row
                          DetailActionButtons(
                            itemId: _displayShow.id.toString(),
                            title: _displayShow.name,
                            isShow: true,
                            textColor: textColor,
                            onShare: () => _shareShow(context),
                          ),
                          const SizedBox(height: 16),
                          // Where to Watch section inline
                          DetailInlineStreamingAvailability(
                              itemId: _displayShow.id,
                              title: _displayShow.name,
                              isShow: true,
                              textColor: textColor),
            ],
          ),
          ],
          body: TabBarView(
            children: [
              CustomScrollView(
                slivers: [
                  // Show details - Overview tab
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_displayShow.overview != null && _displayShow.overview!.isNotEmpty) ...[
                            Text(
                              context.l10n.synopsisLabel,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 24,
                                color: AppTheme.filmStripBlack,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.vintagePaper,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayShow.overview!,
                                    style: GoogleFonts.lato(
                                      color: AppTheme.filmStripBlack,
                                      fontSize: 15,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: _isSynopsisExpanded ? null : 4,
                                    overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                                  ),
                                  if (_displayShow.overview!.length > 200) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isSynopsisExpanded = !_isSynopsisExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isSynopsisExpanded ? context.l10n.showLessLabel : context.l10n.moreLabel,
                                        style: GoogleFonts.lato(
                                          color: AppTheme.cinemaRed,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: DetailVideosSection(
                      initialVideos: _displayShow.videos,
                      fetchVideos: () =>
                          TMDBService().getShowVideos(_displayShow.id),
                    ),
                  ),
                  if (_displayShow.crew != null || _displayShow.cast != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: DetailCastCrewSection(
                          crew: _displayShow.crew
                                  ?.where((m) =>
                                      m.job?.toLowerCase() == 'creator' ||
                                      m.job?.toLowerCase() ==
                                          'executive producer')
                                  .toList() ??
                              const [],
                          cast: _displayShow.cast ?? const [],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: DetailSimilarSection(
                      title: context.l10n.showsLikeThisLabel,
                      errorLabel: context.l10n.failedToLoadSimilarShows,
                      emptyLabel: context.l10n.noSimilarShowsFound,
                      loadItems: () => _loadSimilarShowItems(context),
                    ),
                  ),
                ],
              ),
              _SeasonsEpisodesTab(show: _displayShow),
            ],
          ),
        );
  }

  int _getCurrentTabIndex() {
    return 0;
  }

  void _handleNavigationTap(int index) {
    handleDetailNavTap(
      context,
      index,
      onCancel: () {
        isDisposed = true;
        _showDetailsTimer?.cancel();
        _colorExtractionTimer?.cancel();
      },
    );
  }

  @override
  void dispose() {
    isDisposed = true;
    _showDetailsTimer?.cancel();
    _colorExtractionTimer?.cancel();
    _revealFallbackTimer?.cancel();
    super.dispose();
  }

  void _shareShow(BuildContext context) {
    shareTitleDetails(
      isShow: true,
      title: _displayShow.name,
      overview: _displayShow.overview,
      rating: _displayShow.formattedRating,
      year: _displayShow.year,
      genres: _displayShow.genres,
      seasons: _displayShow.numberOfSeasons,
      episodes: _displayShow.numberOfEpisodes,
    );
  }
}

/// Seasons & Episodes tab: expandable seasons, episode list with watched toggle and tap-for-detail
class _SeasonsEpisodesTab extends StatefulWidget {
  final TvShow show;

  const _SeasonsEpisodesTab({required this.show});

  @override
  State<_SeasonsEpisodesTab> createState() => _SeasonsEpisodesTabState();
}

class _SeasonsEpisodesTabState extends State<_SeasonsEpisodesTab> {
  final Map<int, List<TvEpisode>> _seasonEpisodes = {};
  final Set<int> _loadingSeasons = {};
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    final seasons = widget.show.numberOfSeasons ?? 0;
    for (var i = 1; i <= seasons; i++) {
      _loadSeason(i);
    }
  }

  Future<void> _loadSeason(int seasonNumber) async {
    if (_seasonEpisodes.containsKey(seasonNumber) || _loadingSeasons.contains(seasonNumber)) return;
    setState(() => _loadingSeasons.add(seasonNumber));
    try {
      final episodes = await _tmdbService.getSeasonDetails(widget.show.id, seasonNumber);
      if (mounted) {
        setState(() {
          _seasonEpisodes[seasonNumber] = episodes;
          _loadingSeasons.remove(seasonNumber);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _seasonEpisodes[seasonNumber] = [];
          _loadingSeasons.remove(seasonNumber);
        });
      }
    }
  }

  void _openEpisodeDialog(BuildContext context, TvEpisode episode) {
    showDialog<void>(
      context: context,
      builder: (context) => _EpisodeDetailDialog(episode: episode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasons = widget.show.numberOfSeasons ?? 0;
    if (seasons == 0) {
      return Center(
        child: Text(
          context.l10n.noSeasonsAvailable,
          style: GoogleFonts.lato(color: AppTheme.filmStripBlack.withValues(alpha: 0.7), fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: seasons,
      itemBuilder: (context, index) {
        final seasonNumber = index + 1;
        final episodes = _seasonEpisodes[seasonNumber];
        final isLoading = _loadingSeasons.contains(seasonNumber);
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              if (expanded && episodes == null) _loadSeason(seasonNumber);
            },
            initiallyExpanded: false,
            iconColor: AppTheme.cinemaRed,
            collapsedIconColor: AppTheme.cinemaRed,
            tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            childrenPadding: const EdgeInsets.only(left: 12, bottom: 16),
            title: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final showId = widget.show.id.toString();
                final watched = episodes != null ? authProvider.getWatchedEpisodes(showId) : <String>{};
                final watchedCount = episodes != null
                    ? episodes.where((e) => watched.contains(e.episodeKey)).length
                    : 0;
                final total = episodes?.length ?? 0;
                final allWatched = total > 0 && watchedCount == total;
                return Row(
                  children: [
                    Text(
                      context.l10n.seasonLabel(seasonNumber),
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: AppTheme.filmStripBlack,
                        letterSpacing: 1,
                      ),
                    ),
                    if (episodes != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '$watchedCount / $total',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.filmStripBlack.withValues(alpha: 0.85),
                        ),
                      ),
                      const Spacer(),
                      Checkbox(
                        value: allWatched,
                        onChanged: total == 0
                            ? null
                            : (value) async {
                                await authProvider.setEpisodesWatched(
                                  showId,
                                  episodes.map((e) => e.episodeKey).toList(),
                                  value ?? false,
                                );
                              },
                        activeColor: AppTheme.cinemaRed,
                        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.cinemaRed;
                          }
                          return AppTheme.filmStripBlack.withValues(alpha: 0.4);
                        }),
                      ),
                    ] else if (isLoading) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cinemaRed),
                      ),
                    ],
                  ],
                );
              },
            ),
            trailing: null,
            children: [
              if (episodes == null && !isLoading)
                const SizedBox.shrink()
              else if (episodes != null)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final showId = widget.show.id.toString();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: episodes.map((episode) {
                          final isWatched = authProvider.isEpisodeWatched(
                            showId,
                            episode.seasonNumber,
                            episode.episodeNumber,
                          );
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openEpisodeDialog(context, episode),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${episode.episodeNumber}',
                                        style: GoogleFonts.lato(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.filmStripBlack.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        episode.name,
                                        style: GoogleFonts.lato(
                                          fontSize: 15,
                                          color: AppTheme.filmStripBlack,
                                          decoration: isWatched ? TextDecoration.lineThrough : null,
                                          decorationColor: AppTheme.filmStripBlack.withValues(alpha: 0.5),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                        color: isWatched ? AppTheme.brickRed : AppTheme.filmStripBlack.withValues(alpha: 0.5),
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        await authProvider.setEpisodeWatched(
                                          showId,
                                          episode.seasonNumber,
                                          episode.episodeNumber,
                                          !isWatched,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Episode detail popup
class _EpisodeDetailDialog extends StatelessWidget {
  final TvEpisode episode;

  const _EpisodeDetailDialog({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.vintagePaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (episode.stillUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: episode.stillUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.brickRed),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                      child: Icon(Icons.tv_rounded, size: 48, color: AppTheme.filmStripBlack.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'S${episode.seasonNumber}E${episode.episodeNumber} · ${episode.name}',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: AppTheme.filmStripBlack,
                        letterSpacing: 1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.airDate != null && episode.airDate!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        episode.airDate!,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (episode.overview != null && episode.overview!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        episode.overview!,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.filmStripBlack,
                        ),
                      ),
                    ],
                    if (episode.runtime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.minutesLabel(episode.runtime!),
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.closeButton,
                      style: GoogleFonts.lato(
                        color: AppTheme.cinemaRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

