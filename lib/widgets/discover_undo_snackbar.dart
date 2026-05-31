import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../utils/theme.dart';
import '../utils/l10n_extension.dart';

/// Inline floating pill shown after a Discover swipe (movies or shows).
///
/// Driven entirely by the parent via [visible], [direction], and [onUndo].
/// No SnackBar / ScaffoldMessenger involved — lives directly in the swipe Stack.
///
/// The parent is responsible for:
/// - Setting [visible] to true when a swipe occurs.
/// - Starting a 2-second timer that sets [visible] back to false (commit).
/// - Calling [onUndo] logic when the UNDO button is tapped.
class DiscoverSwipeFeedback extends StatefulWidget {
  const DiscoverSwipeFeedback({
    super.key,
    required this.visible,
    required this.direction,
    required this.onUndo,
  });

  final bool visible;
  final CardSwiperDirection? direction;
  final VoidCallback onUndo;

  @override
  State<DiscoverSwipeFeedback> createState() => _DiscoverSwipeFeedbackState();
}

class _DiscoverSwipeFeedbackState extends State<DiscoverSwipeFeedback> {
  @override
  Widget build(BuildContext context) {
    final (label, iconWidget) = _labelAndIcon(context, widget.direction);

    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, 0.4),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.filmStripBlack,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.popcornGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 28, height: 28, child: iconWidget),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.creamyWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lato',
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 18,
                  color: AppTheme.creamyWhite.withValues(alpha: 0.25),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: widget.onUndo,
                  child: Text(
                    context.l10n.undoButton,
                    style: const TextStyle(
                      color: AppTheme.popcornGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Lato',
                      letterSpacing: 1.2,
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

  (String label, Widget iconWidget) _labelAndIcon(BuildContext context, CardSwiperDirection? direction) {
    final l10n = context.l10n;
    return switch (direction) {
      CardSwiperDirection.right => (
        l10n.swipeLiked,
        Image.asset('assets/buttons/like_button.png', fit: BoxFit.contain),
      ),
      CardSwiperDirection.left => (
        l10n.swipePassed,
        Image.asset('assets/buttons/dislike_button.png', fit: BoxFit.contain),
      ),
      CardSwiperDirection.top => (
        l10n.swipeWatchlisted,
        const Icon(Icons.bookmark_added, color: AppTheme.popcornGold, size: 22),
      ),
      _ => (
        l10n.swipeSwiped,
        const Icon(Icons.check, color: AppTheme.creamyWhite, size: 22),
      ),
    };
  }
}
