import 'dart:math' as math;
import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pixel-accurate Lyrithm squircle logo displaying the authentic 3D iridescent
/// musical note with flowing ribbon wings directly from the reference design.
class LyrithmLogoWidget extends StatelessWidget {
  final double size;

  const LyrithmLogoWidget({
    super.key,
    this.size = 148,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final borderRadius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: borderRadius,
        boxShadow: theme.raisedShadow(depth: 1.25, blur: 20),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/lyrithm_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Elegant programmatic vector fallback if asset loading is interrupted
            return CustomPaint(
              painter: _MusicNoteLogoPainter(isDark: theme.isDark),
            );
          },
        ),
      ),
    );
  }
}

class _MusicNoteLogoPainter extends CustomPainter {
  final bool isDark;

  const _MusicNoteLogoPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft iridescent ambient glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x6006B6D4),
          const Color(0x40A855F7),
          const Color(0x00A855F7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.45));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, glowPaint);

    // 2. Swirling ribbon wings
    final wing1Path = Path();
    wing1Path.moveTo(w * 0.05, h * 0.42);
    wing1Path.cubicTo(w * 0.15, h * 0.28, w * 0.35, h * 0.25, w * 0.52, h * 0.36);
    wing1Path.cubicTo(w * 0.70, h * 0.46, w * 0.85, h * 0.38, w * 0.95, h * 0.46);
    wing1Path.cubicTo(w * 0.82, h * 0.56, w * 0.60, h * 0.52, w * 0.45, h * 0.46);
    wing1Path.cubicTo(w * 0.25, h * 0.40, w * 0.12, h * 0.48, w * 0.05, h * 0.42);
    wing1Path.close();

    final wing1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFF38BDF8), Color(0xFFC084FC), Color(0xFF06B6D4)],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(wing1Path, wing1Paint);

    // 3. Central 3D Iridescent Musical Note
    final stemPath = Path();
    stemPath.moveTo(w * 0.53, h * 0.24);
    stemPath.lineTo(w * 0.57, h * 0.24);
    stemPath.cubicTo(w * 0.56, h * 0.42, w * 0.52, h * 0.56, w * 0.49, h * 0.64);
    stemPath.lineTo(w * 0.44, h * 0.64);
    stemPath.cubicTo(w * 0.48, h * 0.54, w * 0.52, h * 0.40, w * 0.53, h * 0.24);
    stemPath.close();

    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF38BDF8), Color(0xFF22D3EE), Color(0xFFA855F7), Color(0xFF818CF8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(stemPath, stemPaint);

    // 4. Notehead
    final headCenter = Offset(w * 0.40, h * 0.65);
    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(-math.pi / 8);

    final headOvalRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.26,
      height: h * 0.19,
    );

    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.85,
        colors: const [
          Color(0xFFFDF4FF),
          Color(0xFFE879F9),
          Color(0xFFA855F7),
          Color(0xFF6366F1),
          Color(0xFF38BDF8),
        ],
        stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
      ).createShader(headOvalRect);
    canvas.drawOval(headOvalRect, headPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusicNoteLogoPainter oldDelegate) => isDark != oldDelegate.isDark;
}
