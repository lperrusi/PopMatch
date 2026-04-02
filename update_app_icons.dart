// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Script to update app icons from assets/icons folder
/// Generates all required iOS and Android icon sizes

void main() async {
  print('🎬 Updating PopMatch app icons...\n');

  // Check if source icons exist
  final sourceIcon1024 = File('assets/icons/app_icon_1024.png');

  if (!await sourceIcon1024.exists()) {
    print('❌ Error: app_icon_1024.png not found in assets/icons/');
    return;
  }

  // Read the source icon
  print('📖 Reading source icon...');
  final sourceBytes = await sourceIcon1024.readAsBytes();
  final sourceImage = img.decodeImage(sourceBytes);

  if (sourceImage == null) {
    print('❌ Error: Could not decode source icon');
    return;
  }

  print('✅ Source icon loaded (${sourceImage.width}x${sourceImage.height})\n');

  // iOS icon sizes from Contents.json
  final iosIcons = {
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

  // Android icon sizes
  final androidIcons = {
    'mipmap-mdpi/ic_launcher.png': 48,
    'mipmap-mdpi/ic_launcher_round.png': 48,
    'mipmap-hdpi/ic_launcher.png': 72,
    'mipmap-hdpi/ic_launcher_round.png': 72,
    'mipmap-xhdpi/ic_launcher.png': 96,
    'mipmap-xhdpi/ic_launcher_round.png': 96,
    'mipmap-xxhdpi/ic_launcher.png': 144,
    'mipmap-xxhdpi/ic_launcher_round.png': 144,
    'mipmap-xxxhdpi/ic_launcher.png': 192,
    'mipmap-xxxhdpi/ic_launcher_round.png': 192,
    'ic_launcher_48.png': 48,
    'ic_launcher_72.png': 72,
    'ic_launcher_96.png': 96,
    'ic_launcher_144.png': 144,
    'ic_launcher_192.png': 192,
  };

  // Generate iOS icons
  print('📱 Generating iOS icons...');
  final iosDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!await iosDir.exists()) {
    await iosDir.create(recursive: true);
  }

  int iosCount = 0;
  for (final entry in iosIcons.entries) {
    final filename = entry.key;
    final size = entry.value;
    final file = File('${iosDir.path}/$filename');

    try {
      final resized = img.copyResize(
        sourceImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.cubic,
      );
      await file.writeAsBytes(img.encodePng(resized));
      print('  ✓ $filename (${size}x$size)');
      iosCount++;
    } catch (e) {
      print('  ✗ Failed to generate $filename: $e');
    }
  }

  print('✅ Generated $iosCount iOS icons\n');

  // Generate Android icons
  print('🤖 Generating Android icons...');
  final androidDir = Directory('android/app/src/main/res');
  if (!await androidDir.exists()) {
    await androidDir.create(recursive: true);
  }

  int androidCount = 0;
  for (final entry in androidIcons.entries) {
    final filename = entry.key;
    final size = entry.value;
    final file = File('${androidDir.path}/$filename');

    try {
      // Create directory if needed
      final fileDir = file.parent;
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }

      final resized = img.copyResize(
        sourceImage,
        width: size,
        height: size,
        interpolation: img.Interpolation.cubic,
      );
      await file.writeAsBytes(img.encodePng(resized));
      print('  ✓ $filename (${size}x$size)');
      androidCount++;
    } catch (e) {
      print('  ✗ Failed to generate $filename: $e');
    }
  }

  print('✅ Generated $androidCount Android icons\n');

  print('🎉 App icons updated successfully!');
  print('📝 Next steps:');
  print('   1. Run: flutter clean');
  print('   2. Run: flutter pub get');
  print('   3. Rebuild the app to see new icons');
}
