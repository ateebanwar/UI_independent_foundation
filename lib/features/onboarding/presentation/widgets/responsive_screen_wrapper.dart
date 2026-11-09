import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Responsive wrapper that presents Lyrithm screens with authentic mobile dimensions
/// on desktop/web (Microsoft Edge) while seamlessly adapting to native mobile viewports.
///
/// Prevents layout overflows via [SingleChildScrollView] + [LayoutBuilder].
class ResponsiveScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 520;
          final outerBg = isWideScreen
              ? (theme.isDark ? const Color(0xFF0F1719) : const Color(0xFFDFE1E8))
              : theme.background;

          final content = Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: theme.background,
              borderRadius: isWideScreen ? BorderRadius.circular(36) : BorderRadius.zero,
              boxShadow: isWideScreen
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: isWideScreen ? BorderRadius.circular(36) : BorderRadius.zero,
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
          );

          if (isWideScreen) {
            return Container(
              color: outerBg,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}
