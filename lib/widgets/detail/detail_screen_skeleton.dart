import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/theme.dart';

/// Full-screen shimmer placeholder for the movie/show detail screens, shown
/// while core data + poster colour load ("reveal when ready"). Approximates the
/// real layout — a large header/poster block, title + meta bars, an action-row,
/// synopsis lines, and one horizontal cast/similar row — so the cross-fade to
/// the real content has no layout jump. Static (non-scrolling).
class DetailScreenSkeleton extends StatelessWidget {
  const DetailScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final block = AppTheme.filmStripBlack.withValues(alpha: 0.10);

    Widget bar({double width = double.infinity, double height = 12}) =>
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: width == double.infinity ? 1.0 : width,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );

    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Header / poster block.
          Container(height: 360, color: block),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title.
                bar(width: 0.7, height: 28),
                const SizedBox(height: 14),
                // Meta chips row.
                Row(
                  children: [
                    _chip(block, 56),
                    const SizedBox(width: 10),
                    _chip(block, 72),
                    const SizedBox(width: 10),
                    _chip(block, 48),
                  ],
                ),
                const SizedBox(height: 20),
                // Action-row placeholders (watchlist / like / dislike / share).
                Row(
                  children: List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: block,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Synopsis lines.
                bar(),
                const SizedBox(height: 8),
                bar(),
                const SizedBox(height: 8),
                bar(width: 0.5),
                const SizedBox(height: 32),
                // Section heading.
                bar(width: 0.35, height: 18),
                const SizedBox(height: 16),
                // Horizontal cast/similar row.
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: block,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(Color color, double width) => Container(
        width: width,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
