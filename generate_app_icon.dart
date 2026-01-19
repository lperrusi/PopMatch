import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// Script to generate app icons with the red clapperboard design
void main() async {
  await generateAppIcons();
}

Future<void> generateAppIcons() async {
  print('🎬 Generating PopMatch app icons...');
  
  // iOS icon sizes
  final iosSizes = [
    20, 29, 40, 60, 76, 83, 1024
  ];
  
  // Android icon sizes
  final androidSizes = [
    48, 72, 96, 144, 192
  ];
  
  // Generate iOS icons
  for (final size in iosSizes) {
    await generateIcon(size, 'ios', size);
  }
  
  // Generate Android icons
  for (final size in androidSizes) {
    await generateIcon(size, 'android', size);
  }
  
  print('✅ App icons generated successfully!');
}

Future<void> generateIcon(int size, String platform, int targetSize) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Create the red background with rounded corners
  final paint = Paint()
    ..color = const Color(0xFFE53E3E) // Red color
    ..style = PaintingStyle.fill;
  
  final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.15));
  canvas.drawRRect(rrect, paint);
  
  // Draw the clapperboard
  final clapperboardSize = size * 0.6;
  final clapperboardX = (size - clapperboardSize) / 2;
  final clapperboardY = (size - clapperboardSize) / 2;
  
  // Draw the clapperboard base (white rectangle)
  final clapperboardPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  
  final clapperboardRect = Rect.fromLTWH(
    clapperboardX,
    clapperboardY,
    clapperboardSize,
    clapperboardSize * 0.7
  );
  canvas.drawRect(clapperboardRect, clapperboardPaint);
  
  // Draw the clapperboard stripes
  final stripePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;
  
  final stripeWidth = clapperboardSize * 0.08;
  final stripeSpacing = clapperboardSize * 0.15;
  
  for (int i = 0; i < 3; i++) {
    final stripeX = clapperboardX + (i * stripeSpacing);
    final stripeRect = Rect.fromLTWH(
      stripeX,
      clapperboardY + clapperboardSize * 0.1,
      stripeWidth,
      clapperboardSize * 0.5
    );
    canvas.drawRect(stripeRect, stripePaint);
  }
  
  // Draw the clapperboard handle
  final handleRect = Rect.fromLTWH(
    clapperboardX + clapperboardSize * 0.1,
    clapperboardY + clapperboardSize * 0.8,
    clapperboardSize * 0.8,
    clapperboardSize * 0.15
  );
  canvas.drawRect(handleRect, clapperboardPaint);
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  // Create directory if it doesn't exist
  final directory = Directory('generated_icons/$platform');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  
  // Save the icon
  final fileName = platform == 'ios' 
    ? 'Icon-App-${size}x${size}@1x.png'
    : 'ic_launcher_${size}.png';
  
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  
  print('Generated: $fileName (${size}x${size})');
} 