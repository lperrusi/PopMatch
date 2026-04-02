import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  /// Converts a color with opacity to use the new withValues method
  /// This replaces the deprecated withOpacity method
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Creates a color with opacity from a theme color
  static Color themeWithOpacity(ColorScheme colorScheme, Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }
} 