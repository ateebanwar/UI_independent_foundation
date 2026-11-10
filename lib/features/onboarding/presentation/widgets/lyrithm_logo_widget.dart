import 'dart:math' as math;
import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pixel-accurate Lyrithm squircle logo displaying the authentic 3D iridescent
/// musical note with flowing ribbon wings directly from the reference design.
///
/// Baseline dimensions: 184 × 185 px with soft diffuse neumorphic elevation.
class LyrithmLogoWidget extends StatelessWidget {
  final double size;

  const LyrithmLogoWidget({
    super.key,
    this.size = 185,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final borderRadius = BorderRadius.circular(38);

    return CustomPaint(
      foregroundPainter: _LogoInnerShadowPainter(
        isDark: theme.isDark,
        borderRadius: 38,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.isDark ? const Color(0xFF203034) : const Color(0xFFFFFFFF),
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.isDark ? const Color(0x30FFFFFF) : const Color(0xFFFFFFFF),
            width: 1.5,
          ),
          boxShadow: [
          // Crisp specular highlight on top-left
          BoxShadow(
            color: theme.isDark
                ? const Color(0x20FFFFFF)
                : const Color(0xFFFFFFFF),
            offset: const Offset(-6, -6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          // Deep, pronounced anamorphic shadow cast beneath
          BoxShadow(
            color: theme.isDark
                ? const Color(0x99000000)
                : const Color(0x4016114B),
            offset: const Offset(8, 16),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          // Soft ambient contact shadow
          BoxShadow(
            color: theme.isDark
                ? const Color(0x55000000)
                : const Color(0x2216114B),
            offset: const Offset(2, 6),
            blurRadius: 10,
            spreadRadius: 0,
          ),
          // Wide floor shadow
          BoxShadow(
            color: theme.isDark
                ? const Color(0x40000000)
                : const Color(0x1816114B),
            offset: const Offset(0, 22),
            blurRadius: 36,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.asset(
          'assets/images/lyrithm_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              painter: _MusicNoteLogoPainter(isDark: theme.isDark),
            );
          },
        ),
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

    // Ambient iridescent glow
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

    // Flowing ribbon wings
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

    // Central 3D Note stem
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

    // Notehead
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

class _LogoInnerShadowPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;

  const _LogoInnerShadowPainter({
    required this.isDark,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Subtle inner shadow at top-left
    final darkShadowColor = isDark ? const Color(0x40000000) : const Color(0x2016114B);
    final darkPaint = Paint()
      ..color = darkShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final darkPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(2.5, 2.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(darkPath, darkPaint);

    // Subtle inner highlight at bottom-right
    final lightHighlightColor = isDark ? const Color(0x154E7A7E) : const Color(0x90FFFFFF);
    final lightPaint = Paint()
      ..color = lightHighlightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final lightPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(-2.0, -2.0)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(lightPath, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoInnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark || borderRadius != oldDelegate.borderRadius;
}
