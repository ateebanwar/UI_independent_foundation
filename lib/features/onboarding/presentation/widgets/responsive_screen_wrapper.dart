import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Responsive device frame wrapper for Project Lyrithm.
///
/// On desktop and wide browser viewports (Microsoft Edge), it presents the screen
/// inside a high-fidelity smartphone mockup floating on the warm ambient studio backdrop.
///
/// On mobile viewports (or Edge DevTools mobile emulation <= 480px), it seamlessly fills
/// the display natively while preserving strict proportional neumorphic layouts.
class ResponsiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 500;

          if (isWideScreen) {
            // Calculate phone dimensions that fit comfortably in browser window
            final availableHeight = constraints.maxHeight;
            final targetHeight = (availableHeight - 48).clamp(660.0, 844.0);
            final targetWidth = (targetHeight * 0.485).clamp(340.0, 410.0);

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: theme.canvasGradient,
              ),
              alignment: Alignment.center,
              child: Container(
                width: targetWidth,
                height: targetHeight,
                decoration: BoxDecoration(
                  gradient: theme.screenBackgroundGradient,
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    // High-fidelity studio lighting drop shadows matching screenshot
                    BoxShadow(
                      color: Colors.white.withValues(alpha: theme.isDark ? 0.05 : 0.8),
                      offset: const Offset(-8, -8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: theme.isDark
                          ? const Color(0x99000000)
                          : const Color(0x3818133E),
                      offset: const Offset(12, 18),
                      blurRadius: 40,
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: theme.isDark
                          ? const Color(0x60000000)
                          : const Color(0x1818133E),
                      offset: const Offset(4, 6),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(42),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: theme.screenBackgroundGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: padding,
                        child: scrollable
                            ? SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: child,
                              )
                            : child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Mobile Viewport (native edge-to-edge)
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              gradient: theme.screenBackgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: padding,
                child: scrollable
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: child,
                      )
                    : child,
              ),
            ),
          );
        },
      ),
    );
  }
}
