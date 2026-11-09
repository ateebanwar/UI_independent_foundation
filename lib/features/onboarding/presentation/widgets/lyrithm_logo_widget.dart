import 'dart:math' as math;
import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pixel-accurate Lyrithm squircle logo with 3D iridescent musical note and ribbon wings.
class LyrithmLogoWidget extends StatelessWidget {
  final double size;

  const LyrithmLogoWidget({
    super.key,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: theme.raisedShadow(depth: 1.2, blur: 20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.isDark
              ? [
                  LyrithmColors.nightSurfaceElevated,
                  LyrithmColors.nightSurface,
                ]
              : [
                  const Color(0xFFFBFBFD),
                  const Color(0xFFEAECF2),
                ],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.72,
          height: size * 0.72,
          child: CustomPaint(
            painter: _MusicNoteLogoPainter(isDark: theme.isDark),
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

    // 1. Soft iridescent ambient glow behind the note
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

    // 2. Swirling ribbon wings (Background waves)
    // Wing 1 - Upper-left flowing wave
    final wing1Path = Path();
    wing1Path.moveTo(w * 0.05, h * 0.42);
    wing1Path.cubicTo(
      w * 0.15, h * 0.28,
      w * 0.35, h * 0.25,
      w * 0.52, h * 0.36,
    );
    wing1Path.cubicTo(
      w * 0.70, h * 0.46,
      w * 0.85, h * 0.38,
      w * 0.95, h * 0.46,
    );
    wing1Path.cubicTo(
      w * 0.82, h * 0.56,
      w * 0.60, h * 0.52,
      w * 0.45, h * 0.46,
    );
    wing1Path.cubicTo(
      w * 0.25, h * 0.40,
      w * 0.12, h * 0.48,
      w * 0.05, h * 0.42,
    );
    wing1Path.close();

    final wing1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8B5CF6), // Purple
          Color(0xFF38BDF8), // Cyan
          Color(0xFFC084FC), // Lilac
          Color(0xFF06B6D4), // Teal
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(wing1Path, wing1Paint);

    // Wing 2 - Delicate lower ribbon filaments
    final wing2Path = Path();
    wing2Path.moveTo(w * 0.10, h * 0.50);
    wing2Path.cubicTo(
      w * 0.22, h * 0.38,
      w * 0.40, h * 0.42,
      w * 0.55, h * 0.55,
    );
    wing2Path.cubicTo(
      w * 0.72, h * 0.68,
      w * 0.88, h * 0.58,
      w * 0.96, h * 0.62,
    );
    wing2Path.cubicTo(
      w * 0.84, h * 0.69,
      w * 0.68, h * 0.67,
      w * 0.52, h * 0.59,
    );
    wing2Path.cubicTo(
      w * 0.35, h * 0.50,
      w * 0.20, h * 0.58,
      w * 0.10, h * 0.50,
    );
    wing2Path.close();

    final wing2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x996366F1),
          Color(0xB3A855F7),
          Color(0xCCE879F9),
          Color(0x9938BDF8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(wing2Path, wing2Paint);

    // Wing 3 - Fine decorative glass accents
    final ribbonStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE0E7FF),
          Color(0xFF38BDF8),
          Color(0xFFF472B6),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final curve1 = Path();
    curve1.moveTo(w * 0.08, h * 0.46);
    curve1.cubicTo(w * 0.25, h * 0.32, w * 0.48, h * 0.36, w * 0.75, h * 0.50);
    canvas.drawPath(curve1, ribbonStroke);

    final curve2 = Path();
    curve2.moveTo(w * 0.18, h * 0.54);
    curve2.cubicTo(w * 0.38, h * 0.44, w * 0.62, h * 0.52, w * 0.90, h * 0.58);
    canvas.drawPath(curve2, ribbonStroke);

    // 3. Central 3D Iridescent Musical Note
    // Note Stem & Flag
    final notePath = Path();

    // Start at top of stem
    notePath.moveTo(w * 0.52, h * 0.26);
    // Downwards stem
    notePath.cubicTo(
      w * 0.51, h * 0.38,
      w * 0.48, h * 0.52,
      w * 0.45, h * 0.60,
    );

    // Notehead oval (rotated ~25 degrees)
    // Stem path
    final stemPath = Path();
    stemPath.moveTo(w * 0.53, h * 0.24);
    stemPath.lineTo(w * 0.57, h * 0.24);
    stemPath.cubicTo(
      w * 0.56, h * 0.42,
      w * 0.52, h * 0.56,
      w * 0.49, h * 0.64,
    );
    stemPath.lineTo(w * 0.44, h * 0.64);
    stemPath.cubicTo(
      w * 0.48, h * 0.54,
      w * 0.52, h * 0.40,
      w * 0.53, h * 0.24,
    );
    stemPath.close();

    // Stem iridescent gradient
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF38BDF8), // Cyan
          Color(0xFF22D3EE),
          Color(0xFFA855F7), // Purple
          Color(0xFF818CF8), // Lilac
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(stemPath, stemPaint);

    // Flag / Top Hook
    final flagPath = Path();
    flagPath.moveTo(w * 0.54, h * 0.24);
    flagPath.cubicTo(
      w * 0.65, h * 0.28,
      w * 0.73, h * 0.38,
      w * 0.68, h * 0.52,
    );
    flagPath.cubicTo(
      w * 0.64, h * 0.44,
      w * 0.60, h * 0.36,
      w * 0.55, h * 0.32,
    );
    flagPath.close();

    final flagPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF22D3EE),
          Color(0xFFC084FC),
          Color(0xFF818CF8),
        ],
      ).createShader(Rect.fromLTWH(w * 0.5, h * 0.2, w * 0.3, h * 0.3))
      ..style = PaintingStyle.fill;
    canvas.drawPath(flagPath, flagPaint);

    // 4. Notehead (Spherical 3D Glass / Metallic Bulb)
    final headCenter = Offset(w * 0.40, h * 0.65);
    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(-math.pi / 8); // -22.5 deg rotation

    final headOvalRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.26,
      height: h * 0.19,
    );

    // Radial 3D sphere gradient
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.85,
        colors: const [
          Color(0xFFFDF4FF), // Specular white highlight
          Color(0xFFE879F9), // Pearl pink
          Color(0xFFA855F7), // Vibrant purple
          Color(0xFF6366F1), // Indigo
          Color(0xFF38BDF8), // Cyan edge
        ],
        stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
      ).createShader(headOvalRect);
    canvas.drawOval(headOvalRect, headPaint);

    // Specular reflection highlight on the notehead
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-w * 0.05, -h * 0.035),
        width: w * 0.08,
        height: h * 0.045,
      ),
      highlightPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MusicNoteLogoPainter oldDelegate) => isDark != oldDelegate.isDark;
}
