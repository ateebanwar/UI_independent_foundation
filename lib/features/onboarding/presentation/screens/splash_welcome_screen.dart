import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/create_profile_screen.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_button.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_logo_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/neumorphic_pill_badge.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/responsive_screen_wrapper.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/wave_curve_painter.dart';
import 'package:flutter/material.dart';

/// Screen 1 — Splash / Welcome Screen for Project Lyrithm.
///
/// Pixel-accurate reproduction of the authoritative design reference (Image 1):
/// - Soft cream/off-white rounded surface with ~8 px outer ambient inset.
/// - Prominent 184 × 185 px squircle 3D iridescent music note logo.
/// - 56 px Georgia serif bold "Lyrithm" display title.
/// - 21 px slate grey "Let your music bloom." tagline.
/// - Raised neumorphic badges: "100% Offline" (116×35) & "Zero Cloud Tracking" (174×35).
/// - Elegant screen-wide embossed decorative S-curve wave boundary.
/// - 323 × 58 px royal blue/violet gradient "Setup to Continue →" CTA with controlled glow.
class SplashWelcomeScreen extends StatelessWidget {
  const SplashWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return ResponsiveScreenWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final isCompact = h < 700;

          // Proportions calibrated directly against reference Image 1 (405 × 811)
          final logoSize = (w * 0.475).clamp(140.0, 185.0);
          final topPadding = isCompact ? 16.0 : (h * 0.203).clamp(40.0, 161.0);
          final logoBottomGap = isCompact ? 14.0 : (h * 0.043).clamp(14.0, 34.0);
          final titleBottomGap = isCompact ? 4.0 : (h * 0.011).clamp(4.0, 9.0);
          final tagBottomGap = isCompact ? 16.0 : (h * 0.055).clamp(16.0, 44.0);
          final bottomPadding = isCompact ? 16.0 : (h * 0.045).clamp(16.0, 36.0);
          final buttonWidth = (w - 48).clamp(280.0, 323.0);

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: topPadding),

              // 1. Centered 3D Squircle Logo (185 × 185 px at baseline)
              Hero(
                tag: 'lyrithm_logo',
                child: LyrithmLogoWidget(size: logoSize),
              ),

              SizedBox(height: logoBottomGap),

              // 2. App Title: "Lyrithm" (Large serif display typography, 56 px)
              Text(
                'Lyrithm',
                textAlign: TextAlign.center,
                style: LyrithmTypography.titleLarge(theme),
              ),

              SizedBox(height: titleBottomGap),

              // 3. Tagline: "Let your music bloom." (21 px regular)
              Text(
                'Let your music bloom.',
                textAlign: TextAlign.center,
                style: LyrithmTypography.subtitle(theme),
              ),

              SizedBox(height: tagBottomGap),

              // 4. Feature Badges: "100% Offline" (116x35) & "Zero Cloud Tracking" (174x35)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      NeumorphicPillBadge(
                        label: '100% Offline',
                        width: 116,
                        height: 35,
                      ),
                      SizedBox(width: 12),
                      NeumorphicPillBadge(
                        label: 'Zero Cloud Tracking',
                        width: 174,
                        height: 35,
                      ),
                    ],
                  ),
                ),
              ),

              if (!isCompact) const Spacer(),

              if (isCompact) const SizedBox(height: 24),

              // 5. Primary Action: "Setup to Continue →" (323 × 58 px)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LyrithmButton(
                  label: 'Setup to Continue',
                  trailingIconText: '→',
                  width: buttonWidth,
                  height: 58,
                  style: LyrithmButtonStyle.primaryGradient,
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        pageBuilder: (context, anim, secAnim) =>
                            const CreateProfileScreen(),
                        transitionsBuilder:
                            (context, anim, secAnim, child) {
                          return FadeTransition(
                            opacity: CurvedAnimation(
                                parent: anim, curve: Curves.easeInOut),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: anim, curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 260),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: bottomPadding),
            ],
          );

          return Stack(
            children: [
              // Screen-wide embossed decorative wave flowing across the lower section
              Positioned.fill(
                child: CustomPaint(
                  painter: WaveCurvePainter(
                    style: WaveStyle.splashBottom,
                    isDark: theme.isDark,
                    curveLine: theme.waveCurveLine,
                    curveHighlight: theme.waveCurveHighlight,
                  ),
                ),
              ),
              // Content layer
              isCompact
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: content,
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: content,
                    ),
            ],
          );
        },
      ),
    );
  }
}
