import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/theme.dart';

/// Custom loading animation widget that cycles through popcorn frames
/// creating a "popcorn popping into a heart" effect
class PopcornLoadingAnimation extends StatefulWidget {
  final double size;
  final String? message;

  const PopcornLoadingAnimation({
    super.key,
    this.size = 120,
    this.message,
  });

  @override
  State<PopcornLoadingAnimation> createState() =>
      _PopcornLoadingAnimationState();
}

class _PopcornLoadingAnimationState extends State<PopcornLoadingAnimation>
    with SingleTickerProviderStateMixin {
  int _currentFrame = 1;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  /// Starts the animation loop cycling through frames 1-4
  void _startAnimation() {
    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame % 4) + 1; // Cycle 1, 2, 3, 4, 1, 2...
        });
      }
    });
  }

  /// Gets the asset path for the current frame
  String _getFramePath(int frameNumber) {
    return 'assets/animations/loading_frame_$frameNumber.png';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated popcorn/heart image
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            _getFramePath(_currentFrame),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback animation if assets not found
              return _FallbackAnimation(
                size: widget.size,
                frame: _currentFrame,
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: child,
              );
            },
          ),
        ),

        // Optional message below animation
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warmCream.withValues(alpha: 80),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Fallback animation widget when assets are not found
/// Creates a pulsing heart effect using Flutter's built-in animations
class _FallbackAnimation extends StatefulWidget {
  final double size;
  final int frame;

  const _FallbackAnimation({
    required this.size,
    required this.frame,
  });

  @override
  State<_FallbackAnimation> createState() => _FallbackAnimationState();
}

class _FallbackAnimationState extends State<_FallbackAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brickRed.withValues(alpha: 80),
                    AppTheme.brickRed.withValues(alpha: 40),
                  ],
                ),
              ),
              child: Icon(
                _getIconForFrame(widget.frame),
                color: AppTheme.warmCream,
                size: widget.size * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns appropriate icon based on frame number
  IconData _getIconForFrame(int frame) {
    switch (frame) {
      case 1:
        return Icons.local_movies_rounded;
      case 2:
        return Icons.movie_creation_rounded;
      case 3:
        return Icons.movie_filter_rounded;
      case 4:
        return Icons.favorite_rounded;
      default:
        return Icons.local_movies_rounded;
    }
  }
}
