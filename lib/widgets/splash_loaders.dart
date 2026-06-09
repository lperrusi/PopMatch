import 'package:flutter/material.dart';

/// Splash loading animation: cross-fades through the illustrated popcorn→hearts
/// frame sequence (assets/animations/splash_loading_frame_1..5.png), looping
/// forward-and-back so popcorn morphs into hearts and back ("finding a movie to
/// love"). Semi-flat illustration — on-brand Retro Cinema, not a geometric spinner.
class PopcornMatchLoader extends StatefulWidget {
  final double size;
  const PopcornMatchLoader({super.key, this.size = 72});

  @override
  State<PopcornMatchLoader> createState() => _PopcornMatchLoaderState();
}

class _PopcornMatchLoaderState extends State<PopcornMatchLoader>
    with SingleTickerProviderStateMixin {
  static const int _frameCount = 5;
  static const String _base = 'assets/animations/splash_loading_frame_';

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    // Yo-yo loop: popcorn → hearts → popcorn …, no jarring jump back.
    _c.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      for (var i = 1; i <= _frameCount; i++) {
        precacheImage(AssetImage('$_base$i.png'), context);
      }
      _precached = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _frame(int index, double opacity) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Image.asset(
        '$_base${index + 1}.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          // Map 0..1 → 0..(frameCount-1); cross-fade the two adjacent frames.
          final pos = _c.value * (_frameCount - 1);
          final lower = pos.floor().clamp(0, _frameCount - 1);
          final upper = pos.ceil().clamp(0, _frameCount - 1);
          final frac = pos - lower;
          return Stack(
            alignment: Alignment.center,
            children: [
              _frame(lower, 1.0 - frac),
              if (upper != lower) _frame(upper, frac),
            ],
          );
        },
      ),
    );
  }
}
