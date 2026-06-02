import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../models/tv_show.dart';
import '../models/streaming_platform.dart';
import '../providers/auth_provider.dart';
import '../providers/show_provider.dart';
import '../utils/theme.dart';
import '../utils/l10n_extension.dart';
import '../utils/recommendation_reason.dart';
import '../utils/recommendation_reason_label.dart';
import '../services/user_preferences_session_cache.dart';
import '../utils/streaming_url_launcher.dart';
import '../services/movie_cache_service.dart';
import '../services/streaming_service.dart';

/// Retro Cinema styled TV show card for swipe interface
class RetroCinemaShowCard extends StatefulWidget {
  @visibleForTesting
  static bool disableAsyncColorExtraction = false;

  // Survives remounts — caches the computed isLight value per show ID.
  static final Map<int, bool> _colorCache = {};

  final TvShow show;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const RetroCinemaShowCard({
    super.key,
    required this.show,
    this.onTap,
    this.onInfoTap,
    this.onLike,
    this.onDislike,
  });

  @override
  State<RetroCinemaShowCard> createState() => _RetroCinemaShowCardState();
}

class _RetroCinemaShowCardState extends State<RetroCinemaShowCard> {
  bool _isLightBackground = false;
  bool _isLoadingColor = true;
  TvShow? _enrichedShow;

  TvShow get _show => _enrichedShow ?? widget.show;

  /// The "why" badge text: a specific "Because you like {Genre}" when the
  /// show's genres match the user's picks, else a generic strategy label.
  String? _reasonLabel(BuildContext context) {
    final userGenreIds = <int>{};
    final raw = context.read<AuthProvider>().userData?.preferences['selectedGenres'];
    if (raw is List) {
      for (final g in raw) {
        final id = g is int ? g : int.tryParse(g.toString());
        if (id != null) userGenreIds.add(id);
      }
    }
    final prefs = UserPreferencesSessionCache().cachedPreferences;
    final reason = buildRecommendationReason(
      strategy: _show.recommendationStrategy,
      genreIds: _show.genreIds,
      genreNames: _show.genres,
      userGenreIds: userGenreIds,
      genres: context.read<ShowProvider>().genres,
      castNames: _show.cast?.take(6).map((c) => c.name).toList(),
      userActors: prefs?.preferredActors.toSet() ?? const {},
    );
    return recommendationReasonLabel(context.l10n, reason);
  }

  @override
  void initState() {
    super.initState();
    // Synchronously apply cached enrichment + colour — prevents any visible
    // flash when CardSwiper remounts (e.g. when undo banner appears/hides).
    final cached = MovieCacheService.instance.getCachedShow(widget.show.id);
    if (cached != null) {
      _enrichedShow = cached.copyWith(
        recommendationStrategy:
            cached.recommendationStrategy ?? widget.show.recommendationStrategy,
        streamingAvailability:
            cached.streamingAvailability ?? widget.show.streamingAvailability,
      );
    }
    final cachedColor = RetroCinemaShowCard._colorCache[widget.show.id];
    if (cachedColor != null) {
      _isLightBackground = cachedColor;
      _isLoadingColor = false;
    } else if (RetroCinemaShowCard.disableAsyncColorExtraction ||
        widget.show.posterUrl == null) {
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
  void didUpdateWidget(RetroCinemaShowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show.id != widget.show.id) {
      final cached = MovieCacheService.instance.getCachedShow(widget.show.id);
      final cachedColor = RetroCinemaShowCard._colorCache[widget.show.id];
      setState(() {
        _enrichedShow = cached?.copyWith(
          recommendationStrategy:
              cached.recommendationStrategy ?? widget.show.recommendationStrategy,
          streamingAvailability:
              cached.streamingAvailability ?? widget.show.streamingAvailability,
        );
        _isLightBackground = cachedColor ?? false;
        _isLoadingColor = cachedColor == null &&
            widget.show.posterUrl != null &&
            !RetroCinemaShowCard.disableAsyncColorExtraction;
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
    final targetId = widget.show.id;
    final posterUrl = widget.show.posterUrl;
    try {
      final dataFuture = Future.wait([
        MovieCacheService.instance.getShowDetails(targetId),
        StreamingService.instance.getStreamingAvailabilityForTv(targetId),
      ]);
      final colorFuture =
          (!RetroCinemaShowCard.disableAsyncColorExtraction && posterUrl != null)
              ? _computeIsLight(posterUrl)
              : Future.value(false);

      final dataResults = await dataFuture;
      final isLight = await colorFuture;

      if (!mounted || widget.show.id != targetId) return;
      final detailed = dataResults[0] as TvShow;
      final streaming = dataResults[1] as MovieStreamingAvailability?;
      RetroCinemaShowCard._colorCache[targetId] = isLight;
      setState(() {
        _enrichedShow = detailed.copyWith(
          recommendationStrategy: detailed.recommendationStrategy ??
              widget.show.recommendationStrategy,
          streamingAvailability: streaming ??
              detailed.streamingAvailability ??
              widget.show.streamingAvailability,
        );
        _isLightBackground = isLight;
        _isLoadingColor = false;
      });
    } catch (_) {
      if (mounted && widget.show.id == targetId) {
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

  Widget _buildPlatformBadges(
      BuildContext context, MovieStreamingAvailability availability) {
    final platforms = availability.platforms.take(3).toList();
    final overflow = availability.availablePlatforms.length - 3;
    return Row(
      children: [
        ...platforms.map((p) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => launchStreamingSearch(
                  context: context,
                  platform: p,
                  title: _show.name,
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
    final strategyLabel = _reasonLabel(context);
    final availability = _show.streamingAvailability;
    final hasPlatforms =
        availability != null && availability.availablePlatforms.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.show.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.show.posterUrl!,
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
                          Icons.tv_outlined,
                          size: 64,
                          color: AppTheme.warmCream.withValues(alpha: 50),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.deepMidnightBrown,
                      child: Icon(
                        Icons.tv_outlined,
                        size: 64,
                        color: AppTheme.warmCream.withValues(alpha: 50),
                      ),
                    ),
            ),

            // Gradient overlay
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

            // Show information overlay
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
                      _show.name,
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

                    // Year, Seasons, Rating row
                    Row(
                      children: [
                        if (_show.year != null)
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
                              _show.year!,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (_show.year != null)
                          const SizedBox(width: 8),

                        // Seasons count
                        if (_show.numberOfSeasons != null) ...[
                          Text(
                            _show.numberOfSeasons == 1
                                ? '1 Season'
                                : '${_show.numberOfSeasons} Seasons',
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // TMDB Rating
                        if (_show.voteAverage != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.brickRed,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _show.formattedRating,
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        // IMDb rating
                        if (_show.imdbRating != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'IMDb ${_show.imdbRating!.toStringAsFixed(1)}',
                            style: GoogleFonts.lato(
                              color: AppTheme.popcornGold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        // RT Tomatometer
                        if (_show.rottenTomatoesTomatometer != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🍅 ${_show.rottenTomatoesTomatometer}%',
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
                    if (_show.genres != null &&
                        _show.genres!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _show.genres!.take(3).map((genre) {
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

                    // Action buttons
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
