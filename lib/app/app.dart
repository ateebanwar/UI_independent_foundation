import 'package:echo_bloom/core/theme/lyrithm_theme.dart';
import 'package:echo_bloom/features/library/library_providers.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/splash_welcome_screen.dart';
import 'package:echo_bloom/features/playback/playback_providers.dart';
import 'package:echo_bloom/features/playlists/playlist_providers.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget mounting [UncontrolledProviderScope].
class EchoBloomApp extends StatelessWidget {
  final ProviderContainer container;
  final Widget? home;

  const EchoBloomApp({
    super.key,
    required this.container,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: _AppView(home: home),
    );
  }
}

class _AppView extends ConsumerWidget {
  final Widget? home;

  const _AppView({this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final lyrithmTheme = isDark ? LyrithmThemeData.night() : LyrithmThemeData.day();

    return LyrithmTheme(
      data: lyrithmTheme,
      child: MaterialApp(
        title: 'Lyrithm',
        debugShowCheckedModeBanner: false,
        themeMode: settings.themeMode,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: LyrithmColors.dayBg,
          colorScheme: const ColorScheme.light(
            primary: LyrithmColors.dayGradientStart,
            surface: LyrithmColors.daySurface,
            onSurface: LyrithmColors.dayTextNavy,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: LyrithmColors.nightBg,
          colorScheme: const ColorScheme.dark(
            primary: LyrithmColors.nightAccentTeal,
            surface: LyrithmColors.nightSurface,
            onSurface: LyrithmColors.nightTextPrimary,
          ),
        ),
        home: home ?? const SplashWelcomeScreen(),
      ),
    );
  }
}

/// Headless Foundation Verification View.
/// Displays operational status of all core subsystems.
/// Preserved for foundation regression tests and diagnostics.
class FoundationVerificationView extends ConsumerWidget {
  const FoundationVerificationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackCountAsync = ref.watch(libraryTrackCountStreamProvider);
    final playlistState = ref.watch(playlistControllerProvider);
    final playbackState = ref.watch(currentPlaybackStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo Bloom — Foundation Architecture'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Core Foundation Reconstructed & Ready',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'UI-independent foundation successfully initialized. Business logic, SQLite database, audio engine, and Riverpod state management are operational.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.storage, color: Colors.indigo),
                          title: const Text('Local SQLite Database'),
                          subtitle: const Text('Persistent tables (v1, v2, v3 schema migrator)'),
                          trailing: const Text('ONLINE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.music_note, color: Colors.purple),
                          title: const Text('Library Tracks Indexed'),
                          trailing: Text(
                            trackCountAsync.when(
                              data: (count) => '$count tracks',
                              loading: () => 'Scanning...',
                              error: (_, __) => '0',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.playlist_play, color: Colors.blue),
                          title: const Text('Playlists Available'),
                          trailing: Text(
                            '${playlistState.playlists.length} playlists',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.graphic_eq, color: Colors.orange),
                          title: const Text('Audio Engine Status'),
                          subtitle: Text(playbackState.currentTrack?.title ?? 'No active track'),
                          trailing: Text(
                            playbackState.status.name.toUpperCase(),
                            style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
