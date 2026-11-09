import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Pixel-accurate sunken / inset neumorphic text input field matching the reference design.
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
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _NeumorphicInsetPainter(
            isDark: theme.isDark,
            borderRadius: 16,
          ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: theme.surfaceInset,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
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
                    style: TextStyle(
                      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
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
                        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
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

    // Dark inner shadow at top-left
    final darkShadowColor = isDark ? const Color(0xB0080D0E) : const Color(0x3318133E);
    final darkPaint = Paint()
      ..color = darkShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final darkPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(3.0, 3.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(darkPath, darkPaint);

    // Light inner highlight at bottom-right
    final lightHighlightColor = isDark ? const Color(0x184E7A7E) : const Color(0xE6FFFFFF);
    final lightPaint = Paint()
      ..color = lightHighlightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final lightPath = Path()
      ..addRect(rect.inflate(15))
      ..addRRect(rrect.shift(const Offset(-2.5, -2.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(lightPath, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeumorphicInsetPainter oldDelegate) =>
      isDark != oldDelegate.isDark || borderRadius != oldDelegate.borderRadius;
}
