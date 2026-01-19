import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../models/movie.dart';
import '../utils/theme.dart';

/// Match success screen that appears when a user swipes up on a movie
/// Displays a festive "It's a Match!" celebration with Retro Cinema styling
class MatchSuccessScreen extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onContinue;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAddToWatchlist;

  const MatchSuccessScreen({
    super.key,
    required this.movie,
    this.onContinue,
    this.onViewDetails,
    this.onAddToWatchlist,
  });

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();

    // Scale animation for the match text
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(_scaleController);

    // Rotation animation for decorative elements
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Fade animation for the entire screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppTheme.vintagePaper,
        body: SafeArea(
          child: Container(
            color: AppTheme.vintagePaper,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Decorative background elements
                _buildDecorativeElements(),

                // Main content
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Smaller cream heart icon at top
                        Icon(
                          Icons.favorite_rounded,
                          size: 60,
                          color: AppTheme.sepiaBrown,
                        ),
                        const SizedBox(height: 12),

                        // Animated "It's a Match!" text (smaller)
                        ScaleTransition(
                          scale: _scaleAnimation,
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

                        const SizedBox(height: 20),

                        // Single movie poster (selected movie only) - bigger but ensuring all elements fit
                        Container(
                          width: 240,
                          height: 360,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.movie.posterUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.movie.posterUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppTheme.deepMidnightBrown,
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppTheme.deepMidnightBrown,
                                      child: Icon(
                                        Icons.movie_outlined,
                                        size: 48,
                                        color: AppTheme.warmCream.withValues(alpha: 50),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppTheme.deepMidnightBrown,
                                    child: Icon(
                                      Icons.movie_outlined,
                                      size: 48,
                                      color: AppTheme.warmCream.withValues(alpha: 50),
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Movie title (smaller)
                        Text(
                          widget.movie.title,
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

                        const SizedBox(height: 10),

                        // Movie year and rating (smaller)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.movie.year != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brickRed,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.warmCream.withValues(alpha: 30),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.movie.year!,
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
                              widget.movie.formattedRating,
                              style: GoogleFonts.lato(
                                color: AppTheme.sepiaBrown,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action buttons - View Details, Add to Watchlist
                        Column(
                          children: [
                            // View Details button
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                            const SizedBox(height: 12),
                            
                            // Add to Watchlist button
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Back button in top left corner - placed last to ensure it's on top and clickable
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
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
              ],
            ),
          ),
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

/// Helper function to show match success screen as full screen
Future<void> showMatchSuccessScreen(
  BuildContext context,
  Movie movie, {
  VoidCallback? onContinue,
  VoidCallback? onViewDetails,
  VoidCallback? onAddToWatchlist,
}) async {
  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => MatchSuccessScreen(
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

