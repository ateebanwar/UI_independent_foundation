import 'dart:convert';
import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Circular neumorphic avatar with raised bezel, sunken inner well, default initial,
/// midnight camera badge, and "Choose Profile Photo" link matching the reference design.
class NeumorphicAvatarWidget extends StatelessWidget {
  final String? avatarKey;
  final String initial;
  final ValueChanged<String>? onAvatarPicked;
  final double size;

  const NeumorphicAvatarWidget({
    super.key,
    this.avatarKey,
    this.initial = 'U',
    this.onAvatarPicked,
    this.size = 104,
  });

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        onAvatarPicked?.call(base64String);
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Widget _buildAvatarContent(LyrithmThemeData theme) {
    if (avatarKey != null && avatarKey!.isNotEmpty) {
      if (avatarKey!.startsWith('data:image')) {
        try {
          final base64Data = avatarKey!.split(',').last;
          final bytes = base64Decode(base64Data);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size * 0.80,
              height: size * 0.80,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {}
      }
    }

    // Default letter initial "U"
    return Text(
      initial.isNotEmpty ? initial[0].toUpperCase() : 'U',
      style: TextStyle(
        fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
        fontSize: size * 0.35,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8C899E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LyrithmTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer raised neumorphic circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: theme.surface,
                shape: BoxShape.circle,
                boxShadow: theme.raisedShadow(depth: 1.15, blur: 16),
              ),
              child: Center(
                // Inner sunken well
                child: Container(
                  width: size * 0.80,
                  height: size * 0.80,
                  decoration: BoxDecoration(
                    color: theme.surfaceInset,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.isDark ? const Color(0x60000000) : const Color(0x2818133E),
                        offset: const Offset(2, 2.5),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: theme.isDark ? const Color(0x144E7A7E) : const Color(0xCCFFFFFF),
                        offset: const Offset(-2, -2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildAvatarContent(theme),
                  ),
                ),
              ),
            ),

            // Camera button at bottom-right (~4 o'clock)
            Positioned(
              right: 0,
              bottom: 2,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => _pickImage(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.darkButton,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                      border: Border.all(
                        color: theme.surface,
                        width: 2.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // "Choose Profile Photo" link
        InkWell(
          onTap: () => _pickImage(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Helvetica Neue', 'sans-serif'],
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: theme.isDark ? theme.accentPrimary : const Color(0xFF2B2D5B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
