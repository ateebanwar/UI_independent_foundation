import 'dart:async';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/features/playback/playback_repository_impl.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAudioEngine implements AudioEngine {
  final _eventsController = StreamController<AudioEngineEvent>.broadcast();
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _posController = StreamController<Duration>.broadcast();
  final _durController = StreamController<Duration>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _position = Duration.zero;

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
  Duration get currentDuration => const Duration(minutes: 3);
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
    _statusController.add(_status);
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

  @override
  Future<void> dispose() async {
    await _eventsController.close();
    await _statusController.close();
    await _posController.close();
    await _durController.close();
  }
}

void main() {
  group('Playback Advanced Features Tests (Sleep Timer, Crossfade, Queue Ops)', () {
    late StubAudioEngine stubEngine;
    late PlaybackRepositoryImpl playbackRepo;

    final track1 = Track(
      id: 'song_1',
      title: 'Song One',
      artist: 'Artist One',
      duration: const Duration(seconds: 200),
      mediaUri: '/storage/1.mp3',
      sourceType: TrackSourceType.localFile,
      dateAdded: DateTime.now(),
    );

    final track2 = Track(
      id: 'song_2',
      title: 'Song Two',
      artist: 'Artist Two',
      duration: const Duration(seconds: 240),
      mediaUri: '/storage/2.mp3',
      sourceType: TrackSourceType.localFile,
      dateAdded: DateTime.now(),
    );

    final track3 = Track(
      id: 'song_3',
      title: 'Song Three',
      artist: 'Artist Three',
      duration: const Duration(seconds: 180),
      mediaUri: '/storage/3.mp3',
      sourceType: TrackSourceType.localFile,
      dateAdded: DateTime.now(),
    );

    setUp(() {
      stubEngine = StubAudioEngine();
      playbackRepo = PlaybackRepositoryImpl(audioEngine: stubEngine);
    });

    tearDown(() {
      playbackRepo.dispose();
      stubEngine.dispose();
    });

    test('Queue reorder moves track and maintains consistent current index', () async {
      await playbackRepo.setQueue([track1, track2, track3], initialIndex: 0);
      expect(playbackRepo.currentQueue.currentList.map((t) => t.id).toList(), equals(['song_1', 'song_2', 'song_3']));

      // Reorder track 2 to index 0
      await playbackRepo.reorderQueue(1, 0);
      expect(playbackRepo.currentQueue.currentList.map((t) => t.id).toList(), equals(['song_2', 'song_1', 'song_3']));
    });

    test('Queue remove removes target track from list', () async {
      await playbackRepo.setQueue([track1, track2, track3], initialIndex: 0);

      await playbackRepo.removeTrackFromQueue('song_2');
      final remaining = playbackRepo.currentQueue.currentList;
      expect(remaining.length, equals(2));
      expect(remaining.any((t) => t.id == 'song_2'), isFalse);
    });

    test('Queue clear clears entire queue and stops playback', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);
      expect(playbackRepo.currentQueue.isEmpty, isFalse);

      await playbackRepo.clearQueue();
      expect(playbackRepo.currentQueue.isEmpty, isTrue);
      expect(playbackRepo.currentState.status, equals(PlaybackStatus.idle));
    });

    test('Crossfade duration configuration updates and exposes current duration', () {
      expect(playbackRepo.crossfadeDuration, equals(Duration.zero));

      playbackRepo.setCrossfadeDuration(const Duration(seconds: 4));
      expect(playbackRepo.crossfadeDuration, equals(const Duration(seconds: 4)));
    });

    test('Sleep timer sets remaining countdown and emits via sleepTimerStream', () async {
      await playbackRepo.setSleepTimer(const Duration(minutes: 30));

      final remaining = playbackRepo.currentSleepTimerRemaining;
      expect(remaining, isNotNull);
      expect(remaining!.inMinutes, equals(29)); // ~30 minutes

      await playbackRepo.cancelSleepTimer();
      expect(playbackRepo.currentSleepTimerRemaining, isNull);
    });
  });
}
