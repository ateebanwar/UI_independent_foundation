import 'package:flutter/material.dart';

enum WaveStyle {
  splashBottom,
  profileAvatar,
}

/// CustomPainter rendering embossed organic neumorphic curves matching the reference.
class WaveCurvePainter extends CustomPainter {
  final WaveStyle style;
  final bool isDark;
  final Color curveLine;
  final Color curveHighlight;

  const WaveCurvePainter({
    required this.style,
    required this.isDark,
    required this.curveLine,
    required this.curveHighlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = curveLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = curveHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (style == WaveStyle.splashBottom) {
      // Flowing S-curve in the lower third above Setup button
      final baseY = h * 0.76;
      path.moveTo(0, baseY);
      path.cubicTo(
        w * 0.28, baseY - 36,
        w * 0.62, baseY + 32,
        w, baseY - 8,
      );
    } else {
      // Create Profile Screen: Sweeping curve looping behind avatar
      final startY = h * 0.32;
      path.moveTo(0, startY);
      path.cubicTo(
        w * 0.20, startY - 14,
        w * 0.32, startY - 60,
        w * 0.48, startY - 62,
      );
      path.cubicTo(
        w * 0.68, startY - 62,
        w * 0.82, startY - 10,
        w, startY - 48,
      );
    }

    // Draw shadow stroke first, then highlight offset by 1px down for embossed neumorphic edge
    canvas.save();
    canvas.translate(0, 1.0);
    canvas.drawPath(path, highlightPaint);
    canvas.restore();

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant WaveCurvePainter oldDelegate) =>
      style != oldDelegate.style || isDark != oldDelegate.isDark;
}
