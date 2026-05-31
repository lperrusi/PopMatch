import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/theme.dart';

/// Shimmer skeleton for a poster grid's initial-load state (Watchlist,
/// Favorites, …). Renders a non-scrollable grid of poster-shaped placeholders
/// matching the real grid's layout, so the content fills in instead of
/// replacing a centered spinner. Use for the empty + loading state only; keep
/// the inline "load more" spinner for pagination.
class PosterGridSkeleton extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const PosterGridSkeleton({
    super.key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _PosterTileSkeleton(),
      ),
    );
  }
}

class _PosterTileSkeleton extends StatelessWidget {
  const _PosterTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Poster block
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Title bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.filmStripBlack.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        // Subtitle bar (shorter)
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.6,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
