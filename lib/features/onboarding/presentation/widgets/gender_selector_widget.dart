import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';

/// Segmented neumorphic pills for selecting Male / Female / Other matching the reference.
class GenderSelectorWidget extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const GenderSelectorWidget({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);
    final options = ['Male', 'Female', 'Other'];

    return Row(
      children: options.map((gender) {
        final isSelected = selectedGender.toLowerCase() == gender.toLowerCase();

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: gender == 'Male' ? 0 : 5,
              right: gender == 'Other' ? 0 : 5,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onGenderChanged(gender),
                borderRadius: BorderRadius.circular(23),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 46,
                  alignment: Alignment.center,
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: theme.primaryGradient,
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: [
                            BoxShadow(
                              color: theme.isDark
                                  ? LyrithmColors.nightGlowTeal
                                  : LyrithmColors.dayGlowBlue,
                              offset: const Offset(0, 4),
                              blurRadius: 14,
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: theme.badgeShadow(),
                        ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (theme.isDark ? theme.textPrimary : theme.textBadge),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
