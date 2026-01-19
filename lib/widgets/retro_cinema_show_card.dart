import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/tv_show.dart';
import '../utils/theme.dart';

/// Retro Cinema styled TV show card for swipe interface
class RetroCinemaShowCard extends StatefulWidget {
  final TvShow show;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const RetroCinemaShowCard({
    super.key,
    required this.show,
    this.onTap,
    this.onLike,
    this.onDislike,
  });

  @override
  State<RetroCinemaShowCard> createState() => _RetroCinemaShowCardState();
}

class _RetroCinemaShowCardState extends State<RetroCinemaShowCard> {
  Color? _dominantColor;
  bool _isLightBackground = false;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    
    // Defer color extraction to avoid blocking UI
    if (widget.show.posterUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _extractColorFromImage() async {
    if (!mounted) return;
    
    try {
      final imageProvider = CachedNetworkImageProvider(widget.show.posterUrl!);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
      );
      
      if (mounted) {
        final dominantColor = paletteGenerator.dominantColor?.color ?? AppTheme.filmStripBlack;
        final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
        final isLight = brightness == Brightness.light;
        
        setState(() {
          _dominantColor = dominantColor;
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

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      widget.show.name,
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
                    Row(
                      children: [
                        if (widget.show.year != null)
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
                              widget.show.year!,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (widget.show.year != null) const SizedBox(width: 12),
                        if (widget.show.voteAverage != null) ...[
                          Icon(
                            Icons.star_rounded,
                            color: AppTheme.brickRed,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.show.formattedRating,
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
                    if (widget.show.genres != null && widget.show.genres!.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.show.genres!.take(3).map((genre) {
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
                                decoration: BoxDecoration(
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
                                decoration: BoxDecoration(
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
