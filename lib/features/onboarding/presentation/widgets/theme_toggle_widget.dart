import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-right Day / Night theme selector replacing the reference "Select ⌵" placeholder.
class ThemeToggleWidget extends ConsumerWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = LyrithmTheme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final isDark = settings.themeMode == ThemeMode.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
          ref.read(settingsControllerProvider.notifier).setThemeMode(newMode);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.badgeShadow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 15,
                color: isDark ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                isDark ? 'Night' : 'Day',
                style: TextStyle(
                  fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: theme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
