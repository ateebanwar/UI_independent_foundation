import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Fully responsive edge-to-edge screen wrapper for Project Lyrithm:
/// - Covers 100% of the screen/viewport with zero edge curves (0px border radius).
/// - Fills the entire display with the authentic tactile paper theme gradient.
/// - Complete responsiveness across all device form factors (mobile, tablet, desktop, Microsoft Edge).
/// - Centers content gracefully on wide viewports (maxWidth: 500) while background expands edge-to-edge.
/// - Built-in SafeArea and smooth scrolling for compact viewports to guarantee zero overflow.
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
      backgroundColor: theme.backgroundTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: theme.screenBackgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              const maxContentWidth = 500.0;
              final isWide = screenWidth > maxContentWidth;

              Widget content = Padding(
                padding: padding,
                child: scrollable
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: child,
                      )
                    : child,
              );

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxContentWidth),
                    child: content,
                  ),
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }
}
