import 'package:flutter/material.dart';

/// Widget that displays a button image with transparent background
/// This widget ensures transparency is preserved when rendering button assets.
/// 
/// Note: If button images have white backgrounds baked in, run the
/// remove_button_backgrounds.dart script first to process them.
class TransparentButtonImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Color? color;

  const TransparentButtonImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Display image in its original colors without tinting
    // The color parameter is ignored to prevent transparent images from appearing as solid squares
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      // Explicitly don't use color parameter to preserve original image colors
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading button image: $assetPath - $error');
        return errorWidget ??
            const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            );
      },
    );
  }
}

