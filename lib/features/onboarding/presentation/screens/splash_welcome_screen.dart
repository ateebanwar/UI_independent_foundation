import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/create_profile_screen.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_button.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_logo_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/neumorphic_pill_badge.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/responsive_screen_wrapper.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/theme_toggle_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/wave_curve_painter.dart';
import 'package:flutter/material.dart';

/// Screen 1 — Splash / Welcome Screen for Project Lyrithm.
///
/// Faithfully reproduces the visual composition, proportions, and neumorphic
/// depth from the authoritative design reference.
class SplashWelcomeScreen extends StatelessWidget {
  const SplashWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return ResponsiveScreenWrapper(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top bar with subtle theme switcher
          const Align(
            alignment: Alignment.topRight,
            child: ThemeToggleWidget(),
          ),

          const SizedBox(height: 24),

          // 1. Centered 3D Squircle Logo with iridescent note & ribbon wings
          const Hero(
            tag: 'lyrithm_logo',
            child: LyrithmLogoWidget(size: 144),
          ),

          const SizedBox(height: 28),

          // 2. App Title: "Lyrithm" (Deep navy bold serif)
          Text(
            'Lyrithm',
            textAlign: TextAlign.center,
            style: LyrithmTypography.titleLarge(theme),
          ),

          const SizedBox(height: 10),

          // 3. Tagline: "Let your music bloom."
          Text(
            'Let your music bloom.',
            textAlign: TextAlign.center,
            style: LyrithmTypography.subtitle(theme),
          ),

          const SizedBox(height: 32),

          // 4. Feature Badges: "100% Offline" & "Zero Cloud Tracking"
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              NeumorphicPillBadge(label: '100% Offline'),
              NeumorphicPillBadge(label: 'Zero Cloud Tracking'),
            ],
          ),

          const SizedBox(height: 36),

          // 5. Embossed S-Curve Wave flowing across the bottom
          SizedBox(
            width: double.infinity,
            height: 56,
            child: CustomPaint(
              painter: WaveCurvePainter(
                style: WaveStyle.splashBottom,
                isDark: theme.isDark,
                curveLine: theme.waveCurveLine,
                curveHighlight: theme.waveCurveHighlight,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 6. Primary Action: "Setup to Continue →"
          LyrithmButton(
            label: 'Setup to Continue',
            trailingIconText: '→',
            style: LyrithmButtonStyle.primaryGradient,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const CreateProfileScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
