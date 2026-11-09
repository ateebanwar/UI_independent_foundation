import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

enum LyrithmButtonStyle {
  primaryGradient, // Royal Blue gradient with glow (Setup to Continue)
  darkNavy,        // Deep Midnight Navy (Continue)
}

class LyrithmButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LyrithmButtonStyle style;
  final bool isLoading;
  final String? trailingIconText;

  const LyrithmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = LyrithmButtonStyle.primaryGradient,
    this.isLoading = false,
    this.trailingIconText,
  });

  @override
  State<LyrithmButton> createState() => _LyrithmButtonState();
}

class _LyrithmButtonState extends State<LyrithmButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final isPrimary = widget.style == LyrithmButtonStyle.primaryGradient;
    final enabled = widget.onPressed != null && !widget.isLoading;

    final decoration = isPrimary
        ? BoxDecoration(
            gradient: theme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: enabled ? theme.buttonGlowShadow() : null,
          )
        : BoxDecoration(
            color: theme.darkButton,
            borderRadius: BorderRadius.circular(30),
            boxShadow: enabled ? theme.darkButtonShadow() : null,
            border: theme.isDark
                ? Border.all(color: const Color(0x30477074), width: 1)
                : null,
          );

    return AnimatedScale(
      scale: _isPressed && enabled ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onHighlightChanged: (highlighted) {
            setState(() => _isPressed = highlighted);
          },
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white24,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 56,
            decoration: decoration,
            alignment: Alignment.center,
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: theme.buttonText,
                      ),
                      if (widget.trailingIconText != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          widget.trailingIconText!,
                          style: theme.buttonText.copyWith(fontSize: 18),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
