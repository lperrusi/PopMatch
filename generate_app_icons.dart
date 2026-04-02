// ignore_for_file: avoid_print
import 'dart:io';

/// Script to generate app icons from SVG
/// This script converts the app_icon.svg to PNG files of different sizes
/// required for iOS app icons

void main() async {
  print('Generating app icons from SVG...');

  // Check if app_icon.svg exists
  final svgFile = File('app_icon.svg');
  if (!await svgFile.exists()) {
    print('Error: app_icon.svg not found in current directory');
    return;
  }

  // iOS app icon sizes
  final iconSizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@1x.png': 60,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-83x83@1x.png': 83,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final outputDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!await outputDir.exists()) {
    print('Error: iOS app icon directory not found');
    return;
  }

  // Read the SVG content
  final svgContent = await svgFile.readAsString();

  print('Converting SVG to PNG files...');

  for (final entry in iconSizes.entries) {
    final filename = entry.key;
    final size = entry.value;

    // Create a temporary SVG with the specific size
    final sizedSvg = svgContent
        .replaceFirst(
            'width="1024" height="1024"', 'width="$size" height="$size"')
        .replaceFirst('viewBox="0 0 1024 1024"', 'viewBox="0 0 $size $size"');

    // Write temporary SVG
    final tempSvgFile = File('temp_icon.svg');
    await tempSvgFile.writeAsString(sizedSvg);

    // Convert SVG to PNG using rsvg-convert
    final outputFile = File('${outputDir.path}/$filename');

    try {
      final result = await Process.run('rsvg-convert', [
        '-w',
        size.toString(),
        '-h',
        size.toString(),
        'temp_icon.svg',
        '-o',
        outputFile.path,
      ]);

      if (result.exitCode == 0) {
        print('✓ Generated $filename (${size}x$size)');
      } else {
        print('✗ Failed to generate $filename: ${result.stderr}');
      }
    } catch (e) {
      print('✗ Failed to generate $filename: $e');
    }

    // Clean up temporary file
    if (await tempSvgFile.exists()) {
      await tempSvgFile.delete();
    }
  }

  print('\nApp icon generation complete!');
}
