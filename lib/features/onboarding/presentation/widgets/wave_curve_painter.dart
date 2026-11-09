import 'package:flutter/material.dart';

enum WaveStyle {
  splashBottom,
  profileAvatar,
}

/// CustomPainter rendering embossed organic neumorphic curves matching the reference design.
///
/// Features authentic dual-stroke embossing (directional shadow + specular highlight)
/// giving a tactile grooved appearance on the neumorphic surface.
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
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = curveHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (style == WaveStyle.splashBottom) {
      // Flowing S-curve across lower section above Setup button
      final baseY = h * 0.55;
      path.moveTo(0, baseY);
      path.cubicTo(
        w * 0.26, baseY + 28,
        w * 0.60, baseY - 36,
        w, baseY - 8,
      );
    } else {
      // Create Profile Screen: Sweeping curve embracing avatar
      final baseY = h * 0.42;
      path.moveTo(0, baseY + 20);
      path.cubicTo(
        w * 0.18, baseY - 10,
        w * 0.32, baseY - 52,
        w * 0.50, baseY - 54,
      );
      path.cubicTo(
        w * 0.68, baseY - 54,
        w * 0.82, baseY - 12,
        w, baseY - 24,
      );
    }

    // Specular highlight offset downwards by 1.2px for embossed groove effect
    canvas.save();
    canvas.translate(0, 1.2);
    canvas.drawPath(path, highlightPaint);
    canvas.restore();

    // Primary shadow contour line
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant WaveCurvePainter oldDelegate) =>
      style != oldDelegate.style ||
      isDark != oldDelegate.isDark ||
      curveLine != oldDelegate.curveLine ||
      curveHighlight != oldDelegate.curveHighlight;
}
