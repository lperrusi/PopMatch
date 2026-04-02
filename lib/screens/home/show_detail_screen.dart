import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../models/tv_show.dart';
import '../../providers/auth_provider.dart';
import '../../providers/show_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/video_player_widget.dart';
import '../../providers/streaming_provider.dart';
import '../../models/streaming_platform.dart';
import '../../models/video.dart';
import '../../models/movie.dart'; // For CastMember, CrewMember
import '../../models/streaming_platform.dart' show MovieStreamingAvailability;
import '../../services/tmdb_service.dart';
import '../../widgets/transparent_button_image.dart';
import '../../widgets/retro_cinema_bottom_nav.dart';
import 'home_screen.dart' show updateHomeScreenTab;

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

class _ShowDetailScreenState extends State<ShowDetailScreen> {
  bool _isLightBackground = false;
  bool _isLoadingColor = true;
  TvShow? _loadedShow;
  bool _isSynopsisExpanded = false;
  bool _isDisposed = false;
  Timer? _showDetailsTimer;
  Timer? _colorExtractionTimer;

  @override
  void initState() {
    super.initState();

    // We have basic show data from widget.show, so screen can render immediately

    // Defer ALL heavy operations until after the screen fully renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for multiple frames to ensure screen is fully rendered and interactive
      _showDetailsTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !_isDisposed) {
          // Load additional show details (cast/crew) in background
          _loadShowDetails();
        }
      });
      
      // Color extraction - delay significantly to not block UI
      _colorExtractionTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted && !_isDisposed) {
          if (widget.show.backdropUrl != null || widget.show.posterUrl != null) {
            _extractColorFromImage();
          } else {
            setState(() {
              _isLoadingColor = false;
              _isLightBackground = false;
            });
          }
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
      if (mounted && !_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isDisposed) {
            setState(() {
              _loadedShow = loadedShow;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading show details: $e');
    }
  }

  /// Gets the show to display (loaded show with cast/crew, or fallback to original)
  TvShow get _displayShow => _loadedShow ?? widget.show;

  /// Extracts dominant color from poster/backdrop image
  Future<void> _extractColorFromImage() async {
    try {
      final show = _displayShow;
      final imageUrl = show.backdropUrl ?? show.posterUrl;
      if (imageUrl == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLightBackground = false;
            _isLoadingColor = false;
          });
        }
        return;
      }

      final imageProvider = CachedNetworkImageProvider(imageUrl);
      PaletteGenerator paletteGenerator;
      try {
        paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider)
            .timeout(const Duration(seconds: 2));
      } on TimeoutException {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLightBackground = false;
            _isLoadingColor = false;
          });
        }
        return;
      }
      
      if (mounted && !_isDisposed) {
        final dominantColor = paletteGenerator.dominantColor?.color ?? AppTheme.filmStripBlack;
        final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
        final isLight = brightness == Brightness.light;
        
        setState(() {
          _isLightBackground = isLight;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLightBackground = false;
          _isLoadingColor = false;
        });
      }
    }
  }

  /// Gets the appropriate text color based on background brightness
  Color get _textColor {
    if (_isLoadingColor) return AppTheme.warmCream;
    return _isLightBackground ? AppTheme.filmStripBlack : AppTheme.warmCream;
  }

  /// Gets the appropriate overlay color for better text readability
  Color get _overlayColor {
    if (_isLightBackground) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return AppTheme.filmStripBlack.withValues(alpha: 0.75);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _isDisposed = true;
          _showDetailsTimer?.cancel();
          _colorExtractionTimer?.cancel();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.vintagePaper,
        body: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Retro Cinema App Bar with show poster
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.vintagePaper,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.vintagePaper,
                child: TabBar(
                  indicatorColor: AppTheme.brickRed,
                  labelColor: AppTheme.filmStripBlack,
                  unselectedLabelColor: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                  labelStyle: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Seasons & Episodes'),
                  ],
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Show backdrop
                  Positioned.fill(
                    child: (_displayShow.backdropUrl != null || _displayShow.posterUrl != null)
                        ? CachedNetworkImage(
                            imageUrl: _displayShow.backdropUrl ?? _displayShow.posterUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.vintagePaper,
                            ),
                            errorWidget: (context, url, error) {
                              return Container(
                                color: AppTheme.vintagePaper,
                                child: Icon(
                                  Icons.tv_outlined,
                                size: 64,
                                  color: AppTheme.filmStripBlack.withValues(alpha: 50),
                              ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.vintagePaper,
                            child: Icon(
                              Icons.tv_outlined,
                              size: 64,
                              color: AppTheme.filmStripBlack.withValues(alpha: 50),
                            ),
                          ),
                  ),
                  
                  // Gradient overlay at bottom for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _overlayColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Show info overlay (extra bottom padding so tab bar doesn't hide Where to Watch)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 72),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            _displayShow.name,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 36,
                              color: _textColor,
                              letterSpacing: 1.5,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          
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
                                      color: _textColor.withValues(alpha: 30),
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
                                  color: _textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_displayShow.voteCount != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(${_displayShow.voteCount} votes)',
                                  style: GoogleFonts.lato(
                                    color: _textColor.withValues(alpha: 70),
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
                                    color: _textColor.withValues(alpha: 80),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_displayShow.numberOfSeasons} ${_displayShow.numberOfSeasons == 1 ? 'Season' : 'Seasons'}',
                                    style: GoogleFonts.lato(
                                      color: _textColor.withValues(alpha: 80),
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
                                    color: _textColor.withValues(alpha: 80),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_displayShow.numberOfEpisodes} Episodes',
                                    style: GoogleFonts.lato(
                                      color: _textColor.withValues(alpha: 80),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Watchlist, Like, Dislike and Share buttons row
                          Row(
                            children: [
                              // Watchlist button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final isInWatchlist = authProvider.isInWatchlistShow(_displayShow.id.toString());
                                  return IconButton(
                                    icon: TransparentButtonImage(
                                      assetPath: 'assets/buttons/watchlist_button.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      errorWidget: Icon(
                                        isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                        color: _textColor,
                                        size: 24,
                                      ),
                                    ),
                                      onPressed: () async {
                                        final showProvider = Provider.of<ShowProvider>(context, listen: false);

                                        if (isInWatchlist) {
                                          await authProvider.removeFromWatchlistShow(_displayShow.id.toString());
                                          if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Removed ${_displayShow.name} from watchlist'),
                                            backgroundColor: AppTheme.fadedCurtain,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        } else {
                                          await authProvider.addShowToWatchlist(_displayShow.id.toString());
                                          if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Added ${_displayShow.name} to watchlist'),
                                            backgroundColor: AppTheme.fadedCurtain,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }

                                        // Keep the swipe feed in sync with detail actions.
                                        showProvider.refreshFilters(authProvider.userData);
                                    },
                                  );
                                },
                              ),
                              // Like button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final showId = _displayShow.id.toString();
                                  final isLiked = authProvider.isLikedShow(showId);
                                  return IconButton(
                                    icon: Icon(
                                      isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                      color: isLiked ? AppTheme.vintagePaper : _textColor,
                                      size: 24,
                                    ),
                                    onPressed: () async {
                                      if (authProvider.userData == null) return;
                                        final showProvider = Provider.of<ShowProvider>(context, listen: false);
                                      if (isLiked) {
                                        await authProvider.removeLikedShow(showId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Removed ${_displayShow.name} from favorites'),
                                              backgroundColor: AppTheme.fadedCurtain,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } else {
                                        await authProvider.removeDislikedShow(showId);
                                        await authProvider.addLikedShow(showId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added ${_displayShow.name} to favorites'),
                                              backgroundColor: AppTheme.fadedCurtain,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }

                                        showProvider.refreshFilters(authProvider.userData);
                                    },
                                  );
                                },
                              ),
                              // Dislike button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final showId = _displayShow.id.toString();
                                  final isDisliked = authProvider.isDislikedShow(showId);
                                  return IconButton(
                                    icon: Icon(
                                      isDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                                      color: isDisliked ? AppTheme.vintagePaper : _textColor.withValues(alpha: 0.8),
                                      size: 24,
                                    ),
                                    onPressed: () async {
                                      if (authProvider.userData == null) return;
                                        final showProvider = Provider.of<ShowProvider>(context, listen: false);
                                      if (isDisliked) {
                                        await authProvider.removeDislikedShow(showId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Removed ${_displayShow.name} from disliked'),
                                              backgroundColor: AppTheme.fadedCurtain,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } else {
                                        await authProvider.removeLikedShow(showId);
                                        await authProvider.addDislikedShow(showId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added ${_displayShow.name} to disliked'),
                                              backgroundColor: AppTheme.fadedCurtain,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }

                                        showProvider.refreshFilters(authProvider.userData);
                                    },
                                  );
                                },
                              ),
                              // Share button
                              IconButton(
                                icon: Icon(
                                  Icons.share_rounded,
                                  color: _textColor,
                                  size: 24,
                                ),
                onPressed: () => _shareShow(context),
              ),
            ],
          ),
                          const SizedBox(height: 16),
                          // Where to Watch section inline
                          _InlineStreamingAvailability(show: _displayShow, textColor: _textColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _isDisposed = true;
                    _showDetailsTimer?.cancel();
                    _colorExtractionTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.vintagePaper,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.cinemaRed.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.cinemaRed,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: const [],
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
                              'Synopsis',
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
                                        _isSynopsisExpanded ? 'Show less' : 'More',
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
                    child: _VideosSection(show: _displayShow),
                  ),
                  if (_displayShow.crew != null || _displayShow.cast != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _CastCrewSection(show: _displayShow),
                      ),
                    ),
                ],
              ),
              _SeasonsEpisodesTab(show: _displayShow),
            ],
          ),
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

  int _getCurrentTabIndex() {
    return 0;
  }

  void _handleNavigationTap(int index) {
    _isDisposed = true;
    _showDetailsTimer?.cancel();
    _colorExtractionTimer?.cancel();
    Navigator.of(context).pop();
    Future.microtask(() => updateHomeScreenTab(index));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _showDetailsTimer?.cancel();
    _colorExtractionTimer?.cancel();
    super.dispose();
  }

  void _shareShow(BuildContext context) {
    final shareText = '''
📺 ${_displayShow.name}

${_displayShow.overview ?? 'No description available'}

⭐ Rating: ${_displayShow.formattedRating}
📅 First Aired: ${_displayShow.year ?? 'Unknown'}
${_displayShow.numberOfSeasons != null ? '📚 Seasons: ${_displayShow.numberOfSeasons}' : ''}
${_displayShow.numberOfEpisodes != null ? '🎬 Episodes: ${_displayShow.numberOfEpisodes}' : ''}
🎭 Genres: ${_displayShow.genres?.join(', ') ?? 'Unknown'}

Check out this show on PopMatch!
''';

    Share.share(shareText, subject: 'Check out this show: ${_displayShow.name}');
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
          'No seasons available',
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
                      'Season $seasonNumber',
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
                        '${episode.runtime} min',
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
                      'Close',
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

// Videos Section
class _VideosSection extends StatefulWidget {
  final TvShow show;

  const _VideosSection({required this.show});

  @override
  State<_VideosSection> createState() => _VideosSectionState();
}

class _VideosSectionState extends State<_VideosSection> {
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.show.videos != null && widget.show.videos!.isNotEmpty) {
      _videos = widget.show.videos!;
      _isLoading = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
    _loadVideos();
        }
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });

      final tmdbService = TMDBService();
      final videos = await tmdbService.getShowVideos(widget.show.id);

      if (!mounted) return;

      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
            'Trailers & Videos',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              color: AppTheme.filmStripBlack,
              letterSpacing: 1,
            ),
                    ),
          const SizedBox(height: 20),
                SizedBox(
            height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                return _RetroVideoCard(video: _videos[index]);
                    },
                  ),
            ),
        ],
      ),
    );
  }
}

class _RetroVideoCard extends StatelessWidget {
  final Video video;

  const _RetroVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cinemaRed,
          width: 1.5,
            ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(video: video),
      ),
    );
  }
}

// Cast & Crew Section
class _CastCrewSection extends StatelessWidget {
  final TvShow show;

  const _CastCrewSection({required this.show});

  @override
  Widget build(BuildContext context) {
    // Get creators from crew (TV shows have creators instead of directors)
    final creators = show.crew
            ?.where((member) => member.job?.toLowerCase() == 'creator' || 
                               member.job?.toLowerCase() == 'executive producer')
            .toList() ??
        [];
    
    // Get top 10 actors from cast
    final topActors = show.cast?.take(10).toList() ?? [];

    final List<dynamic> allPeople = [];
    
    // Add creators first
    for (var creator in creators) {
      allPeople.add({
        'type': 'creator',
        'person': creator,
      });
    }
    
    // Add actors
    for (var actor in topActors) {
      allPeople.add({
        'type': 'actor',
        'person': actor,
      });
    }

    if (allPeople.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
          'Cast & Crew',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            color: AppTheme.filmStripBlack,
            letterSpacing: 1,
                        ),
                      ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allPeople.length,
            itemBuilder: (context, index) {
              final item = allPeople[index];
              final isCreator = item['type'] == 'creator';
              final person = item['person'];
              
              String? profileUrl;
              String name;
              String? info;
              
              if (isCreator) {
                final creator = person as CrewMember;
                profileUrl = creator.profileUrl;
                name = creator.name;
                info = creator.job;
              } else {
                final actor = person as CastMember;
                profileUrl = actor.profileUrl;
                name = actor.name;
                info = actor.character != null ? 'as ${actor.character!}' : null;
              }
              
              return _CastCrewCard(
                profileUrl: profileUrl,
                name: name,
                info: info,
                isCreator: isCreator,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual cast/crew card
class _CastCrewCard extends StatelessWidget {
  final String? profileUrl;
  final String name;
  final String? info;
  final bool isCreator;

  const _CastCrewCard({
    required this.profileUrl,
    required this.name,
    this.info,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
                  child: Stack(
          fit: StackFit.expand,
                    children: [
            profileUrl != null
                ? CachedNetworkImage(
                    imageUrl: profileUrl!,
                          fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.brickRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.filmStripBlack.withValues(alpha: 20),
                              child: Icon(
                        Icons.person,
                        color: AppTheme.filmStripBlack.withValues(alpha: 50),
                        size: 48,
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.filmStripBlack.withValues(alpha: 20),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.filmStripBlack.withValues(alpha: 50),
                      size: 48,
                    ),
                        ),
                      
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                          decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.filmStripBlack.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
                      name,
                      style: GoogleFonts.lato(
                        color: AppTheme.warmCream,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
                    if (info != null) ...[
            const SizedBox(height: 2),
            Text(
                        info!,
                        style: GoogleFonts.lato(
                          color: AppTheme.warmCream.withValues(alpha: 85),
                          fontSize: 11,
                          fontStyle: isCreator ? FontStyle.normal : FontStyle.italic,
                          letterSpacing: 0.1,
              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
            ),
                    ],
          ],
        ),
      ),
            ),
          ],
        ),
      ),
    );
  }
}

// Streaming Availability Section (inline)
class _InlineStreamingAvailability extends StatefulWidget {
  final TvShow show;
  final Color textColor;

  const _InlineStreamingAvailability({
    required this.show,
    this.textColor = AppTheme.warmCream,
  });

  @override
  State<_InlineStreamingAvailability> createState() => _InlineStreamingAvailabilityState();
}

class _InlineStreamingAvailabilityState extends State<_InlineStreamingAvailability> {
  MovieStreamingAvailability? _availability;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreamingAvailability();
  }

  Future<void> _loadStreamingAvailability() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final streamingProvider = Provider.of<StreamingProvider>(context, listen: false);
      final availability = await streamingProvider.getStreamingAvailabilityForTv(widget.show.id);

      if (mounted) {
        setState(() {
          _availability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_error != null || _availability == null || _availability!.availablePlatforms.isEmpty) {
      return const SizedBox.shrink();
    }

    final platforms = _availability!.platforms.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tv_rounded,
              color: widget.textColor.withValues(alpha: 80),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Where to Watch:',
              style: GoogleFonts.lato(
                color: widget.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
          ),
        ],
      ),
          const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: platforms.length,
            itemBuilder: (context, index) {
              final platform = platforms[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.sepiaBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
            platform.name,
                      style: GoogleFonts.lato(
                        color: widget.textColor,
                        fontSize: 12,
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
    );
  }
}
