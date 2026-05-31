import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/theme.dart';

// Discover deck action buttons, extracted from swipe_screen.dart. The deck is
// framed in a cross: rectangular MATCH on top, circular NOPE on the left edge,
// circular LIKE on the right edge, rectangular SKIP below the card. Each is a
// sibling of the swiper in the tab Stack, so they stay fixed while cards swipe
// underneath. All are pure (driven by an [onTap] callback).

/// Rectangular MATCH badge (cropped ADMIT ONE ticket) at the top-center.
class MatchActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const MatchActionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Center(
        child: RectActionButton(
          leadingIcon: Icons.local_activity,
          label: 'MATCH',
          trailingIcon: Icons.keyboard_arrow_up_rounded,
          fillColor: AppTheme.cinemaRed,
          borderColor: AppTheme.popcornGold,
          foregroundColor: AppTheme.popcornGold,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Circular NOPE button straddling the card's left edge, vertically centered.
class NopeActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const NopeActionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: SwipeActionButton(
          assetPath: 'assets/swipe/swipe_left.png',
          label: null,
          color: AppTheme.nopeRed,
          size: 64,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Circular LIKE button straddling the card's right edge, vertically centered.
class LikeActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const LikeActionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: SwipeActionButton(
          assetPath: 'assets/swipe/swipe_right.png',
          label: null,
          color: AppTheme.likeGreen,
          size: 64,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Rectangular SKIP badge (cropped "SKIP ↓") centered below the card.
class SkipActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const SkipActionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: RectActionButton(
          leadingIcon: Icons.content_cut,
          label: 'SKIP',
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          fillColor: AppTheme.filmStripBlack.withValues(alpha: 0.9),
          borderColor: AppTheme.sepiaBrown,
          foregroundColor: AppTheme.creamyWhite,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Circular image action button (NOPE / LIKE) with a press-scale animation.
class SwipeActionButton extends StatefulWidget {
  const SwipeActionButton({
    super.key,
    required this.assetPath,
    required this.label,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String assetPath;
  // When null, only the image is rendered (no caption below).
  final String? label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              widget.assetPath,
              width: widget.size,
              height: widget.size,
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 3),
              Text(
                widget.label!,
                style: TextStyle(
                  color: widget.color.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1.1,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable rounded-rectangle badge in the Retro Cinema chip vocabulary: a
/// motif glyph + BebasNeue label + optional direction chevron, on a themed
/// fill with a colored border. Used for MATCH (ticket) and SKIP (scissors),
/// which read better as designed rectangles than the cropped circular PNGs.
class RectActionButton extends StatefulWidget {
  const RectActionButton({
    super.key,
    required this.leadingIcon,
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.onTap,
    this.trailingIcon,
  });

  final IconData leadingIcon;
  final String label;
  final IconData? trailingIcon; // direction chevron (swipe cue)
  final Color fillColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  State<RectActionButton> createState() => _RectActionButtonState();
}

class _RectActionButtonState extends State<RectActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.leadingIcon, color: widget.foregroundColor, size: 20),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.bebasNeue(
                  color: widget.foregroundColor,
                  fontSize: 20,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  color: widget.foregroundColor.withValues(alpha: 0.8),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
