import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/theme.dart';

/// Shimmer skeletons for list-row / tile loading states (Search results,
/// Profile "recently liked"), mirroring [PosterGridSkeleton] for grids. The
/// row shape matches the real content (poster on the left + stacked text bars)
/// so items fill in instead of replacing a centered spinner. Shimmer colours
/// match the grid skeleton for app-wide consistency.
class PosterListSkeleton extends StatelessWidget {
  final int itemCount;
  final double posterWidth;
  final double posterHeight;
  final int lineCount;
  final EdgeInsetsGeometry padding;
  final double rowSpacing;

  const PosterListSkeleton({
    super.key,
    this.itemCount = 6,
    this.posterWidth = 80,
    this.posterHeight = 120,
    this.lineCount = 3,
    this.padding = const EdgeInsets.all(12),
    this.rowSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: ListView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: rowSpacing),
          child: _PosterRowSkeleton(
            posterWidth: posterWidth,
            posterHeight: posterHeight,
            lineCount: lineCount,
          ),
        ),
      ),
    );
  }
}

/// Single shimmer tile matching a `Card` + leading-poster list tile (Profile's
/// recently-liked placeholder). Each pending item renders one of these, so they
/// resolve independently as data arrives.
class PosterListTileSkeleton extends StatelessWidget {
  final double posterWidth;
  final double posterHeight;
  final int lineCount;

  const PosterListTileSkeleton({
    super.key,
    this.posterWidth = 40,
    this.posterHeight = 60,
    this.lineCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _PosterRowSkeleton(
            posterWidth: posterWidth,
            posterHeight: posterHeight,
            lineCount: lineCount,
          ),
        ),
      ),
    );
  }
}

/// Shared row shape: a rounded poster block + [lineCount] text bars. No shimmer
/// wrapper of its own — the parent supplies a single [Shimmer.fromColors] so the
/// sweep stays synchronized.
class _PosterRowSkeleton extends StatelessWidget {
  final double posterWidth;
  final double posterHeight;
  final int lineCount;

  const _PosterRowSkeleton({
    required this.posterWidth,
    required this.posterHeight,
    required this.lineCount,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = AppTheme.filmStripBlack.withValues(alpha: 0.10);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: posterWidth,
          height: posterHeight,
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < lineCount; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        i == 0 ? 0.9 : (i == lineCount - 1 ? 0.4 : 0.65),
                    child: Container(
                      height: i == 0 ? 14 : 11,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
