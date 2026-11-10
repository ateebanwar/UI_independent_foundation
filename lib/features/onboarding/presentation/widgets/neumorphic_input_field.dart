import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pure bright white neumorphic text input field matching the reference design.
///
/// Features pure white background (#FFFFFF) with dual-direction shadowing:
/// - Outer elevation shadow extending outward for tactile elevation.
/// - Inner cavity shadow extending inward for an authentic sunken / recessed cavity effect.
/// - Navy blue cursor and clear text hierarchy.
class NeumorphicInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double height;

  const NeumorphicInputField({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.surfaceInset,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.isDark
                  ? const Color(0x20FFFFFF)
                  : const Color(0x2016114B),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.isDark
                    ? const Color(0x40000000)
                    : const Color(0x1016114B),
                offset: const Offset(0, 1),
                blurRadius: 3,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: theme.isDark
                    ? const Color(0x10FFFFFF)
                    : const Color(0x40FFFFFF),
                offset: const Offset(0, -1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Inner shadow extending inward (recessed / sunken effect)
              Positioned.fill(
                child: CustomPaint(
                  painter: _NeumorphicInsetPainter(
                    isDark: theme.isDark,
                    borderRadius: 16,
                  ),
                ),
              ),

              // 2. Interactive text input & trailing content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          onTap: onTap,
                          readOnly: readOnly,
                          keyboardType: keyboardType,
                          cursorColor: theme.isDark
                              ? const Color(0xFF14B8A6)
                              : const Color(0xFF16114B),
                          cursorWidth: 2.0,
                          cursorRadius: const Radius.circular(1.0),
                          style: TextStyle(
                            fontFamilyFallback: const [
                              'Segoe UI',
                              'Roboto',
                              'Helvetica Neue',
                              'sans-serif',
                            ],
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: theme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: hintText,
                            hintStyle: TextStyle(
                              fontFamilyFallback: const [
                                'Segoe UI',
                                'Roboto',
                                'Helvetica Neue',
                                'sans-serif',
                              ],
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: theme.textHint,
                            ),
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Dual-stage inner recessed cavity painter for sunken neumorphic effect.
class _NeumorphicInsetPainter extends CustomPainter {
  final bool isDark;
  final double borderRadius;

  const _NeumorphicInsetPainter({
    required this.isDark,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    canvas.save();
    canvas.clipRRect(rrect);

    // Stage 1: Tight dark rim contact shadow (top & left)
    final tightColor = isDark ? const Color(0xD005080A) : const Color(0x3516114B);
    final tightPaint = Paint()
      ..color = tightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final tightPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(2.0, 2.2)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(tightPath, tightPaint);

    // Stage 2: Deep ambient cavity shadow (top & left)
    final ambientColor = isDark ? const Color(0x90000000) : const Color(0x2216114B);
    final ambientPaint = Paint()
      ..color = ambientColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

    final ambientPath = Path()
      ..addRect(rect.inflate(20))
      ..addRRect(rrect.shift(const Offset(4.0, 4.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(ambientPath, ambientPaint);

    // Stage 3: Specular inner floor highlight (bottom & right)
    final lightHighlightColor = isDark ? const Color(0x184E7A7E) : const Color(0xF0FFFFFF);
    final lightPaint = Paint()
      ..color = lightHighlightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final lightPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(-2.2, -2.2)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(lightPath, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeumorphicInsetPainter oldDelegate) =>
      isDark != oldDelegate.isDark || borderRadius != oldDelegate.borderRadius;
}
