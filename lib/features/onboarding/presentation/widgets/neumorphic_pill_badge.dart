import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pure white raised neumorphic pill badge matching the reference design:
/// - Pure white background (#FFFFFF).
/// - Outer elevation shadow extending outward.
/// - Inner shadow extending inward for tactile depth.
/// - Deep navy typography.
class NeumorphicPillBadge extends StatelessWidget {
  final String label;
  final double? width;
  final double height;

  const NeumorphicPillBadge({
    super.key,
    required this.label,
    this.width,
    this.height = 35,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final radius = height / 2;

    return CustomPaint(
      foregroundPainter: _BadgeInnerShadowPainter(
        isDark: theme.isDark,
        borderRadius: radius,
      ),
      child: Container(
        width: width,
        height: height,
        padding: width == null
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5)
            : EdgeInsets.zero,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.isDark ? const Color(0xFF1E2E32) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: theme.isDark ? const Color(0x30FFFFFF) : const Color(0xFFFFFFFF),
            width: 1.2,
          ),
          boxShadow: theme.badgeShadow(),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.badgeText,
        ),
      ),
    );
  }
}

class _BadgeInnerShadowPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;

  const _BadgeInnerShadowPainter({
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final darkPath = Path()
      ..addRect(rect.inflate(10))
      ..addRRect(rrect.shift(const Offset(1.5, 1.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(darkPath, darkPaint);

    // Subtle inner highlight at bottom-right
    final lightHighlightColor = isDark ? const Color(0x154E7A7E) : const Color(0x80FFFFFF);
    final lightPaint = Paint()
      ..color = lightHighlightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final lightPath = Path()
      ..addRect(rect.inflate(10))
      ..addRRect(rrect.shift(const Offset(-1.5, -1.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(lightPath, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgeInnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark || borderRadius != oldDelegate.borderRadius;
}
