// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

/// Simple script to generate app icons with red clapperboard design
void main() async {
  print('🎬 Generating PopMatch app icons...');

  // Generate iOS icons
  final iosSizes = [20, 29, 40, 60, 76, 83, 1024];
  for (final size in iosSizes) {
    await generateIcon(size, 'ios');
  }

  // Generate Android icons
  final androidSizes = [48, 72, 96, 144, 192];
  for (final size in androidSizes) {
    await generateIcon(size, 'android');
  }

  print('✅ App icons generated successfully!');
}

Future<void> generateIcon(int size, String platform) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Red background with rounded corners
  final paint = ui.Paint()
    ..color = const ui.Color(0xFFE53E3E) // Red color
    ..style = ui.PaintingStyle.fill;

  final rect = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  final rrect =
      ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(size * 0.15));
  canvas.drawRRect(rrect, paint);

  // White clapperboard
  final clapperboardSize = size * 0.6;
  final clapperboardX = (size - clapperboardSize) / 2;
  final clapperboardY = (size - clapperboardSize) / 2;

  final clapperboardPaint = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF) // White
    ..style = ui.PaintingStyle.fill;

  // Main clapperboard body
  final clapperboardRect = ui.Rect.fromLTWH(
      clapperboardX, clapperboardY, clapperboardSize, clapperboardSize * 0.7);
  canvas.drawRect(clapperboardRect, clapperboardPaint);

  // Black stripes
  final stripePaint = ui.Paint()
    ..color = const ui.Color(0xFF000000) // Black
    ..style = ui.PaintingStyle.fill;

  final stripeWidth = clapperboardSize * 0.08;
  final stripeSpacing = clapperboardSize * 0.15;

  for (int i = 0; i < 3; i++) {
    final stripeX = clapperboardX + (i * stripeSpacing);
    final stripeRect = ui.Rect.fromLTWH(
        stripeX,
        clapperboardY + clapperboardSize * 0.1,
        stripeWidth,
        clapperboardSize * 0.5);
    canvas.drawRect(stripeRect, stripePaint);
  }

  // Clapperboard handle
  final handleRect = ui.Rect.fromLTWH(
      clapperboardX + clapperboardSize * 0.1,
      clapperboardY + clapperboardSize * 0.8,
      clapperboardSize * 0.8,
      clapperboardSize * 0.15);
  canvas.drawRect(handleRect, clapperboardPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Create directory
  final directory = Directory('generated_icons/$platform');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  // Save icon
  final fileName = platform == 'ios'
      ? 'Icon-App-${size}x$size@1x.png'
      : 'ic_launcher_$size.png';

  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);

  print('Generated: $fileName (${size}x$size)');
}
