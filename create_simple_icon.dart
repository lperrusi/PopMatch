// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

void main() async {
  print('🎬 Creating PopMatch app icon...');

  // Create a simple 1024x1024 icon
  await createIcon(1024);

  print('✅ App icon created successfully!');
}

Future<void> createIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Red background
  final paint = ui.Paint()
    ..color = const ui.Color(0xFFE53E3E)
    ..style = ui.PaintingStyle.fill;

  canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);

  // White clapperboard
  final clapperboardSize = size * 0.6;
  final clapperboardX = (size - clapperboardSize) / 2;
  final clapperboardY = (size - clapperboardSize) / 2;

  final whitePaint = ui.Paint()
    ..color = const ui.Color(0xFFFFFFFF)
    ..style = ui.PaintingStyle.fill;

  // Clapperboard body
  canvas.drawRect(
      ui.Rect.fromLTWH(clapperboardX, clapperboardY, clapperboardSize,
          clapperboardSize * 0.7),
      whitePaint);

  // Black stripes
  final blackPaint = ui.Paint()
    ..color = const ui.Color(0xFF000000)
    ..style = ui.PaintingStyle.fill;

  final stripeWidth = clapperboardSize * 0.08;
  final stripeSpacing = clapperboardSize * 0.15;

  for (int i = 0; i < 3; i++) {
    final stripeX = clapperboardX + (i * stripeSpacing);
    canvas.drawRect(
        ui.Rect.fromLTWH(stripeX, clapperboardY + clapperboardSize * 0.1,
            stripeWidth, clapperboardSize * 0.5),
        blackPaint);
  }

  // Handle
  canvas.drawRect(
      ui.Rect.fromLTWH(
          clapperboardX + clapperboardSize * 0.1,
          clapperboardY + clapperboardSize * 0.8,
          clapperboardSize * 0.8,
          clapperboardSize * 0.15),
      whitePaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Save to assets
  final directory = Directory('assets/icons');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}/app_icon.png');
  await file.writeAsBytes(bytes);

  print('✅ Icon saved to: ${file.path}');
}
