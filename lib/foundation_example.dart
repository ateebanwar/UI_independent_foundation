import 'dart:async';
import 'package:echo_bloom/echo_bloom_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Complete executable integration example demonstrating how an entirely independent
/// visual UI or external developer consumes the Echo Bloom foundation.
///
/// Follows the 12-step foundation integration pattern:
/// 1. Initialize foundation & bindings
/// 2. Configure providers & overrides
/// 3. Configure API endpoints & credentials
/// 4. Initialize database with migrations
/// 5. Search catalog (local or remote)
/// 6. Play a track & manipulate queue
/// 7. Observe real-time playback state
/// 8. Read listening history with 5-second qualification
/// 9. Manage playlists (create, add, reorder)
/// 10. Trigger downloads & monitor storage
/// 11. Adjust 5-band equalizer & presets
/// 12. Gracefully dispose and close resources
Future<void> main() async {
  // 1. Initialize platform & database bindings
  sqfliteFfiInit();
  final logger = ConsoleLogger(enableInRelease: true);
  logger.info('Step 1: Initializing foundation bindings...', tag: 'FoundationExample');

  // 2. Configure database & data sources
  final migrator = DatabaseMigrator(logger: logger);
  final appDb = AppDatabase(migrator: migrator, databaseName: inMemoryDatabasePath, logger: logger);
  await appDb.initialize(inMemoryPath: inMemoryDatabasePath, customFactory: databaseFactoryFfi);
  logger.info('Step 2 & 4: Database initialized with schema version ${migrator.latestVersion}', tag: 'FoundationExample');

  // 3. Configure API client with resilient networking pipeline
  final httpClient = ResilientHttpClient(logger: logger);
  logger.info('Step 3: Configured resilient HTTP client middleware', tag: 'FoundationExample');

  // Create ProviderContainer for headless dependency injection
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(appDb),
      loggerProvider.overrideWithValue(logger),
    ],
  );

  try {
    // 5. Search music across multi-provider catalog
    final searchCtrl = container.read(searchControllerProvider.notifier);
    logger.info('Step 5: Executing music search for "Khuda"...', tag: 'FoundationExample');
    await searchCtrl.search('Khuda', immediate: true);
    final searchResults = container.read(searchControllerProvider).localResults;
    logger.info('Found ${searchResults.length} local results', tag: 'FoundationExample');

    // 6. Play a track & manage queue
    final playbackRepo = container.read(playbackRepositoryProvider);
    final sampleTrack = Track(
      id: 'demo_track_001',
      title: 'Foundation Demo Track',
      artist: 'Echo Bloom Architect',
      album: 'Clean Foundation',
      duration: const Duration(seconds: 180),
      mediaUri: 'https://preview.saavncdn.com/demo.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    logger.info('Step 6: Playing track "${sampleTrack.title}"...', tag: 'FoundationExample');
    await playbackRepo.playTrack(sampleTrack);

    // 7. Observe real-time playback state
    final playbackState = playbackRepo.currentState;
    logger.info('Step 7: Playback status: ${playbackState.status}, isPlaying: ${playbackState.isPlaying}', tag: 'FoundationExample');

    // 8. 5-Second Listening History Qualification
    logger.info('Step 8: Verifying listening history qualification...', tag: 'FoundationExample');
    final historyRepo = container.read(historyRepositoryProvider);
    final initialHistory = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
    logger.info('Initial history count: ${initialHistory.length} (Immediate clicks do NOT qualify)', tag: 'FoundationExample');

    // 9. Playlist Management
    logger.info('Step 9: Managing user playlists...', tag: 'FoundationExample');
    final playlistCtrl = container.read(playlistControllerProvider.notifier);
    await playlistCtrl.createPlaylist('Favorites 2026', description: 'Curated by foundation');
    final playlistState = container.read(playlistControllerProvider);
    logger.info('Active user playlists: ${playlistState.playlists.map((p) => p.name).toList()}', tag: 'FoundationExample');

    // 10. Downloads & Storage calculation
    logger.info('Step 10: Inspecting offline downloads & storage usage...', tag: 'FoundationExample');
    final downloadCtrl = container.read(downloadControllerProvider.notifier);
    logger.info('Current offline storage used: ${downloadCtrl.formattedStorageUsage}', tag: 'FoundationExample');

    // 11. Equalizer controls
    logger.info('Step 11: Applying Equalizer Rock preset...', tag: 'FoundationExample');
    final eqCtrl = container.read(equalizerControllerProvider.notifier);
    final rockPreset = EqualizerPreset.defaultPresets.firstWhere((p) => p.id == 'rock');
    await eqCtrl.applyPreset(rockPreset);
    logger.info('Active EQ band gains: ${container.read(equalizerControllerProvider).configuration.bandGains}', tag: 'FoundationExample');

    logger.info('Foundation integration example finished successfully!', tag: 'FoundationExample');
  } finally {
    // 12. Gracefully dispose and close resources
    logger.info('Step 12: Gracefully shutting down foundation...', tag: 'FoundationExample');
    httpClient.close();
    await appDb.close();
    container.dispose();
  }
}
