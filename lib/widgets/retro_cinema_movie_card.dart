import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/movie.dart';
import '../utils/theme.dart';
import '../services/movie_cache_service.dart';

/// Retro Cinema styled movie card for swipe interface
class RetroCinemaMovieCard extends StatefulWidget {
  @visibleForTesting
  static bool disableAsyncColorExtraction = false;

  final Movie movie;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const RetroCinemaMovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onLike,
    this.onDislike,
  });

  @override
  State<RetroCinemaMovieCard> createState() => _RetroCinemaMovieCardState();
}

class _RetroCinemaMovieCardState extends State<RetroCinemaMovieCard> {
  bool _isLightBackground = false;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    // Preload movie details in background when card is created
    MovieCacheService.instance.preloadMovieDetails(widget.movie.id);

    // Defer color extraction to avoid blocking UI - only extract after card is visible
    // This significantly improves performance, especially on physical devices
    if (!RetroCinemaMovieCard.disableAsyncColorExtraction &&
        widget.movie.posterUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay color extraction to not block initial render
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _extractColorFromImage();
          }
        });
      });
    } else {
      _isLoadingColor = false;
      _isLightBackground = false;
    }
  }

  /// Extracts dominant color from poster image and determines if background is light
  /// OPTIMIZED: Only extracts if card is still mounted and visible
  Future<void> _extractColorFromImage() async {
    if (!mounted) return;

    try {
      final imageProvider = CachedNetworkImageProvider(widget.movie.posterUrl!);
      // Use a smaller sample size for faster processing on mobile devices
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5, // Reduced from default for better performance
      );

      if (mounted) {
        final dominantColor =
            paletteGenerator.dominantColor?.color ?? AppTheme.filmStripBlack;
        final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
        final isLight = brightness == Brightness.light;

        setState(() {
          _isLightBackground = isLight;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
                    // Title with Retro Cinema style
                    Text(
                      widget.movie.title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: _textColor,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Year and Rating row
                    Row(
                      children: [
                        // Year badge
                        if (widget.movie.year != null)
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
                              widget.movie.year!,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (widget.movie.year != null)
                          const SizedBox(width: 12),

                        // Rating
                        if (widget.movie.voteAverage != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.brickRed,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.movie.formattedRating,
                            style: GoogleFonts.lato(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Genres
                    if (widget.movie.genres != null &&
                        widget.movie.genres!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.movie.genres!.take(3).map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.brickRed.withValues(alpha: 20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.brickRed.withValues(alpha: 40),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: GoogleFonts.lato(
                                color: _textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),

                    // Action buttons on card (like/dislike)
                    if (widget.onLike != null || widget.onDislike != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Dislike button
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
                          // Like button
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

            // Tap indicator (info icon)
            if (widget.onTap != null)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: widget.onTap,
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
