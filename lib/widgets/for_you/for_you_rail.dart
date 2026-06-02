import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/movie.dart';
import '../../utils/theme.dart';

/// A Retro Cinema horizontal rail for the "For You" screen: a BebasNeue header
/// with a gold accent underline + a row of poster cards (mirrors the detail
/// screens' "… Like This" cards). Shows a shimmer row while [isLoading] and
/// collapses to nothing when empty.
class ForYouRail extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final bool isLoading;
  final void Function(Movie) onTap;

  const ForYouRail({
    super.key,
    required this.title,
    required this.movies,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && movies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 26,
                    color: AppTheme.filmStripBlack,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.popcornGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: isLoading ? _buildShimmer() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: movies.length,
      itemBuilder: (context, i) => _ForYouPosterCard(
        movie: movies[i],
        onTap: () => onTap(movies[i]),
      ),
    );
  }

  Widget _buildShimmer() {
    final block = AppTheme.filmStripBlack.withValues(alpha: 0.10);
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (context, i) => Container(
          width: 130,
          margin: const EdgeInsets.only(right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: 100,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForYouPosterCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _ForYouPosterCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (c, u) =>
                            Container(color: AppTheme.vintagePaper),
                        errorWidget: (c, u, e) => Container(
                          color: AppTheme.vintagePaper,
                          child: Icon(Icons.movie_outlined,
                              color: AppTheme.filmStripBlack
                                  .withValues(alpha: 0.4)),
                        ),
                      )
                    : Container(
                        color: AppTheme.vintagePaper,
                        child: Icon(Icons.movie_outlined,
                            color:
                                AppTheme.filmStripBlack.withValues(alpha: 0.4)),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: GoogleFonts.lato(
                color: AppTheme.filmStripBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (movie.year != null) ...[
                  Text(
                    movie.year!,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (movie.voteAverage != null && movie.voteAverage! > 0) ...[
                  const Icon(Icons.star_rounded,
                      color: AppTheme.popcornGold, size: 13),
                  const SizedBox(width: 2),
                  Text(
                    movie.formattedRating,
                    style: GoogleFonts.lato(
                      color: AppTheme.filmStripBlack.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
