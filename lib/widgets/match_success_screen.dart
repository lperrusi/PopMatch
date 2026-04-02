import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../utils/theme.dart';

/// Match success screen that appears when a user swipes up on a movie or show
/// Displays a festive "It's a Match!" celebration with Retro Cinema styling
class MatchSuccessScreen extends StatefulWidget {
  final Movie? movie;
  final TvShow? show;
  final VoidCallback? onContinue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAddToWatchlist;
  /// When false, the secondary "Add to Watchlist" action is hidden (e.g. Discover auto-add).
  final bool showAddToWatchlistButton;
  /// When set, pops this route after the duration (same as tapping back / continue).
  final Duration? autoDismissAfter;

  const MatchSuccessScreen({
    super.key,
    this.movie,
    this.show,
    this.onContinue,
    this.onViewDetails,
    this.onAddToWatchlist,
    this.showAddToWatchlistButton = true,
    this.autoDismissAfter,
  }) : assert(movie != null || show != null,
            'Either movie or show must be provided');

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen>
    with SingleTickerProviderStateMixin {
  /// One timeline: staggered heart → headline → poster → meta → actions.
  late AnimationController _entranceController;

  late Animation<double> _veilOpacity;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  late Animation<double> _matchOpacity;
  late Animation<Offset> _matchSlide;
  late Animation<double> _matchScale;
  late Animation<double> _posterOpacity;
  late Animation<Offset> _posterSlide;
  late Animation<double> _posterScale;
  late Animation<double> _metaOpacity;
  late Animation<Offset> _metaSlide;
  late Animation<double> _extraOpacity;
  late Animation<Offset> _extraSlide;
  late Animation<double> _actionsOpacity;
  late Animation<Offset> _actionsSlide;
  late Animation<double> _backOpacity;

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2100),
      vsync: this,
    );

    _veilOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.12, curve: Curves.easeOut),
    );

    _heartScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.02, 0.34, curve: Curves.elasticOut),
      ),
    );
    _heartOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.02, 0.22, curve: Curves.easeOut),
      ),
    );

    _matchSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _matchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.38, curve: Curves.easeOut),
      ),
    );
    _matchScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.08, 0.40, curve: Curves.easeOutBack),
      ),
    );

    _posterSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.58, curve: Curves.easeOutCubic),
      ),
    );
    _posterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.52, curve: Curves.easeOut),
      ),
    );
    _posterScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.56, curve: Curves.easeOutCubic),
      ),
    );

    _metaSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _metaOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.36, 0.62, curve: Curves.easeOut),
      ),
    );

    _extraSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _extraOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.66, curve: Curves.easeOut),
      ),
    );

    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _actionsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.82, curve: Curves.easeOut),
      ),
    );

    _backOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.14, 0.42, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();

    final dismissAfter = widget.autoDismissAfter;
    if (dismissAfter != null) {
      _autoDismissTimer = Timer(dismissAfter, () {
        if (!mounted) return;
        if (widget.onContinue != null) {
          widget.onContinue!();
        } else {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  /// Gets poster URL (works for both movies and shows)
  String? _getPosterUrl() {
    return widget.movie?.posterUrl ?? widget.show?.posterUrl;
  }

  /// Gets title (works for both movies and shows)
  String _getTitle() {
    return widget.movie?.title ?? widget.show?.name ?? '';
  }

  /// Gets year (works for both movies and shows)
  String? _getYear() {
    return widget.movie?.year ?? widget.show?.year;
  }

  /// Gets formatted rating (works for both movies and shows)
  String _getFormattedRating() {
    return widget.movie?.formattedRating ??
        widget.show?.formattedRating ??
        'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vintagePaper,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Stack(
              children: [
                // Soft vignette that eases in with content
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.15,
                          colors: [
                            AppTheme.vintagePaper.withValues(
                                alpha: 0.12 * _veilOpacity.value),
                            AppTheme.vintagePaper,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildDecorativeElements(),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _heartOpacity,
                          child: ScaleTransition(
                            scale: _heartScale,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 60,
                              color: AppTheme.sepiaBrown,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: _matchSlide,
                          child: FadeTransition(
                            opacity: _matchOpacity,
                            child: ScaleTransition(
                              scale: _matchScale,
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    "It's a",
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 28,
                                      color: AppTheme.sepiaBrown,
                                      letterSpacing: 2,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "MATCH!",
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 42,
                                      color: AppTheme.brickRed,
                                      letterSpacing: 3,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _posterSlide,
                          child: FadeTransition(
                            opacity: _posterOpacity,
                            child: ScaleTransition(
                              scale: _posterScale,
                              alignment: Alignment.center,
                              child: Container(
                                width: 240,
                                height: 360,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.filmStripBlack
                                          .withValues(alpha: 0.18),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _getPosterUrl() != null
                                      ? CachedNetworkImage(
                                          imageUrl: _getPosterUrl()!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: AppTheme.deepMidnightBrown,
                                          ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Container(
                                            color: AppTheme.deepMidnightBrown,
                                            child: Icon(
                                              widget.movie != null
                                                  ? Icons.movie_outlined
                                                  : Icons.tv_outlined,
                                              size: 48,
                                              color: AppTheme.warmCream
                                                  .withValues(alpha: 50),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: AppTheme.deepMidnightBrown,
                                          child: Icon(
                                            widget.movie != null
                                                ? Icons.movie_outlined
                                                : Icons.tv_outlined,
                                            size: 48,
                                            color: AppTheme.warmCream
                                                .withValues(alpha: 50),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SlideTransition(
                          position: _metaSlide,
                          child: FadeTransition(
                            opacity: _metaOpacity,
                            child: Text(
                              _getTitle(),
                              style: GoogleFonts.bebasNeue(
                                fontSize: 22,
                                color: AppTheme.sepiaBrown,
                                letterSpacing: 1.2,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SlideTransition(
                          position: _metaSlide,
                          child: FadeTransition(
                            opacity: _metaOpacity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_getYear() != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brickRed,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.warmCream
                                            .withValues(alpha: 30),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getYear()!,
                                      style: GoogleFonts.lato(
                                        color: AppTheme.warmCream,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.brickRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getFormattedRating(),
                                  style: GoogleFonts.lato(
                                    color: AppTheme.sepiaBrown,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!widget.showAddToWatchlistButton) ...[
                          const SizedBox(height: 12),
                          SlideTransition(
                            position: _extraSlide,
                            child: FadeTransition(
                              opacity: _extraOpacity,
                              child: Text(
                                'Saved to your watchlist',
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.sepiaBrown
                                      .withValues(alpha: 0.85),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: _actionsSlide,
                          child: FadeTransition(
                            opacity: _actionsOpacity,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: widget.onViewDetails ??
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cinemaRed,
                                      foregroundColor: AppTheme.warmCream,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'View Details',
                                      style: GoogleFonts.lato(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.showAddToWatchlistButton) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: widget.onAddToWatchlist ??
                                          () {
                                            Navigator.of(context).pop();
                                          },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.vintagePaper,
                                        foregroundColor: AppTheme.cinemaRed,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Add to Watchlist',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _backOpacity,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (widget.onContinue != null) {
                            widget.onContinue!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.vintagePaper,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.cinemaRed
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.cinemaRed,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds decorative background elements
  Widget _buildDecorativeElements() {
    // Removed flashy decorative elements to blend with background
    return const SizedBox.shrink();
  }
}

/// Helper function to show match success screen as full screen (for movies)
Future<void> showMatchSuccessScreen(
  BuildContext context,
  Movie movie, {
  VoidCallback? onContinue,
  VoidCallback? onViewDetails,
  VoidCallback? onAddToWatchlist,
  bool showAddToWatchlistButton = true,
  Duration? autoDismissAfter,
}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MatchSuccessScreen(
        movie: movie,
        onContinue: onContinue ??
            () {
              Navigator.of(context).pop();
            },
        onViewDetails: onViewDetails ??
            () {
              Navigator.of(context).pop();
              // Navigate to movie detail screen
              // This will be handled by the calling screen
            },
        onAddToWatchlist: onAddToWatchlist ??
            () {
              Navigator.of(context).pop();
            },
        showAddToWatchlistButton: showAddToWatchlistButton,
        autoDismissAfter: autoDismissAfter,
      ),
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      opaque: true,
      fullscreenDialog: false,
    ),
  );
}

/// Helper function to show match success screen as full screen (for TV shows)
Future<void> showShowMatchSuccessScreen(
  BuildContext context,
  TvShow show, {
  VoidCallback? onContinue,
  VoidCallback? onViewDetails,
  VoidCallback? onAddToWatchlist,
  bool showAddToWatchlistButton = true,
  Duration? autoDismissAfter,
}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          MatchSuccessScreen(
        show: show,
        onContinue: onContinue ??
            () {
              Navigator.of(context).pop();
            },
        onViewDetails: onViewDetails ??
            () {
              Navigator.of(context).pop();
              // Navigate to show detail screen
              // This will be handled by the calling screen
            },
        onAddToWatchlist: onAddToWatchlist ??
            () {
              Navigator.of(context).pop();
            },
        showAddToWatchlistButton: showAddToWatchlistButton,
        autoDismissAfter: autoDismissAfter,
      ),
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      opaque: true,
      fullscreenDialog: false,
    ),
  );
}
