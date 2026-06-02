import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/movie.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';

/// Large featured "Top Pick for You" card at the top of the For You screen: a
/// backdrop with a bottom gradient, gold eyebrow, title, rating chip, and an
/// Open CTA. Whole card taps through to [onTap]. Shows a shimmer block while
/// [isLoading] and collapses when there's no [movie].
class ForYouHeroCard extends StatelessWidget {
  final Movie? movie;
  final bool isLoading;
  final VoidCallback onTap;

  const ForYouHeroCard({
    super.key,
    required this.movie,
    required this.isLoading,
    required this.onTap,
  });

  static const double _height = 230;

  @override
  Widget build(BuildContext context) {
    if (movie == null) {
      return isLoading ? _buildShimmer() : const SizedBox.shrink();
    }
    final m = movie!;
    final l10n = context.l10n;
    final img = m.backdropUrl ?? m.posterUrl;
    final hasRating = m.voteAverage != null && m.voteAverage! > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: _height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null)
                  CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    placeholder: (c, u) =>
                        Container(color: AppTheme.deepMidnightBrown),
                    errorWidget: (c, u, e) =>
                        Container(color: AppTheme.deepMidnightBrown),
                  )
                else
                  Container(color: AppTheme.deepMidnightBrown),
                // Readability gradient.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.filmStripBlack.withValues(alpha: 0.88),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                if (hasRating)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.popcornGold, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            m.formattedRating,
                            style: GoogleFonts.lato(
                              color: AppTheme.warmCream,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.forYouTopPick.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          color: AppTheme.popcornGold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.title,
                        style: GoogleFonts.bebasNeue(
                          color: AppTheme.warmCream,
                          fontSize: 30,
                          letterSpacing: 0.5,
                          height: 1.05,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.cinemaRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: AppTheme.warmCream, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              l10n.forYouOpen,
                              style: GoogleFonts.lato(
                                color: AppTheme.warmCream,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Shimmer.fromColors(
        baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
        highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: AppTheme.filmStripBlack.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
