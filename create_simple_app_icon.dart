import 'dart:io';
import 'dart:typed_data';

/// Simple script to create a basic app icon
/// This creates a simple red background with white clapperboard design

void main() async {
  print('Creating simple app icon...');
  
  // Create a simple SVG content
  final svgContent = '''
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- Red background with rounded corners -->
  <rect width="1024" height="1024" rx="150" ry="150" fill="#E53E3E"/>
  
  <!-- White clapperboard body -->
  <rect x="205" y="205" width="614" height="430" fill="white"/>
  
  <!-- Black stripes -->
  <rect x="245" y="245" width="49" height="307" fill="black"/>
  <rect x="365" y="245" width="49" height="307" fill="black"/>
  <rect x="485" y="245" width="49" height="307" fill="black"/>
  
  <!-- White handle -->
  <rect x="266" y="717" width="492" height="92" fill="white"/>
</svg>
''';
  
  // Write the SVG file
  final svgFile = File('app_icon.svg');
  await svgFile.writeAsString(svgContent);
  
  print('✓ Created app_icon.svg');
  
  // Now try to convert using rsvg-convert directly
  final outputDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!await outputDir.exists()) {
    print('Error: iOS app icon directory not found');
    return;
  }
  
  // Try converting the main 1024x1024 icon first
  try {
    final result = await Process.run('rsvg-convert', [
      '-w', '1024',
      '-h', '1024',
      'app_icon.svg',
      '-o', '${outputDir.path}/Icon-App-1024x1024@1x.png',
    ]);
    
    if (result.exitCode == 0) {
      print('✓ Generated Icon-App-1024x1024@1x.png');
    } else {
      print('✗ Failed to generate main icon: ${result.stderr}');
    }
  } catch (e) {
    print('✗ Failed to convert SVG: $e');
  }
  
  print('\nApp icon creation complete!');
  print('You may need to manually copy the generated icon to all required sizes.');
} 