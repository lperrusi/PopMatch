import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/l10n_extension.dart';
import '../../utils/theme.dart';

/// Poster-shaped shimmer skeleton card for the Discover deck loading state.
class DiscoverSkeletonCard extends StatelessWidget {
  const DiscoverSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.filmStripBlack.withValues(alpha: 0.12),
      highlightColor: AppTheme.filmStripBlack.withValues(alpha: 0.06),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.warmCream.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                    color: AppTheme.filmStripBlack.withValues(alpha: 0.08)),
              ),
              Container(
                height: 56,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppTheme.filmStripBlack.withValues(alpha: 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.filmStripBlack.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared Discover loading UI (stacked skeleton cards + label) for both tabs.
class DiscoverSwipeLoadingState extends StatelessWidget {
  final String label;

  const DiscoverSwipeLoadingState({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: AppTheme.vintagePaper,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 420,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: Transform.scale(
                          scale: 0.92,
                          child: const DiscoverSkeletonCard(),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.92,
                        child: const DiscoverSkeletonCard(),
                      ),
                      const DiscoverSkeletonCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.filmStripBlack.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Smart empty state shown when active Discover filters produce zero results.
class DiscoverFilteredEmptyState extends StatelessWidget {
  final IconData icon;
  final List moods;
  final List genres;
  final List platforms;
  final VoidCallback onRelax;

  const DiscoverFilteredEmptyState({
    super.key,
    required this.icon,
    required this.moods,
    required this.genres,
    required this.platforms,
    required this.onRelax,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    if (platforms.isNotEmpty && genres.isEmpty && moods.isEmpty) {
      message =
          'No titles found on your selected platforms.\nTry adding more platforms or clearing the platform filter.';
    } else if (genres.isNotEmpty && platforms.isEmpty && moods.isEmpty) {
      message =
          'No titles found in your selected genres.\nTry broadening your genre filter.';
    } else if (moods.isNotEmpty && genres.isEmpty && platforms.isEmpty) {
      message =
          'No titles match this mood.\nTry a different mood or clear the mood filter.';
    } else {
      message =
          'No titles match your current filters.\nTry relaxing some filters to see more results.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64, color: AppTheme.filmStripBlack.withValues(alpha: 50)),
            const SizedBox(height: 16),
            Text(
              context.l10n.nothingHereLabel,
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: AppTheme.filmStripBlack,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRelax,
              icon: const Icon(Icons.tune_outlined, size: 16),
              label: Text(context.l10n.relaxFiltersButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cinemaRed,
                foregroundColor: AppTheme.warmCream,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
