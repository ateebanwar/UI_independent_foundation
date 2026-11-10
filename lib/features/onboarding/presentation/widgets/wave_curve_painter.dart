import 'dart:math' as math;
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = curveHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (style == WaveStyle.splashBottom) {
      // Natural smooth continuous organic wave with zero sharp corners / kinks:
      // Mathematically continuous sinusoid with harmonic roundness
      const segments = 120;
      for (int i = 0; i <= segments; i++) {
        final t = i / segments;
        final x = w * t;
        final theta = ((t - 0.49) / 0.58) * math.pi;
        final y = h * (0.795 - 0.040 * math.sin(theta));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    } else {
      // Create Profile Screen: Exact mathematical curve matching authoritative reference image.
      // - Left: starts at (0, cy + 34), curves up smoothly to cy, and enters the avatar horizontally.
      // - Center: avatar circle sits right on this horizontal equator line at cy.
      // - Right: exits avatar horizontally at cy, runs flat to ~0.74w, then curves UPWARDS to (w, cy - 34).
      final cy = h * 0.40;
      final avatarRadius = math.min(74.0, w * 0.19);
      final avatarLeft = w * 0.50 - avatarRadius;
      final avatarRight = w * 0.50 + avatarRadius;

      // 1. Left curve entering the avatar circle
      path.moveTo(0, cy + 34);
      path.cubicTo(
        w * 0.12, cy + 32,
        w * 0.22, cy,
        w * 0.30, cy,
      );
      path.lineTo(avatarLeft, cy);

      // 2. Right curve exiting the avatar circle and sweeping upward
      path.moveTo(avatarRight, cy);
      path.lineTo(w * 0.74, cy);
      path.cubicTo(
        w * 0.84, cy,
        w * 0.94, cy - 32,
        w, cy - 34,
      );
    }

    // Specular highlight offset slightly upwards for directional top-left illumination
    canvas.save();
    canvas.translate(0, -1.0);
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
