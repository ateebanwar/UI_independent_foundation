import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Segmented neumorphic pills for selecting Male / Female / Other matching the reference.
///
/// Each button features both an outer elevation shadow AND an inner shadow/bevel,
/// providing an elevated, tactile 3D button-like appearance.
class GenderSelectorWidget extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const GenderSelectorWidget({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final options = ['Male', 'Female', 'Other'];

    return Row(
      children: options.map((gender) {
        final isSelected = selectedGender.toLowerCase() == gender.toLowerCase();

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: gender == 'Male' ? 0 : 5,
              right: gender == 'Other' ? 0 : 5,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onGenderChanged(gender),
                borderRadius: BorderRadius.circular(23),
                child: CustomPaint(
                  foregroundPainter: _GenderButtonInnerShadowPainter(
                    isSelected: isSelected,
                    isDark: theme.isDark,
                    borderRadius: 23,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 46,
                    alignment: Alignment.center,
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: theme.primaryGradient,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                            boxShadow: [
                              // Royal blue outer glow
                              BoxShadow(
                                color: theme.isDark
                                    ? LyrithmColors.nightGlowTeal
                                    : LyrithmColors.dayGlowBlue,
                                offset: const Offset(0, 6),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                              // Directional drop shadow
                              BoxShadow(
                                color: theme.isDark
                                    ? const Color(0x70000000)
                                    : const Color(0x4016114B),
                                offset: const Offset(2, 5),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          )
                        : BoxDecoration(
                            color: theme.surface,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: theme.isDark
                                  ? [
                                      const Color(0xFF233539),
                                      const Color(0xFF1E2E32),
                                      const Color(0xFF192629),
                                    ]
                                  : [
                                      const Color(0xFFFFFFFF),
                                      const Color(0xFFFAF7FD),
                                      const Color(0xFFEDE8F5),
                                    ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(
                              color: theme.isDark
                                  ? const Color(0x30FFFFFF)
                                  : Colors.white.withValues(alpha: 0.95),
                              width: 1.2,
                            ),
                            boxShadow: [
                              // Top-left specular highlight
                              BoxShadow(
                                color: theme.isDark
                                    ? const Color(0x25FFFFFF)
                                    : const Color(0xFFFFFFFF),
                                offset: const Offset(-2, -2),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                              // Bottom-right prominent shadow
                              BoxShadow(
                                color: theme.isDark
                                    ? const Color(0x80000000)
                                    : const Color(0x3016114B),
                                offset: const Offset(3, 6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                              // Contact shadow
                              BoxShadow(
                                color: theme.isDark
                                    ? const Color(0x40000000)
                                    : const Color(0x1416114B),
                                offset: const Offset(1, 2),
                                blurRadius: 3,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                    child: Text(
                      gender,
                      style: TextStyle(
                        fontFamilyFallback: const [
                          'Segoe UI',
                          'Roboto',
                          'Helvetica Neue',
                          'sans-serif',
                        ],
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (theme.isDark
                                ? theme.textPrimary
                                : theme.textBadge),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Subtle interior shadow and bevel painter for tactile button feel.
class _GenderButtonInnerShadowPainter extends CustomPainter {
  final bool isSelected;
  final bool isDark;
  final double borderRadius;

  const _GenderButtonInnerShadowPainter({
    required this.isSelected,
    required this.isDark,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    if (isSelected) {
      // Subtle top inner highlight on selected pill
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

      final highlightPath = Path()
        ..addRect(rect.inflate(10))
        ..addRRect(rrect.shift(const Offset(0, 1.5)))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(highlightPath, highlightPaint);
    } else {
      // Top-left subtle inner shadow
      final darkColor = isDark
          ? const Color(0x40000000)
          : const Color(0x2016114B);
      final darkPaint = Paint()
        ..color = darkColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      final darkPath = Path()
        ..addRect(rect.inflate(10))
        ..addRRect(rrect.shift(const Offset(1.5, 1.6)))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(darkPath, darkPaint);

      // Bottom-right inner highlight
      final lightColor = isDark
          ? const Color(0x154E7A7E)
          : const Color(0x80FFFFFF);
      final lightPaint = Paint()
        ..color = lightColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      final lightPath = Path()
        ..addRect(rect.inflate(10))
        ..addRRect(rrect.shift(const Offset(-1.5, -1.5)))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(lightPath, lightPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GenderButtonInnerShadowPainter oldDelegate) =>
      isSelected != oldDelegate.isSelected ||
      isDark != oldDelegate.isDark ||
      borderRadius != oldDelegate.borderRadius;
}
