import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/theme.dart';

/// Vector watchlist button icon for the detail screens, drawn with a
/// [CustomPainter] so it is transparent, crisp at any size, and recolours with
/// state — replacing the opaque-background PNGs.
///
/// - [added] == false → a stroked bookmark outline with a centered "+".
/// - [added] == true  → a filled bookmark with a centered star.
class WatchlistIcon extends StatelessWidget {
  final double size;
  final bool added;

  /// Colour of the outline + plus when not added (usually the adaptive
  /// `textColor` of the detail header).
  final Color inactiveColor;

  /// Fill of the bookmark when added.
  final Color addedColor;

  /// Colour of the star when added.
  final Color addedAccent;

  const WatchlistIcon({
    super.key,
    required this.size,
    required this.added,
    required this.inactiveColor,
    this.addedColor = AppTheme.popcornGold,
    this.addedAccent = AppTheme.filmStripBlack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WatchlistIconPainter(
          added: added,
          inactiveColor: inactiveColor,
          addedColor: addedColor,
          addedAccent: addedAccent,
        ),
      ),
    );
  }
}

class _WatchlistIconPainter extends CustomPainter {
  final bool added;
  final Color inactiveColor;
  final Color addedColor;
  final Color addedAccent;

  _WatchlistIconPainter({
    required this.added,
    required this.inactiveColor,
    required this.addedColor,
    required this.addedAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bookmark/pennant bounds — narrower than the box (a bookmark is tall),
    // leaving a little padding so the stroke isn't clipped.
    final left = w * 0.24;
    final right = w * 0.76;
    final top = h * 0.10;
    final bottom = h * 0.90;
    final notchDepth = h * 0.18; // inward V at the bottom
    final radius = w * 0.10; // rounded top corners
    final cx = w / 2;

    final bookmark = Path()
      ..moveTo(left, top + radius)
      ..quadraticBezierTo(left, top, left + radius, top)
      ..lineTo(right - radius, top)
      ..quadraticBezierTo(right, top, right, top + radius)
      ..lineTo(right, bottom)
      ..lineTo(cx, bottom - notchDepth)
      ..lineTo(left, bottom)
      ..close();

    // Center of the upper body (above the notch) for the plus/star.
    final markCenter = Offset(cx, top + (bottom - notchDepth - top) * 0.46);

    if (added) {
      canvas.drawPath(
        bookmark,
        Paint()
          ..color = addedColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      _drawStar(
        canvas,
        center: markCenter,
        radius: w * 0.17,
        paint: Paint()
          ..color = addedAccent
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    } else {
      final stroke = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawPath(bookmark, stroke);

      // Centered plus.
      final arm = w * 0.12;
      canvas.drawLine(
        Offset(markCenter.dx - arm, markCenter.dy),
        Offset(markCenter.dx + arm, markCenter.dy),
        stroke,
      );
      canvas.drawLine(
        Offset(markCenter.dx, markCenter.dy - arm),
        Offset(markCenter.dx, markCenter.dy + arm),
        stroke,
      );
    }
  }

  /// Draws a filled 5-point star centered at [center].
  void _drawStar(Canvas canvas,
      {required Offset center, required double radius, required Paint paint}) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.5;
    // Start pointing up.
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WatchlistIconPainter old) =>
      old.added != added ||
      old.inactiveColor != inactiveColor ||
      old.addedColor != addedColor ||
      old.addedAccent != addedAccent;
}
