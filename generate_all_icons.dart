import 'dart:io';

/// Script to generate all iOS app icon sizes from the main 1024x1024 icon

void main() async {
  print('Generating all iOS app icon sizes...');
  
  final outputDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  final mainIcon = File('${outputDir.path}/Icon-App-1024x1024@1x.png');
  
  if (!await mainIcon.exists()) {
    print('Error: Main icon not found. Run create_simple_app_icon.dart first.');
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
  };
  
  print('Converting main icon to all required sizes...');
  
  for (final entry in iconSizes.entries) {
    final filename = entry.key;
    final size = entry.value;
    
    try {
      final result = await Process.run('sips', [
        '-z', size.toString(), size.toString(),
        mainIcon.path,
        '--out', '${outputDir.path}/$filename',
      ]);
      
      if (result.exitCode == 0) {
        print('✓ Generated $filename (${size}x${size})');
      } else {
        print('✗ Failed to generate $filename: ${result.stderr}');
      }
    } catch (e) {
      print('✗ Failed to generate $filename: $e');
    }
  }
  
  print('\nAll app icons generated!');
  print('Now run the app to see the new icon.');
} 