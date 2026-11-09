import 'package:flutter/material.dart';

/// Semantic colors and design tokens for Lyrithm Day & Night neumorphism.
/// Extracted and calibrated directly from the authoritative design reference.
class LyrithmColors {
  // Day Mode (Light Neumorphic — Authoritative Reference)
  static const Color dayCanvasBgStart = Color(0xFFF9F3EA); // Warm cream ambient light
  static const Color dayCanvasBgMid = Color(0xFFEDE5DE);   // Soft neutral transition
  static const Color dayCanvasBgEnd = Color(0xFFC5C5DF);   // Cool lavender shadow

  static const Color dayBgTop = Color(0xFFF7F4EE);        // Phone surface gradient top
  static const Color dayBgBottom = Color(0xFFE8E4EC);     // Phone surface gradient bottom
  static const Color dayBackground = Color(0xFFEBE8EE);   // Phone solid fallback
  static const Color dayBg = dayBackground;

  static const Color daySurface = Color(0xFFEDE9EF);      // Raised buttons/cards/pills
  static const Color daySurfaceElevated = Color(0xFFF4F0F6);
  static const Color daySurfaceInset = Color(0xFFE2DFE7); // Inset inputs and inner avatar

  static const Color dayTextPrimary = Color(0xFF18133E);  // Deep midnight navy
  static const Color dayTextNavy = dayTextPrimary;
  static const Color dayTextSecondary = Color(0xFF78768B);// Muted slate grey
  static const Color dayTextHint = Color(0xFF9A97A8);     // Input field placeholder
  static const Color dayTextBadge = Color(0xFF282645);    // Badge and pill text

  static const Color dayAccentBlue = Color(0xFF535AE8);   // Setup button gradient start
  static const Color dayGradientStart = dayAccentBlue;
  static const Color dayAccentBlueEnd = Color(0xFF3C42D3);// Setup button gradient end
  static const Color dayDarkButton = Color(0xFF171838);   // Continue button midnight navy

  static const Color dayShadowLight = Color(0xFFFFFFFF);
  static const Color dayShadowDark = Color(0x75B5B1C6);   // Soft neumorphic drop shadow
  static const Color dayGlowBlue = Color(0x66535AE8);     // Glowing vibrant button shadow
  static const Color dayCurveLine = Color(0xFFC7C3D3);    // Wave shadow contour
  static const Color dayCurveHighlight = Color(0xE6FFFFFF); // Wave highlight line

  // Night Mode (Muted Dark Teal Neumorphic)
  static const Color nightCanvasBgStart = Color(0xFF0F1719);
  static const Color nightCanvasBgEnd = Color(0xFF080D0E);

  static const Color nightBgTop = Color(0xFF192629);
  static const Color nightBgBottom = Color(0xFF131D1F);
  static const Color nightBackground = Color(0xFF162224);
  static const Color nightBg = nightBackground;

  static const Color nightSurface = Color(0xFF1B2A2D);
  static const Color nightSurfaceElevated = Color(0xFF223539);
  static const Color nightSurfaceInset = Color(0xFF111A1C);

  static const Color nightTextPrimary = Color(0xFFE3EFF1);
  static const Color nightTextSecondary = Color(0xFF7D9DA1);
  static const Color nightTextHint = Color(0xFF4F696D);
  static const Color nightTextBadge = Color(0xFFD0E6E9);

  static const Color nightAccentTeal = Color(0xFF14B8A6);
  static const Color nightAccentTealEnd = Color(0xFF0D9488);
  static const Color nightDarkButton = Color(0xFF0C1315);

  static const Color nightShadowLight = Color(0x1F477074);
  static const Color nightShadowDark = Color(0x800A0F11);
  static const Color nightGlowTeal = Color(0x5514B8A6);
  static const Color nightCurveLine = Color(0xFF22363A);
  static const Color nightCurveHighlight = Color(0x1F63969B);
}

/// Dynamic theme container providing typography, shadows, gradients and surfaces.
class LyrithmThemeData {
  final bool isDark;
  final Color background;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color canvasStart;
  final Color canvasEnd;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInset;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textBadge;
  final Color accentPrimary;
  final Color accentSecondary;
  final LinearGradient primaryGradient;
  final Color darkButton;
  final Color curveLine;
  final Color curveHighlight;

  const LyrithmThemeData({
    required this.isDark,
    required this.background,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.canvasStart,
    required this.canvasEnd,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInset,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textBadge,
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
      backgroundTop: LyrithmColors.dayBgTop,
      backgroundBottom: LyrithmColors.dayBgBottom,
      canvasStart: LyrithmColors.dayCanvasBgStart,
      canvasEnd: LyrithmColors.dayCanvasBgEnd,
      surface: LyrithmColors.daySurface,
      surfaceElevated: LyrithmColors.daySurfaceElevated,
      surfaceInset: LyrithmColors.daySurfaceInset,
      textPrimary: LyrithmColors.dayTextPrimary,
      textSecondary: LyrithmColors.dayTextSecondary,
      textHint: LyrithmColors.dayTextHint,
      textBadge: LyrithmColors.dayTextBadge,
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
      backgroundTop: LyrithmColors.nightBgTop,
      backgroundBottom: LyrithmColors.nightBgBottom,
      canvasStart: LyrithmColors.nightCanvasBgStart,
      canvasEnd: LyrithmColors.nightCanvasBgEnd,
      surface: LyrithmColors.nightSurface,
      surfaceElevated: LyrithmColors.nightSurfaceElevated,
      surfaceInset: LyrithmColors.nightSurfaceInset,
      textPrimary: LyrithmColors.nightTextPrimary,
      textSecondary: LyrithmColors.nightTextSecondary,
      textHint: LyrithmColors.nightTextHint,
      textBadge: LyrithmColors.nightTextBadge,
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

  /// Phone screen background gradient
  LinearGradient get screenBackgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backgroundTop, backgroundBottom],
      );

  /// Ambient studio backdrop gradient (for wide browser viewports)
  LinearGradient get canvasGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [LyrithmColors.nightCanvasBgStart, LyrithmColors.nightCanvasBgEnd]
            : [
                LyrithmColors.dayCanvasBgStart,
                LyrithmColors.dayCanvasBgMid,
                LyrithmColors.dayCanvasBgEnd,
              ],
        stops: isDark ? const [0.0, 1.0] : const [0.0, 0.45, 1.0],
      );

  /// Neumorphic raised double shadows (top-left highlight, bottom-right shadow).
  List<BoxShadow> raisedShadow({double depth = 1.0, double blur = 14.0}) {
    if (isDark) {
      return [
        BoxShadow(
          color: LyrithmColors.nightShadowLight,
          offset: Offset(-3.5 * depth, -3.5 * depth),
          blurRadius: blur * depth,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: LyrithmColors.nightShadowDark,
          offset: Offset(4.5 * depth, 5.5 * depth),
          blurRadius: blur * 1.2 * depth,
          spreadRadius: -1,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: LyrithmColors.dayShadowLight,
          offset: Offset(-4 * depth, -4 * depth),
          blurRadius: blur * 0.9 * depth,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: LyrithmColors.dayShadowDark,
          offset: Offset(5 * depth, 6.5 * depth),
          blurRadius: blur * 1.15 * depth,
          spreadRadius: 0,
        ),
      ];
    }
  }

  /// Subtle capsule / badge shadow.
  List<BoxShadow> badgeShadow() {
    return raisedShadow(depth: 0.65, blur: 8.0);
  }

  /// Glowing vibrant shadow for primary action buttons (Setup to Continue).
  List<BoxShadow> buttonGlowShadow() {
    final glowColor = isDark ? LyrithmColors.nightGlowTeal : LyrithmColors.dayGlowBlue;
    final ambientColor = isDark ? const Color(0x60000000) : const Color(0x28101438);
    return [
      BoxShadow(
        color: glowColor,
        offset: const Offset(0, 7),
        blurRadius: 18,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: ambientColor,
        offset: const Offset(0, 12),
        blurRadius: 24,
        spreadRadius: -2,
      ),
    ];
  }

  /// Dark button shadow (Continue).
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
          color: Color(0x45101438),
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
        fontFamilyFallback: const ['Georgia', 'Playfair Display', 'Cambria', 'Times New Roman', 'serif'],
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textPrimary,
      );

  TextStyle get serifHeading => TextStyle(
        fontFamilyFallback: const ['Georgia', 'Playfair Display', 'Cambria', 'Times New Roman', 'serif'],
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      );

  TextStyle get tagline => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  TextStyle get bodySubtitle => TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: 13,
        height: 1.35,
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
        color: isDark ? textPrimary : textBadge,
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
