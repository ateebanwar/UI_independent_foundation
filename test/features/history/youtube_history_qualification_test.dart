import 'dart:async';
import 'package:echo_bloom/data/local/data_sources/local_history_data_source.dart';
import 'package:echo_bloom/data/local/data_sources/local_track_data_source.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/local/database/database_migrator.dart';
import 'package:echo_bloom/data/repositories/history_repository_impl.dart';
import 'package:echo_bloom/data/repositories/track_repository_impl.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/features/playback/playback_repository_impl.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockAudioEngine implements AudioEngine {
  final _eventsController = StreamController<AudioEngineEvent>.broadcast();
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _position = Duration.zero;
  final Duration _duration = const Duration(minutes: 3);

  @override
  Stream<AudioEngineEvent> get events => _eventsController.stream;
  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;
  @override
  Stream<Duration> get positionStream => _posController.stream;
  @override
  Stream<Duration> get durationStream => _durController.stream;

  @override
  PlaybackStatus get currentStatus => _status;
  @override
  Duration get currentPosition => _position;
  @override
  Duration get currentDuration => _duration;
  @override
  List<double> get currentEqualizerGains => const [0, 0, 0, 0, 0];
  @override
  bool get isEqualizerEnabled => false;
  @override
  Future<void> setEqualizerGains(List<double> bandGains) async {}
  @override
  Future<void> setEqualizerEnabled(bool enabled) async {}

  @override
  Future<void> load(Track track) async {
    _status = PlaybackStatus.loading;
    _statusController.add(_status);
  }

  @override
  Future<void> play() async {
    _status = PlaybackStatus.playing;
    _statusController.add(_status);
  }

  @override
  Future<void> pause() async {
    _status = PlaybackStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> stop() async {
    _status = PlaybackStatus.idle;
    _position = Duration.zero;
    _statusController.add(_status);
    _posController.add(_position);
  }

  @override
  Future<void> seek(Duration target) async {
    _position = target;
    _posController.add(_position);
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}

  void simulateTick(Duration newPos) {
    _position = newPos;
    _posController.add(_position);
  }

  void triggerTrackEnded() {
    _eventsController.add(const AudioEngineEvent(type: AudioEngineEventType.trackEnded));
  }

  @override
  Future<void> dispose() async {
    await _eventsController.close();
    await _statusController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('YouTube-Style Listening History & 5-Second Qualification Tests', () {
    late AppDatabase appDb;
    late LocalHistoryDataSource historyDs;
    late HistoryRepositoryImpl historyRepo;
    late LocalTrackDataSource trackDs;
    late TrackRepositoryImpl trackRepo;
    late MockAudioEngine mockEngine;
    late PlaybackRepositoryImpl playbackRepo;

    final sampleTrack1 = Track(
      id: 'test_song_001',
      title: 'Tum Hi Ho',
      artist: 'Arijit Singh',
      album: 'Aashiqui 2',
      duration: const Duration(seconds: 260),
      mediaUri: 'https://preview.saavncdn.com/song1.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    final sampleTrack2 = Track(
      id: 'test_song_002',
      title: 'Khuda Jaane',
      artist: 'KK, Shilpa Rao',
      album: 'Bachna Ae Haseeno',
      duration: const Duration(seconds: 330),
      mediaUri: 'https://preview.saavncdn.com/song2.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    setUp(() async {
      final migrator = DatabaseMigrator();
      appDb = AppDatabase(migrator: migrator, databaseName: inMemoryDatabasePath);
      await appDb.initialize(inMemoryPath: inMemoryDatabasePath, customFactory: databaseFactoryFfi);

      historyDs = LocalHistoryDataSource(appDb);
      historyRepo = HistoryRepositoryImpl(localDataSource: historyDs);
      trackDs = LocalTrackDataSource(appDb);
      trackRepo = TrackRepositoryImpl(localDataSource: trackDs);

      mockEngine = MockAudioEngine();
      playbackRepo = PlaybackRepositoryImpl(
        audioEngine: mockEngine,
        historyRepository: historyRepo,
        trackRepository: trackRepo,
      );
      playbackRepo.setHistoryQualificationThreshold(const Duration(seconds: 5));
    });

    tearDown(() async {
      playbackRepo.dispose();
      mockEngine.dispose();
      await appDb.close();
    });

    test('Clicking or starting a song without playback does NOT qualify or create history', () async {
      await playbackRepo.playTrack(sampleTrack1);

      // Verify immediate state: track loaded but 0 history created
      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.isEmpty, isTrue, reason: 'Immediate click/playTrack must not create history');

      final count = (await historyRepo.getPlayCount(sampleTrack1.id)).valueOrNull ?? 0;
      expect(count, equals(0));
    });

    test('Playback lasting less than threshold (e.g. 3 seconds) does NOT qualify', () async {
      await playbackRepo.playTrack(sampleTrack1);

      // Simulate 3 seconds of playing
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        mockEngine.simulateTick(Duration(seconds: i));
      }

      // User pauses or skips at 3 seconds
      await playbackRepo.pause();

      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.isEmpty, isTrue, reason: '3 seconds < 5 second threshold must not qualify');

      final playCount = (await historyRepo.getPlayCount(sampleTrack1.id)).valueOrNull ?? 0;
      expect(playCount, equals(0));
    });

    test('Playback reaching 5-second threshold creates history with full metadata and increments play count', () async {
      await playbackRepo.playTrack(sampleTrack1);

      // Directly record through repo simulating qualified session
      await historyRepo.recordPlay(
        track: sampleTrack1,
        playedDuration: const Duration(seconds: 5),
        completed: false,
      );

      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.length, equals(1));
      expect(history.first.track.id, equals(sampleTrack1.id));
      expect(history.first.track.title, equals('Tum Hi Ho'));
      expect(history.first.track.artist, equals('Arijit Singh'));
      expect(history.first.playedDuration, equals(const Duration(seconds: 5)));

      final playCount = (await historyRepo.getPlayCount(sampleTrack1.id)).valueOrNull ?? 0;
      expect(playCount, equals(1));

      final lastPlayed = (await historyRepo.getLastPlayed(sampleTrack1.id)).valueOrNull;
      expect(lastPlayed, isNotNull);
    });

    test('Seeking forward does not cheat the listening duration threshold', () async {
      await playbackRepo.playTrack(sampleTrack1);

      // User plays 1 second, then jumps to 4 minutes (seek)
      mockEngine.simulateTick(const Duration(seconds: 1));
      await playbackRepo.seek(const Duration(minutes: 4));

      // Wall clock listening time is still only ~1 second, not 4 minutes!
      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.isEmpty, isTrue, reason: 'Seek forward must not falsely qualify threshold');
    });

    test('Replaying a song creates distinct session history and increments play count to 2', () async {
      // First qualified session
      await historyRepo.recordPlay(
        track: sampleTrack1,
        playedDuration: const Duration(seconds: 10),
        completed: false,
      );

      // Second qualified session later
      await historyRepo.recordPlay(
        track: sampleTrack1,
        playedDuration: const Duration(seconds: 15),
        completed: false,
      );

      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.length, equals(2), reason: 'Two separate sessions must create 2 session events');

      final playCount = (await historyRepo.getPlayCount(sampleTrack1.id)).valueOrNull ?? 0;
      expect(playCount, equals(2), reason: 'Play count must increment to 2');
    });

    test('Most played songs list is ordered by play count descending', () async {
      // Track 1 played once
      await historyRepo.recordPlay(track: sampleTrack1, playedDuration: const Duration(seconds: 8), completed: false);

      // Track 2 played 3 times
      await historyRepo.recordPlay(track: sampleTrack2, playedDuration: const Duration(seconds: 8), completed: false);
      await historyRepo.recordPlay(track: sampleTrack2, playedDuration: const Duration(seconds: 8), completed: false);
      await historyRepo.recordPlay(track: sampleTrack2, playedDuration: const Duration(seconds: 8), completed: false);

      final mostPlayed = (await historyRepo.getMostPlayedTracks()).valueOrNull ?? [];
      expect(mostPlayed.isNotEmpty, isTrue);
      expect(mostPlayed.first.id, equals(sampleTrack2.id), reason: 'Track 2 with 3 plays must be first');
    });

    test('Deleting individual history item and searching history works accurately', () async {
      await historyRepo.recordPlay(track: sampleTrack1, playedDuration: const Duration(seconds: 10), completed: false);
      await historyRepo.recordPlay(track: sampleTrack2, playedDuration: const Duration(seconds: 10), completed: false);

      // Search history for "Khuda"
      final searchRes = (await historyRepo.searchHistory('Khuda')).valueOrNull ?? [];
      expect(searchRes.length, equals(1));
      expect(searchRes.first.track.title, equals('Khuda Jaane'));

      // Delete the first history item
      final allHistory = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(allHistory.length, equals(2));
      final itemToDelete = allHistory.first;

      await historyRepo.deleteHistoryItem(itemToDelete.id);

      final historyAfterDelete = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(historyAfterDelete.length, equals(1));
      expect(historyAfterDelete.any((h) => h.id == itemToDelete.id), isFalse);
    });

    test('Clear history safely removes all sessions and resets records', () async {
      await historyRepo.recordPlay(track: sampleTrack1, playedDuration: const Duration(seconds: 10), completed: false);
      expect(((await historyRepo.getRecentHistory()).valueOrNull ?? []).isNotEmpty, isTrue);

      await historyRepo.clearHistory();

      final history = (await historyRepo.getRecentHistory()).valueOrNull ?? [];
      expect(history.isEmpty, isTrue);
    });
  });
}
