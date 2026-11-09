import 'dart:math' as math;
import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/gender_selector_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_button.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/neumorphic_avatar_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/neumorphic_input_field.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/responsive_screen_wrapper.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/theme_toggle_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/wave_curve_painter.dart';
import 'package:echo_bloom/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 2 — Create Profile Screen for Project Lyrithm.
///
/// Pixel-accurate reproduction of the authoritative design reference (left phone mockup):
/// - Top bar with Back button and "Select ⌵" pill.
/// - Bold serif "Create Profile" heading & offline subtitle.
/// - Sweeping embossed wave curve embracing circular avatar.
/// - Sunken inset inputs with dynamic "Age: XX" raised pill.
/// - Segmented gender selector with active royal blue glow.
/// - Midnight navy "Continue" button validating and persisting profile locally.
class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  DateTime _dateOfBirth = DateTime(2006, 1, 1);
  String _selectedGender = 'Male';
  String? _avatarKey;
  String? _nameError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController(text: '1/1/2006');

    // Populate with existing profile if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingProfile = ref.read(profileControllerProvider).profile;
      if (existingProfile != null && mounted) {
        setState(() {
          _nameController.text = existingProfile.name;
          _dateOfBirth = existingProfile.dateOfBirth;
          _dobController.text =
              '${existingProfile.dateOfBirth.month}/${existingProfile.dateOfBirth.day}/${existingProfile.dateOfBirth.year}';
          _selectedGender = existingProfile.gender;
          _avatarKey = existingProfile.avatarKey;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  int get _calculatedAge {
    final now = DateTime.now();
    int age = now.year - _dateOfBirth.year;
    if (now.month < _dateOfBirth.month ||
        (now.month == _dateOfBirth.month && now.day < _dateOfBirth.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = LyrithmTheme.of(context);
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
            colorScheme: theme.isDark
                ? const ColorScheme.dark(
                    primary: LyrithmColors.nightAccentTeal,
                    surface: LyrithmColors.nightSurface,
                    onSurface: LyrithmColors.nightTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: LyrithmColors.dayGradientStart,
                    surface: LyrithmColors.daySurface,
                    onSurface: LyrithmColors.dayTextNavy,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _nameError = null;
      _isSubmitting = true;
    });

    final success = await ref.read(profileControllerProvider.notifier).saveProfile(
          name: name,
          dateOfBirth: _dateOfBirth,
          gender: _selectedGender,
          avatarKey: _avatarKey,
        );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Profile saved locally. Welcome to Lyrithm!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final error = ref.read(profileControllerProvider).errorMessage ?? 'Failed to save profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return ResponsiveScreenWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final isCompact = h < 720;
          final verticalGap = isCompact ? 10.0 : math.max(10.0, h * 0.016);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. Top Bar: Back Button & "Select ⌵"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 26,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const ThemeToggleWidget(),
                      ],
                    ),
                  ),

                  SizedBox(height: isCompact ? 8 : 12),

                  // 2. Heading: "Create Profile"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Create Profile',
                      style: LyrithmTypography.titleMedium(theme),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Stored 100% locally on your device. Never shared or uploaded.',
                      style: LyrithmTypography.caption(theme),
                    ),
                  ),

                  SizedBox(height: isCompact ? 8 : 14),

                  // 4. Sweeping Wave Curve embracing Avatar (Screen-wide full bleed)
                  SizedBox(
                    width: double.infinity,
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WaveCurvePainter(
                              style: WaveStyle.profileAvatar,
                              isDark: theme.isDark,
                              curveLine: theme.waveCurveLine,
                              curveHighlight: theme.waveCurveHighlight,
                            ),
                          ),
                        ),
                        NeumorphicAvatarWidget(
                          avatarKey: _avatarKey,
                          initial: _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()[0].toUpperCase()
                              : 'U',
                          onAvatarPicked: (avatar) {
                            setState(() => _avatarKey = avatar);
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: verticalGap),

                  // 5. Full Name Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: LyrithmTypography.label(theme),
                        ),
                        const SizedBox(height: 8),
                        NeumorphicInputField(
                          controller: _nameController,
                          hintText: 'Enter your name',
                          errorText: _nameError,
                          onChanged: (val) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            } else {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: verticalGap),

                  // 6. Date of Birth Section with "Age: 20" raised pill
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: LyrithmTypography.label(theme),
                        ),
                        const SizedBox(height: 8),
                        NeumorphicInputField(
                          controller: _dobController,
                          hintText: 'Select date of birth',
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: theme.badgeShadow(),
                            ),
                            child: Text(
                              'Age: $_calculatedAge',
                              style: const TextStyle(
                                fontFamilyFallback: [
                                  'Segoe UI',
                                  'Roboto',
                                  'Helvetica Neue',
                                  'sans-serif'
                                ],
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6E6C82),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: verticalGap),

                  // 7. Gender Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: LyrithmTypography.label(theme),
                        ),
                        const SizedBox(height: 8),
                        GenderSelectorWidget(
                          selectedGender: _selectedGender,
                          onGenderChanged: (gender) {
                            setState(() => _selectedGender = gender);
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isCompact ? 22 : 28),

                  // 8. Midnight Navy Continue Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LyrithmButton(
                      label: 'Continue',
                      style: LyrithmButtonStyle.darkNavy,
                      isLoading: _isSubmitting,
                      onPressed: _handleContinue,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
