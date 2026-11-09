import 'package:flutter/material.dart';

/// Semantic colors and design tokens for Lyrithm Day & Night neumorphism.
class LyrithmColors {
  // Day Mode (Light Neumorphic — Authoritative Reference)
  static const Color dayBackground = Color(0xFFEBECF2);
  static const Color dayBg = dayBackground;
  static const Color daySurface = Color(0xFFEFF1F6);
  static const Color daySurfaceElevated = Color(0xFFF3F5FA);
  static const Color daySurfaceInset = Color(0xFFE2E5EC);
  static const Color dayTextPrimary = Color(0xFF101426);
  static const Color dayTextNavy = dayTextPrimary;
  static const Color dayTextSecondary = Color(0xFF7E849A);
  static const Color dayTextHint = Color(0xFFA1A7BA);
  static const Color dayAccentBlue = Color(0xFF4F5DEC);
  static const Color dayGradientStart = dayAccentBlue;
  static const Color dayAccentBlueEnd = Color(0xFF3B48DE);
  static const Color dayDarkButton = Color(0xFF13172E);
  static const Color dayShadowLight = Color(0xFFFFFFFF);
  static const Color dayShadowDark = Color(0x28161D38);
  static const Color dayGlowBlue = Color(0x554F5DEC);
  static const Color dayCurveLine = Color(0xFFDCE0EA);
  static const Color dayCurveHighlight = Color(0x99FFFFFF);

  // Night Mode (Muted Dark Teal Neumorphic — Authoritative Inspiration)
  static const Color nightBackground = Color(0xFF162224);
  static const Color nightBg = nightBackground;
  static const Color nightSurface = Color(0xFF1B2A2D);
  static const Color nightSurfaceElevated = Color(0xFF203236);
  static const Color nightSurfaceInset = Color(0xFF121C1E);
  static const Color nightTextPrimary = Color(0xFFE3EFF1);
  static const Color nightTextSecondary = Color(0xFF7D9DA1);
  static const Color nightTextHint = Color(0xFF4F696D);
  static const Color nightAccentTeal = Color(0xFF14B8A6);
  static const Color nightAccentTealEnd = Color(0xFF0D9488);
  static const Color nightDarkButton = Color(0xFF0E1719);
  static const Color nightShadowLight = Color(0x1F477074);
  static const Color nightShadowDark = Color(0x800A0F11);
  static const Color nightGlowTeal = Color(0x4414B8A6);
  static const Color nightCurveLine = Color(0xFF22363A);
  static const Color nightCurveHighlight = Color(0x1F63969B);
}

/// Dynamic theme container providing typography, shadows, gradients and surfaces.
class LyrithmThemeData {
  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accentPrimary;
  final Color accentSecondary;
  final LinearGradient primaryGradient;
  final Color darkButton;
  final Color curveLine;
  final Color curveHighlight;

  const LyrithmThemeData({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.primaryGradient,
    required this.darkButton,
    required this.curveLine,
    required this.curveHighlight,
  });

  factory LyrithmThemeData.day() {
    return const LyrithmThemeData(
      isDark: false,
      background: LyrithmColors.dayBackground,
      surface: LyrithmColors.daySurface,
      surfaceElevated: LyrithmColors.daySurfaceElevated,
      surfaceInset: LyrithmColors.daySurfaceInset,
      textPrimary: LyrithmColors.dayTextPrimary,
      textSecondary: LyrithmColors.dayTextSecondary,
      textHint: LyrithmColors.dayTextHint,
      accentPrimary: LyrithmColors.dayAccentBlue,
      accentSecondary: LyrithmColors.dayAccentBlueEnd,
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [LyrithmColors.dayAccentBlue, LyrithmColors.dayAccentBlueEnd],
      ),
      darkButton: LyrithmColors.dayDarkButton,
      curveLine: LyrithmColors.dayCurveLine,
      curveHighlight: LyrithmColors.dayCurveHighlight,
    );
  }

  factory LyrithmThemeData.night() {
    return const LyrithmThemeData(
      isDark: true,
      background: LyrithmColors.nightBackground,
      surface: LyrithmColors.nightSurface,
      surfaceElevated: LyrithmColors.nightSurfaceElevated,
      surfaceInset: LyrithmColors.nightSurfaceInset,
      textPrimary: LyrithmColors.nightTextPrimary,
      textSecondary: LyrithmColors.nightTextSecondary,
      textHint: LyrithmColors.nightTextHint,
      accentPrimary: LyrithmColors.nightAccentTeal,
      accentSecondary: LyrithmColors.nightAccentTealEnd,
      primaryGradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [LyrithmColors.nightAccentTeal, LyrithmColors.nightAccentTealEnd],
      ),
      darkButton: LyrithmColors.nightDarkButton,
      curveLine: LyrithmColors.nightCurveLine,
      curveHighlight: LyrithmColors.nightCurveHighlight,
    );
  }

  /// Neumorphic raised double shadows (top-left highlight, bottom-right shadow).
  List<BoxShadow> raisedShadow({double depth = 1.0, double blur = 14.0}) {
    if (isDark) {
      return [
        BoxShadow(
          color: LyrithmColors.nightShadowLight,
          offset: Offset(-4 * depth, -4 * depth),
          blurRadius: blur * depth,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: LyrithmColors.nightShadowDark,
          offset: Offset(5 * depth, 6 * depth),
          blurRadius: blur * 1.2 * depth,
          spreadRadius: -1,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: LyrithmColors.dayShadowLight,
          offset: Offset(-5 * depth, -5 * depth),
          blurRadius: blur * depth,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: LyrithmColors.dayShadowDark,
          offset: Offset(6 * depth, 8 * depth),
          blurRadius: blur * 1.2 * depth,
          spreadRadius: -1,
        ),
      ];
    }
  }

  /// Subtle capsule / badge shadow.
  List<BoxShadow> badgeShadow() {
    return raisedShadow(depth: 0.6, blur: 8.0);
  }

  /// Glowing vibrant shadow for primary action buttons.
  List<BoxShadow> buttonGlowShadow() {
    final glowColor = isDark ? LyrithmColors.nightGlowTeal : LyrithmColors.dayGlowBlue;
    final ambientColor = isDark ? const Color(0x60000000) : const Color(0x30101426);
    return [
      BoxShadow(
        color: glowColor,
        offset: const Offset(0, 7),
        blurRadius: 18,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: ambientColor,
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -2,
      ),
    ];
  }

  /// Dark button shadow.
  List<BoxShadow> darkButtonShadow() {
    if (isDark) {
      return [
        const BoxShadow(
          color: Color(0x1F477074),
          offset: Offset(-2, -2),
          blurRadius: 8,
        ),
        const BoxShadow(
          color: Color(0x80000000),
          offset: Offset(0, 8),
          blurRadius: 18,
        ),
      ];
    } else {
      return [
        const BoxShadow(
          color: Color(0x33101426),
          offset: Offset(0, 8),
          blurRadius: 20,
        ),
        const BoxShadow(
          color: Color(0x40FFFFFF),
          offset: Offset(-2, -2),
          blurRadius: 6,
        ),
      ];
    }
  }

  Color get waveCurveLine => curveLine;
  Color get waveCurveHighlight => curveHighlight;

  // Typography Styles
  TextStyle get serifTitle => TextStyle(
        fontFamilyFallback: const ['Georgia', 'Cambria', 'Times New Roman', 'serif'],
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      );

  TextStyle get serifHeading => TextStyle(
        fontFamilyFallback: const ['Georgia', 'Cambria', 'Times New Roman', 'serif'],
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textPrimary,
      );

  TextStyle get tagline => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  TextStyle get bodySubtitle => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  TextStyle get fieldLabel => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  TextStyle get badgeText => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isDark ? textPrimary : const Color(0xFF282D42),
      );

  TextStyle get buttonText => const TextStyle(
        fontFamilyFallback: ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );
}

/// InheritedWidget or context extension for convenient theme resolution.
class LyrithmTheme extends InheritedWidget {
  final LyrithmThemeData data;

  const LyrithmTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static LyrithmThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<LyrithmTheme>();
    return theme?.data ?? LyrithmThemeData.day();
  }

  @override
  bool updateShouldNotify(LyrithmTheme oldWidget) => data.isDark != oldWidget.data.isDark;
}

/// Static typography provider matching Lyrithm design system.
class LyrithmTypography {
  static TextStyle titleLarge(LyrithmThemeData theme) => theme.serifTitle;
  static TextStyle titleMedium(LyrithmThemeData theme) => theme.serifHeading;
  static TextStyle subtitle(LyrithmThemeData theme) => theme.tagline;
  static TextStyle caption(LyrithmThemeData theme) => theme.bodySubtitle;
  static TextStyle label(LyrithmThemeData theme) => theme.fieldLabel;
  static TextStyle badge(LyrithmThemeData theme) => theme.badgeText;
  static TextStyle button(LyrithmThemeData theme) => theme.buttonText;
}
