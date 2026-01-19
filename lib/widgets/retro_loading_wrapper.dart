import 'package:flutter/material.dart';
import 'popcorn_loading_animation.dart';
import '../utils/theme.dart';

/// Wrapper widget that provides a consistent loading experience
/// with Retro Cinema aesthetic throughout the app
class RetroLoadingWrapper extends StatelessWidget {
  final String? message;
  final double size;
  final Color? backgroundColor;

  const RetroLoadingWrapper({
    super.key,
    this.message,
    this.size = 120,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppTheme.deepMidnightBrown,
      child: Center(
        child: PopcornLoadingAnimation(
          size: size,
          message: message,
        ),
      ),
    );
  }
}

/// Full screen loading overlay with Retro Cinema styling
class RetroLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const RetroLoadingOverlay({
    super.key,
    this.message,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: AppTheme.deepMidnightBrown.withValues(alpha: 95),
      child: Center(
        child: PopcornLoadingAnimation(
          size: 140,
          message: message ?? 'Loading...',
        ),
      ),
    );
  }
}

