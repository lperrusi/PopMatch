import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/movie.dart';
import '../models/streaming_platform.dart';
import '../utils/theme.dart';
import '../utils/l10n_extension.dart';
import '../utils/streaming_url_launcher.dart';
import '../services/movie_cache_service.dart';
import '../services/streaming_service.dart';

/// Retro Cinema styled movie card for swipe interface
class RetroCinemaMovieCard extends StatefulWidget {
  @visibleForTesting
  static bool disableAsyncColorExtraction = false;

  // Survives remounts — caches the computed isLight value per movie ID so
  // colour is restored instantly on CardSwiper key-change remounts.
  static final Map<int, bool> _colorCache = {};

  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final String? friendLikedLabel;

  const RetroCinemaMovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onInfoTap,
    this.onLike,
    this.onDislike,
    this.friendLikedLabel,
  });

  @override
  State<RetroCinemaMovieCard> createState() => _RetroCinemaMovieCardState();
}

class _RetroCinemaMovieCardState extends State<RetroCinemaMovieCard> {
  bool _isLightBackground = false;
  bool _isLoadingColor = true;
  Movie? _enrichedMovie;

  Movie get _movie => _enrichedMovie ?? widget.movie;

  String? _strategyLabel(BuildContext context, String? strategy) {
    if (strategy == null) return null;
    final l10n = context.l10n;
    return switch (strategy) {
      'similar_to_liked' => l10n.strategyLikedSimilar,
      'genre_match'      => l10n.strategyGenreMatch,
      'trending'         => l10n.strategyTrending,
      'top_rated'        => l10n.strategyTopRated,
      'personalized'     => l10n.strategyPersonalized,
      'curated'          => l10n.strategyCurated,
      'actor_discovery'  => l10n.strategyActorDiscovery,
      'director_discovery' => l10n.strategyDirectorDiscovery,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    // Synchronously apply cached enrichment + colour — prevents any visible
    // flash when CardSwiper remounts (e.g. when undo banner appears/hides).
    final cached = MovieCacheService.instance.getCachedMovie(widget.movie.id);
    if (cached != null) {
      _enrichedMovie = cached.copyWith(
        recommendationStrategy:
            cached.recommendationStrategy ?? widget.movie.recommendationStrategy,
        streamingAvailability:
            cached.streamingAvailability ?? widget.movie.streamingAvailability,
      );
    }
    final cachedColor = RetroCinemaMovieCard._colorCache[widget.movie.id];
    if (cachedColor != null) {
      _isLightBackground = cachedColor;
      _isLoadingColor = false;
    } else if (RetroCinemaMovieCard.disableAsyncColorExtraction ||
        widget.movie.posterUrl == null) {
      _isLoadingColor = false;
      _isLightBackground = false;
    }
    // Single deferred operation: enrichment + colour in one setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _enrichCard();
      });
    });
  }

  @override
  void didUpdateWidget(RetroCinemaMovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movie.id != widget.movie.id) {
      final cached = MovieCacheService.instance.getCachedMovie(widget.movie.id);
      final cachedColor = RetroCinemaMovieCard._colorCache[widget.movie.id];
      setState(() {
        _enrichedMovie = cached?.copyWith(
          recommendationStrategy:
              cached.recommendationStrategy ?? widget.movie.recommendationStrategy,
          streamingAvailability:
              cached.streamingAvailability ?? widget.movie.streamingAvailability,
        );
        _isLightBackground = cachedColor ?? false;
        _isLoadingColor = cachedColor == null &&
            widget.movie.posterUrl != null &&
            !RetroCinemaMovieCard.disableAsyncColorExtraction;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _enrichCard();
        });
      });
    }
  }

  /// Computes whether the poster background is light-coloured.
  /// Returns a plain bool so callers can batch it with other state updates.
  Future<bool> _computeIsLight(String posterUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(posterUrl),
        maximumColorCount: 5,
      );
      final dominant = palette.dominantColor?.color ?? AppTheme.filmStripBlack;
      return ThemeData.estimateBrightnessForColor(dominant) == Brightness.light;
    } catch (_) {
      return false;
    }
  }

  /// Fetches enrichment data and poster colour in parallel, then applies
  /// everything in a single setState — exactly one rebuild per card.
  Future<void> _enrichCard() async {
    final targetId = widget.movie.id;
    final posterUrl = widget.movie.posterUrl;
    try {
      final dataFuture = Future.wait([
        MovieCacheService.instance.getMovieDetails(targetId),
        StreamingService.instance.getStreamingAvailability(targetId),
      ]);
      final colorFuture =
          (!RetroCinemaMovieCard.disableAsyncColorExtraction && posterUrl != null)
              ? _computeIsLight(posterUrl)
              : Future.value(false);

      final dataResults = await dataFuture;
      final isLight = await colorFuture;

      if (!mounted || widget.movie.id != targetId) return;
      final detailed = dataResults[0] as Movie;
      final streaming = dataResults[1] as MovieStreamingAvailability?;
      RetroCinemaMovieCard._colorCache[targetId] = isLight;
      setState(() {
        _enrichedMovie = detailed.copyWith(
          recommendationStrategy: detailed.recommendationStrategy ??
              widget.movie.recommendationStrategy,
          streamingAvailability: streaming ??
              detailed.streamingAvailability ??
              widget.movie.streamingAvailability,
        );
        _isLightBackground = isLight;
        _isLoadingColor = false;
      });
    } catch (_) {
      if (mounted && widget.movie.id == targetId) {
        setState(() => _isLoadingColor = false);
      }
    }
  }

  Color get _textColor {
    if (_isLoadingColor) return AppTheme.warmCream;
    return _isLightBackground ? AppTheme.filmStripBlack : AppTheme.warmCream;
  }

  Color get _overlayColor {
    if (_isLightBackground) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return AppTheme.filmStripBlack.withValues(alpha: 0.75);
  }

  String _formatRuntime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Widget _buildPlatformBadges(
      BuildContext context, MovieStreamingAvailability availability) {
    final platforms = availability.platforms.take(3).toList();
    final overflow = availability.availablePlatforms.length - 3;
    return Row(
      children: [
        ...platforms.map((p) => Padding(
              padding: const EdgeInsets.only(right: 6),
              // GestureDetector absorbs the tap so it doesn't reach the
              // CardSwiper, which only handles drag/fling gestures anyway.
              child: GestureDetector(
                onTap: () => launchStreamingSearch(
                  context: context,
                  platform: p,
                  title: _movie.title,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: AppTheme.popcornGold.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 10,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: TextStyle(
              color: _textColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Lato',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strategy = _movie.recommendationStrategy;
    final strategyLabel = _strategyLabel(context, strategy);
    final availability = _movie.streamingAvailability;
    final hasPlatforms =
        availability != null && availability.availablePlatforms.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Movie poster as full background
            Positioned.fill(
              child: widget.movie.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.movie.posterUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.deepMidnightBrown,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.brickRed,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.deepMidnightBrown,
                        child: Icon(
                          Icons.movie_outlined,
                          size: 64,
                          color: AppTheme.warmCream.withValues(alpha: 50),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.deepMidnightBrown,
                      child: Icon(
                        Icons.movie_outlined,
                        size: 64,
                        color: AppTheme.warmCream.withValues(alpha: 50),
                      ),
                    ),
            ),

            // Gradient overlay at bottom for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 280,
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

            // Movie information overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recommendation strategy label
                    if (strategyLabel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.popcornGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.popcornGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          strategyLabel,
                          style: const TextStyle(
                            color: AppTheme.popcornGold,
                            fontSize: 11,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Title
                    Text(
                      _movie.title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: _textColor,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Year, Runtime, Rating row
                    Row(
                      children: [
                        if (_movie.year != null)
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
                              _movie.year!,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (_movie.year != null)
                          const SizedBox(width: 8),

                        // Runtime
                        if (_movie.runtime != null &&
                            _movie.runtime! > 0) ...[
                          Text(
                            _formatRuntime(_movie.runtime!),
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // TMDB Rating
                        if (_movie.voteAverage != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.brickRed,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _movie.formattedRating,
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        // IMDb rating
                        if (_movie.imdbRating != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'IMDb ${_movie.imdbRating!.toStringAsFixed(1)}',
                            style: GoogleFonts.lato(
                              color: AppTheme.popcornGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        // RT Tomatometer
                        if (_movie.rottenTomatoesTomatometer != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🍅 ${_movie.rottenTomatoesTomatometer}%',
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Genres
                    if (_movie.genres != null &&
                        _movie.genres!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _movie.genres!.take(3).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.brickRed.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    // Platform badges
                    if (hasPlatforms) ...[
                      const SizedBox(height: 8),
                      _buildPlatformBadges(context, availability),
                    ],

                    // Action buttons on card (like/dislike)
                    if (widget.onLike != null || widget.onDislike != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.onDislike != null)
                            GestureDetector(
                              onTap: widget.onDislike,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.sepiaBrown,
                                ),
                                child: const Icon(
                                  Icons.thumb_down_rounded,
                                  color: AppTheme.warmCream,
                                  size: 28,
                                ),
                              ),
                            ),
                          if (widget.onDislike != null && widget.onLike != null)
                            const SizedBox(width: 24),
                          if (widget.onLike != null)
                            GestureDetector(
                              onTap: widget.onLike,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.sepiaBrown,
                                ),
                                child: const Icon(
                                  Icons.thumb_up_rounded,
                                  color: AppTheme.warmCream,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Friend-liked badge
            if (widget.friendLikedLabel != null)
              Positioned(
                bottom: 72,
                left: 12,
                right: 60,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.popcornGold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${widget.friendLikedLabel} liked this',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppTheme.creamyWhite,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Info icon — opens quick peek when onInfoTap is provided,
            // otherwise falls back to onTap (full detail navigation)
            if (widget.onTap != null || widget.onInfoTap != null)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: widget.onInfoTap ?? widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _overlayColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: _textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
