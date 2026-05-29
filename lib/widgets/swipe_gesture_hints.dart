import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

/// One-time animated overlay that teaches new users the swipe gestures.
/// Shows on first Discover session, auto-dismisses after 5s, then never again.
class SwipeGestureHints extends StatefulWidget {
  final VoidCallback onDismiss;

  const SwipeGestureHints({super.key, required this.onDismiss});

  @override
  State<SwipeGestureHints> createState() => _SwipeGestureHintsState();
}

class _SwipeGestureHintsState extends State<SwipeGestureHints>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _autoTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SWIPE TO DISCOVER',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                      color: AppTheme.popcornGold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Up hint
                  _hintRow(
                    assetPath: 'assets/swipe/swipe_up.png',
                    label: 'Watchlist',
                    direction: Axis.vertical,
                    isUp: true,
                  ),
                  const SizedBox(height: 12),

                  // Left / Right hints side by side
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _hintRow(
                        assetPath: 'assets/swipe/swipe_left.png',
                        label: 'Pass',
                        direction: Axis.horizontal,
                        isLeft: true,
                      ),
                      const SizedBox(width: 48),
                      _hintRow(
                        assetPath: 'assets/swipe/swipe_right.png',
                        label: 'Like',
                        direction: Axis.horizontal,
                        isLeft: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Down hint
                  _hintRow(
                    assetPath: 'assets/swipe/swipe_down.png',
                    label: 'Skip',
                    direction: Axis.vertical,
                    isUp: false,
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Tap anywhere to dismiss',
                    style: GoogleFonts.lato(
                      color: AppTheme.warmCream.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hintRow({
    required String assetPath,
    required String label,
    required Axis direction,
    bool isUp = true,
    bool isLeft = true,
  }) {
    final icon = Image.asset(
      assetPath,
      width: 40,
      height: 40,
      color: AppTheme.warmCream.withValues(alpha: 0.9),
    );
    final text = Text(
      label,
      style: GoogleFonts.lato(
        color: AppTheme.warmCream,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: isUp ? [icon, const SizedBox(height: 4), text] : [text, const SizedBox(height: 4), icon],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isLeft
          ? [icon, const SizedBox(width: 6), text]
          : [text, const SizedBox(width: 6), icon],
    );
  }
}
