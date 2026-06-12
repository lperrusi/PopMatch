import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/theme.dart';

/// Shared hero header (`SliverAppBar`) for the movie and show detail screens.
///
/// Owns only the chrome that is identical between the two screens: the
/// stretchable backdrop image (with a vintage-paper fallback), the bottom-up
/// dark gradient, the adaptive-color title, and the circular back button. The
/// model-specific bits — the meta row (runtime / external ratings vs
/// seasons & episodes), the why-line, the action row and the inline streaming
/// section — are built by each screen and passed as [children], dropped into
/// the shared padded overlay column directly under the title.
///
/// Differences between the two screens are exposed as parameters: [bottom]
/// (the show's Overview/Seasons `TabBar`), [contentPadding] (the show reserves
/// extra bottom space so the tab bar doesn't hide "Where to watch") and
/// [fallbackIcon].
class DetailHeaderHero extends StatelessWidget {
  /// Backdrop (or poster fallback) URL. When null/empty the [fallbackIcon] is
  /// shown on a vintage-paper background.
  final String? imageUrl;

  final String title;

  /// Adaptive title/content colour derived from the poster palette.
  final Color textColor;

  /// Colour the bottom gradient fades into (the extracted dominant colour).
  final Color overlayColor;

  /// Invoked by the back button. Callers cancel their timers + pop here.
  final VoidCallback onBack;

  /// Meta row, why-line, action row and streaming section (with their spacers),
  /// rendered under the title in the overlay column.
  final List<Widget> children;

  /// Optional app-bar bottom (the show screen passes its Overview/Seasons
  /// `TabBar`).
  final PreferredSizeWidget? bottom;

  /// Overlay column padding — the show reserves extra bottom space (72) so the
  /// tab bar doesn't cover the streaming row.
  final EdgeInsetsGeometry contentPadding;

  final IconData fallbackIcon;

  final double expandedHeight;

  const DetailHeaderHero({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.textColor,
    required this.overlayColor,
    required this.onBack,
    required this.children,
    this.bottom,
    this.contentPadding = const EdgeInsets.all(24),
    this.fallbackIcon = Icons.movie_outlined,
    this.expandedHeight = 450,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.vintagePaper,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop (falls back to the poster, then to an icon).
            Positioned.fill(child: _buildBackdrop()),

            // Gradient for text readability over the lower portion.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, overlayColor],
                  ),
                ),
              ),
            ),

            // Title + caller-provided content overlay.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 36,
                        color: textColor,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: _buildBackButton(),
      actions: const [],
    );
  }

  Widget _buildBackdrop() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: AppTheme.vintagePaper),
      errorWidget: (context, url, error) {
        debugPrint('Detail header image load error: $error for URL: $imageUrl');
        return _fallback();
      },
    );
  }

  Widget _fallback() => Container(
        color: AppTheme.vintagePaper,
        child: Icon(
          fallbackIcon,
          size: 64,
          color: AppTheme.filmStripBlack.withValues(alpha: 50),
        ),
      );

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 52,
            height: 52,
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
            child: const Center(
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.cinemaRed,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
