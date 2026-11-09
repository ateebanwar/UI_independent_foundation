import 'dart:math' as math;
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
/// Pixel-accurate reproduction of the authoritative design reference (right phone mockup):
/// - Clean composition without clutter.
/// - Centered 3D iridescent squircle logo.
/// - Elegant serif "Lyrithm" typography & slate tagline.
/// - Side-by-side raised pills: "100% Offline" & "Zero Cloud Tracking".
/// - Screen-wide embossed organic S-curve wave contour.
/// - Glowing royal blue "Setup to Continue →" CTA.
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
          final isCompact = h < 640;

          final logoSize = (w * 0.44).clamp(118.0, 150.0);
          final topPadding = isCompact ? 16.0 : math.max(20.0, h * 0.08);
          final logoBottomGap = isCompact ? 14.0 : math.max(14.0, h * 0.035);
          final titleBottomGap = isCompact ? 6.0 : math.max(6.0, h * 0.012);
          final tagBottomGap = isCompact ? 16.0 : math.max(16.0, h * 0.038);
          final bottomPadding = isCompact ? 16.0 : math.max(18.0, h * 0.045);

          Widget content = Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: topPadding),

              // 1. Centered 3D Squircle Logo
              Hero(
                tag: 'lyrithm_logo',
                child: LyrithmLogoWidget(size: logoSize),
              ),

              SizedBox(height: logoBottomGap),

              // 2. App Title: "Lyrithm" (Deep navy bold serif)
              Text(
                'Lyrithm',
                textAlign: TextAlign.center,
                style: LyrithmTypography.titleLarge(theme),
              ),

              SizedBox(height: titleBottomGap),

              // 3. Tagline: "Let your music bloom."
              Text(
                'Let your music bloom.',
                textAlign: TextAlign.center,
                style: LyrithmTypography.subtitle(theme),
              ),

              SizedBox(height: tagBottomGap),

              // 4. Feature Badges: "100% Offline" & "Zero Cloud Tracking"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      NeumorphicPillBadge(label: '100% Offline'),
                      SizedBox(width: 12),
                      NeumorphicPillBadge(label: 'Zero Cloud Tracking'),
                    ],
                  ),
                ),
              ),

              if (!isCompact) const Spacer(),

              if (isCompact) const SizedBox(height: 20),

              // 5. Embossed S-Curve Wave flowing across the bottom
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CustomPaint(
                  painter: WaveCurvePainter(
                    style: WaveStyle.splashBottom,
                    isDark: theme.isDark,
                    curveLine: theme.waveCurveLine,
                    curveHighlight: theme.waveCurveHighlight,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 6. Primary Action: "Setup to Continue →"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LyrithmButton(
                  label: 'Setup to Continue',
                  trailingIconText: '→',
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

          if (isCompact) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}
