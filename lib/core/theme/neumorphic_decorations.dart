import 'package:echo_bloom/core/theme/app_colors.dart';
import 'package:echo_bloom/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Predefined neumorphic box decorations with full Light and Dark Neumorphism support.
abstract final class NeumorphicDecorations {
  /// Elevated rounded card
  static BoxDecoration elevatedCard({
    BorderRadius? borderRadius,
    Color? color,
    bool isDark = false,
  }) {
    final surfaceColor = color ?? (isDark ? AppColors.darkSurface : AppColors.surface);
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: borderRadius ?? AppSpacing.roundedControlPanel,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: const Offset(-6, -6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
          offset: const Offset(7, 11),
          blurRadius: 22,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Elevated circular button
  static BoxDecoration circularButton({
    Color? color,
    double elevation = 1.0,
    bool isDark = false,
  }) {
    final surfaceColor = color ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.surface);
    return BoxDecoration(
      color: surfaceColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: Offset(-3.5 * elevation, -3.5 * elevation),
          blurRadius: 8 * elevation,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
          offset: Offset(4.5 * elevation, 6.5 * elevation),
          blurRadius: 12 * elevation,
          spreadRadius: -1,
        ),
      ],
    );
  }
}

