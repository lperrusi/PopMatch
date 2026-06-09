import 'package:flutter/material.dart';

/// Splash loading animation: a stop-motion flipbook of the illustrated
/// popcorn→hearts frame sequence (assets/animations/splash_loading_frame_1..5.png).
/// It plays popcorn kernels → hearts → popcorn… (yo-yo loop) — "finding a movie to
/// love." Semi-flat illustration, on-brand Retro Cinema, not a geometric spinner.
///
/// Frames are cropped to their content (≈768×348), so the loader sizes to that
/// aspect and the art renders large. One discrete frame is shown per tick (no
/// cross-fade) to avoid ghosting between frames whose elements shift position.
class PopcornMatchLoader extends StatefulWidget {
  /// Rendered height in logical px; width is derived from the frame aspect.
  final double height;
  const PopcornMatchLoader({super.key, this.height = 58});

  @override
  State<PopcornMatchLoader> createState() => _PopcornMatchLoaderState();
}

class _PopcornMatchLoaderState extends State<PopcornMatchLoader>
    with SingleTickerProviderStateMixin {
  static const int _frameCount = 5;
  static const String _base = 'assets/animations/splash_loading_frame_';
  // Source frames are cropped to this content box (see splash_loaders plan).
  static const double _frameAspect = 768 / 348;

  late final AnimationController _c = AnimationController(
    vsync: this,
    // ~260 ms per frame across 4 steps → ~2.4 s full popcorn↔hearts cycle.
    duration: const Duration(milliseconds: 1040),
  );
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    // Yo-yo: popcorn → hearts → popcorn …, no jarring jump back to kernels.
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

  @override
  Widget build(BuildContext context) {
    final width = widget.height * _frameAspect;
    return SizedBox(
      width: width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          // Map 0..1 → a single discrete frame index (flipbook, no cross-fade).
          final index =
              (_c.value * (_frameCount - 1)).round().clamp(0, _frameCount - 1);
          return Image.asset(
            '$_base${index + 1}.png',
            width: width,
            height: widget.height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
