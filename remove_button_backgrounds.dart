// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Script to remove white backgrounds from button images
/// This processes all PNG images in assets/buttons/ and removes white backgrounds
void main() async {
  print('🎨 Removing white backgrounds from button images...');
  
  final buttonsDir = Directory('assets/buttons');
  if (!buttonsDir.existsSync()) {
    print('❌ Error: assets/buttons directory not found!');
    return;
  }

  final buttonFiles = buttonsDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList();

  if (buttonFiles.isEmpty) {
    print('⚠️  No PNG files found in assets/buttons/');
    return;
  }

  print('📁 Found ${buttonFiles.length} button image(s) to process...');

  for (final file in buttonFiles) {
    await processImage(file);
  }

  print('✅ Finished processing all button images!');
}

/// Processes a single image to remove white backgrounds
Future<void> processImage(File file) async {
  try {
    print('🔄 Processing: ${file.path.split('/').last}...');

    // Read the image
    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      print('   ❌ Failed to decode image');
      return;
    }

    // Create a new image with the same dimensions
    final processedImage = img.Image(
      width: originalImage.width,
      height: originalImage.height,
    );

    // Process each pixel
    for (int y = 0; y < originalImage.height; y++) {
      for (int x = 0; x < originalImage.width; x++) {
        final pixel = originalImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Check if pixel is white (or very close to white)
        // Threshold: if RGB values are all above 240, treat as white
        final isWhite = r > 240 && g > 240 && b > 240;

        if (isWhite) {
          // Make white pixels transparent
          processedImage.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          // Keep original pixel
          processedImage.setPixel(x, y, pixel);
        }
      }
    }

    // Save the processed image
    final processedBytes = Uint8List.fromList(img.encodePng(processedImage));
    await file.writeAsBytes(processedBytes);

    print('   ✅ Successfully processed!');
  } catch (e) {
    print('   ❌ Error processing image: $e');
  }
}

