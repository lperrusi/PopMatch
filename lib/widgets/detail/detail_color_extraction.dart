import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../utils/theme.dart';

/// Shared poster/backdrop color extraction for the movie and show detail
/// screens. Mix into a [State] and call [extractColorFromImageUrl] after the
/// first frame; use [textColor] / [overlayColor] for adaptive theming.
///
/// [isDisposed] is exposed (and writable) because the detail screens also flip
/// it at mid-life cancellation points to stop in-flight async work — not only
/// in [dispose].
mixin DetailColorExtractionMixin<T extends StatefulWidget> on State<T> {
  bool isLightBackground = false;
  bool isLoadingColor = true;
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  /// Text color that reads well on the extracted background.
  Color get textColor {
    if (isLoadingColor) return AppTheme.warmCream;
    return isLightBackground ? AppTheme.filmStripBlack : AppTheme.warmCream;
  }

  /// Overlay color for better text readability over the backdrop.
  Color get overlayColor {
    if (isLightBackground) {
      return Colors.white.withValues(alpha: 0.85);
    }
    return AppTheme.filmStripBlack.withValues(alpha: 0.75);
  }

  /// Extracts the dominant color from [imageUrl] (pass `backdropUrl ?? posterUrl`)
  /// and updates [isLightBackground] / [isLoadingColor]. Falls back to a dark
  /// background on missing image, timeout, or error.
  Future<void> extractColorFromImageUrl(String? imageUrl) async {
    try {
      if (imageUrl == null) {
        if (mounted && !isDisposed) {
          setState(() {
            isLightBackground = false;
            isLoadingColor = false;
          });
        }
        return;
      }

      final imageProvider = CachedNetworkImageProvider(imageUrl);
      PaletteGenerator paletteGenerator;
      try {
        paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider)
            .timeout(const Duration(seconds: 2));
      } on TimeoutException {
        if (mounted && !isDisposed) {
          setState(() {
            isLightBackground = false;
            isLoadingColor = false;
          });
        }
        return;
      }

      if (mounted && !isDisposed) {
        final dominantColor =
            paletteGenerator.dominantColor?.color ?? AppTheme.filmStripBlack;
        final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
        setState(() {
          isLightBackground = brightness == Brightness.light;
          isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted && !isDisposed) {
        setState(() {
          isLightBackground = false;
          isLoadingColor = false;
        });
      }
    }
  }
}
