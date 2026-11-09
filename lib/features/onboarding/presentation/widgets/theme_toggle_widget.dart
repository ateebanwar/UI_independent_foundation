import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-right "Select ⌵" neumorphic pill button matching the authoritative reference design.
///
/// Tapping toggles between Day and Night neumorphic themes.
class ThemeToggleWidget extends ConsumerWidget {
  final bool showChevron;

  const ThemeToggleWidget({
    super.key,
    this.showChevron = true,
  });

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: theme.badgeShadow(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select',
                style: TextStyle(
                  fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: theme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
