import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-right neumorphic mode toggle button matching the user's directive:
/// - In Day Mode (default), displays 'Night' (tapping switches to Night Mode).
/// - In Night Mode, automatically shifts to display 'Day' (tapping switches to Day Mode).
/// - Downward-pointing arrow is removed.
/// - Distinct elevated 3D appearance with pronounced outer shadow AND subtle inner shadow.
class ThemeToggleWidget extends ConsumerWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = LyrithmTheme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final label = isDark ? 'Day' : 'Night';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
          ref.read(settingsControllerProvider.notifier).setThemeMode(newMode);
        },
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          foregroundPainter: _PillInnerShadowPainter(
            isDark: theme.isDark,
            borderRadius: 20,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: theme.isDark ? const Color(0xFF1E2E32) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.isDark ? const Color(0x30FFFFFF) : const Color(0xFFFFFFFF),
                width: 1.2,
              ),
              boxShadow: [
                // Top-left crisp specular highlight
                BoxShadow(
                  color: theme.isDark ? const Color(0x25FFFFFF) : const Color(0xFFFFFFFF),
                  offset: const Offset(-3, -3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                // Bottom-right strong directional shadow
                BoxShadow(
                  color: theme.isDark ? const Color(0x90000000) : const Color(0x4516114B),
                  offset: const Offset(4, 7),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
                // Ambient contact shadow
                BoxShadow(
                  color: theme.isDark ? const Color(0x50000000) : const Color(0x2016114B),
                  offset: const Offset(1, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle interior shadow and specular bevel painter for neumorphic pill components.
class _PillInnerShadowPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;

  const _PillInnerShadowPainter({
    required this.isDark,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Subtle dark inner shadow at top-left
    final darkShadowColor = isDark ? const Color(0x50000000) : const Color(0x2516114B);
    final darkPaint = Paint()
      ..color = darkShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final darkPath = Path()
      ..addRect(rect.inflate(10))
      ..addRRect(rrect.shift(const Offset(1.5, 1.8)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(darkPath, darkPaint);

    // Subtle light inner highlight at bottom-right
    final lightHighlightColor = isDark ? const Color(0x184E7A7E) : const Color(0x80FFFFFF);
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
  bool shouldRepaint(covariant _PillInnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark || borderRadius != oldDelegate.borderRadius;
}
