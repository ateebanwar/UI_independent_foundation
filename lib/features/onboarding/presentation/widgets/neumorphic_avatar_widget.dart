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
    this.size = 148,
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
              width: size * 0.78,
              height: size * 0.78,
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
        fontSize: size * 0.38,
        fontWeight: FontWeight.w700,
        color: theme.isDark ? const Color(0xFFB5C9CC) : const Color(0xFF686480),
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
            // Outer raised neumorphic circle with very prominent outer shadow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: theme.surface,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.isDark
                      ? [const Color(0xFF233539), const Color(0xFF1E2E32), const Color(0xFF192629)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFFAF7FD), const Color(0xFFEDE8F5)],
                  stops: const [0.0, 0.45, 1.0],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.isDark ? const Color(0x30FFFFFF) : Colors.white.withValues(alpha: 0.95),
                  width: 1.8,
                ),
                boxShadow: [
                  // Top-left crisp specular highlight
                  BoxShadow(
                    color: theme.isDark ? const Color(0x25FFFFFF) : const Color(0xFFFFFFFF),
                    offset: const Offset(-5, -5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  // Bottom-right prominent deep directional shadow
                  BoxShadow(
                    color: theme.isDark ? const Color(0x99000000) : const Color(0x3816114B),
                    offset: const Offset(7, 14),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                  // Secondary ambient contact shadow
                  BoxShadow(
                    color: theme.isDark ? const Color(0x55000000) : const Color(0x1816114B),
                    offset: const Offset(2, 5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  // Wide ground floor shadow
                  BoxShadow(
                    color: theme.isDark ? const Color(0x40000000) : const Color(0x1216114B),
                    offset: const Offset(0, 18),
                    blurRadius: 26,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Center(
                // Inner sunken well with distinct inner recessed shadows (thinner outer band, larger circle)
                child: CustomPaint(
                  foregroundPainter: _CircleInnerShadowPainter(isDark: theme.isDark),
                  child: Container(
                    width: size * 0.88,
                    height: size * 0.88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: theme.isDark
                            ? [const Color(0xFF0F1719), const Color(0xFF162224)]
                            : [const Color(0xFFDCD6E4), const Color(0xFFEAE5F1)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.isDark ? const Color(0x15FFFFFF) : const Color(0x30FFFFFF),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: _buildAvatarContent(theme),
                    ),
                  ),
                ),
              ),
            ),

            // Camera button at bottom-right (~4:30 o'clock): Midnight navy badge with white border and white camera icon
            Positioned(
              right: 2,
              bottom: 4,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => _pickImage(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.darkButton,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          offset: const Offset(0, -1),
                          blurRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 2.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                fontSize: 14,
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

/// Circular inner shadow painter creating an authentic recessed / sunken well for the avatar.
class _CircleInnerShadowPainter extends CustomPainter {
  final bool isDark;

  const _CircleInnerShadowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()..addOval(rect);

    canvas.save();
    canvas.clipPath(path);

    // Dark inner shadow at top-left
    final darkShadowColor = isDark ? const Color(0xC0080D0E) : const Color(0x4516114B);
    final darkPaint = Paint()
      ..color = darkShadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final darkPath = Path()
      ..addRect(rect.inflate(15))
      ..addOval(rect.shift(const Offset(3.0, 3.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(darkPath, darkPaint);

    // Light inner highlight at bottom-right
    final lightHighlightColor = isDark ? const Color(0x204E7A7E) : const Color(0xF5FFFFFF);
    final lightPaint = Paint()
      ..color = lightHighlightColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final lightPath = Path()
      ..addRect(rect.inflate(15))
      ..addOval(rect.shift(const Offset(-2.5, -2.5)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(lightPath, lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CircleInnerShadowPainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}
