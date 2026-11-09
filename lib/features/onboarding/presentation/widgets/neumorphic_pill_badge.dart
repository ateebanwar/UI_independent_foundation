import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Raised neumorphic pill badge used for "100% Offline" and "Zero Cloud Tracking".
class NeumorphicPillBadge extends StatelessWidget {
  final String label;

  const NeumorphicPillBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: theme.badgeShadow(),
      ),
      child: Text(
        label,
        style: theme.badgeText,
      ),
    );
  }
}
