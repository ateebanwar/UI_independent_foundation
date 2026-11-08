import 'dart:async';
import 'package:echo_bloom/data/local/data_sources/local_track_data_source.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/local/database/database_migrator.dart';
import 'package:echo_bloom/data/remote/contracts/remote_music_data_source.dart';
import 'package:echo_bloom/data/repositories/track_repository_impl.dart';
import 'package:echo_bloom/domain/entities/app_mode.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/features/playback/playback_repository_impl.dart';
import 'package:echo_bloom/features/search/search_controller.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockRemoteDataSource implements RemoteMusicDataSource {
  final Map<String, List<Track>> responses;

  MockRemoteDataSource(this.responses);

  @override
  Future<List<Track>> searchRemoteCatalog(String query, {int page = 1, int limit = 20}) async {
    final lower = query.toLowerCase();
    for (final key in responses.keys) {
      if (lower.contains(key.toLowerCase())) {
        return responses[key]!;
      }
    }
    return const [];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudioEngine implements AudioEngine {
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
    _status = PlaybackStatus.buffering;
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
  Future<void> seek(Duration position) async {
    _position = position;
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
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Multi-Provider Search & Discovery Tests', () {
    late AppDatabase appDb;
    late LocalTrackDataSource localDs;
    late TrackRepositoryImpl trackRepo;
    late SearchController searchCtrl;
    late PlaybackRepositoryImpl playbackRepo;

    final khudaTracks = [
      Track(
        id: 'jiosaavn_khuda_bhi',
        title: 'Khuda Bhi',
        artist: 'Mohit Chauhan, Tony Kakkar',
        album: 'Ek Paheli Leela',
        duration: const Duration(seconds: 300),
        mediaUri: 'https://aac.saavncdn.com/stream/khuda_bhi.mp4',
        sourceType: TrackSourceType.remoteStream,
        dateAdded: DateTime.now(),
        remoteProvider: 'jiosaavn',
      ),
      Track(
        id: 'jiosaavn_khuda_jaane',
        title: 'Khuda Jaane',
        artist: 'KK, Shilpa Rao',
        album: 'Bachna Ae Haseeno',
        duration: const Duration(seconds: 333),
        mediaUri: 'https://aac.saavncdn.com/stream/khuda_jaane.mp4',
        sourceType: TrackSourceType.remoteStream,
        dateAdded: DateTime.now(),
        remoteProvider: 'jiosaavn',
      ),
    ];

    final arijitTracks = [
      Track(
        id: 'jiosaavn_tum_hi_ho',
        title: 'Tum Hi Ho',
        artist: 'Arijit Singh',
        album: 'Aashiqui 2',
        duration: const Duration(seconds: 262),
        mediaUri: 'https://aac.saavncdn.com/stream/tum_hi_ho.mp4',
        sourceType: TrackSourceType.remoteStream,
        dateAdded: DateTime.now(),
        remoteProvider: 'jiosaavn',
      ),
      Track(
        id: 'jiosaavn_channa_mereya',
        title: 'Channa Mereya',
        artist: 'Arijit Singh',
        album: 'Ae Dil Hai Mushkil',
        duration: const Duration(seconds: 289),
        mediaUri: 'https://aac.saavncdn.com/stream/channa_mereya.mp4',
        sourceType: TrackSourceType.remoteStream,
        dateAdded: DateTime.now(),
        remoteProvider: 'jiosaavn',
      ),
    ];

    setUp(() async {
      final migrator = DatabaseMigrator();
      appDb = AppDatabase(migrator: migrator, databaseName: inMemoryDatabasePath);
      await appDb.initialize(inMemoryPath: inMemoryDatabasePath, customFactory: databaseFactoryFfi);

      localDs = LocalTrackDataSource(appDb);
      final remoteDs = MockRemoteDataSource({
        'khuda': khudaTracks,
        'arijit': arijitTracks,
      });

      trackRepo = TrackRepositoryImpl(
        localDataSource: localDs,
        remoteDataSource: remoteDs,
      );

      searchCtrl = SearchController(trackRepo, AppMode.online);
      playbackRepo = PlaybackRepositoryImpl(
        audioEngine: FakeAudioEngine(),
        trackRepository: trackRepo,
      );
    });

    tearDown(() async {
      searchCtrl.dispose();
      playbackRepo.dispose();
      await appDb.close();
    });

    test('Searching "Khuda" returns all matching songs, artist attribution, and album metadata', () async {
      await searchCtrl.search('Khuda', immediate: true);

      final state = searchCtrl.state;
      expect(state.remoteResults.length, equals(2));
      expect(state.remoteResults.map((t) => t.title), containsAll(['Khuda Bhi', 'Khuda Jaane']));
      expect(state.albumResults.any((a) => a.title == 'Ek Paheli Leela'), isTrue);
      expect(state.albumResults.any((a) => a.title == 'Bachna Ae Haseeno'), isTrue);
    });

    test('Searching "Arijit Singh" returns artist discography and builds a playable artist collection', () async {
      await searchCtrl.search('Arijit Singh', immediate: true);

      final state = searchCtrl.state;
      expect(state.remoteResults.length, equals(2));
      expect(state.remoteResults.every((t) => t.artist.contains('Arijit Singh')), isTrue);
      expect(state.artistResults.any((a) => a.name.contains('Arijit Singh')), isTrue);
    });

    test('Play All action loads entire collection into active queue and sets initial track', () async {
      await searchCtrl.playAll(khudaTracks, playbackRepo);

      expect(playbackRepo.currentState.currentTrack?.title, equals('Khuda Bhi'));
      expect(playbackRepo.currentQueue.currentList.length, equals(2));
    });

    test('Queue All action appends collection to existing playback queue without interrupting current track', () async {
      // Start with Arijit
      await playbackRepo.playTrack(arijitTracks.first);
      expect(playbackRepo.currentState.currentTrack?.title, equals('Tum Hi Ho'));

      // Queue all Khuda tracks
      await searchCtrl.queueAll(khudaTracks, playbackRepo);

      final queue = playbackRepo.currentQueue.currentList;
      expect(queue.length, equals(3));
      expect(queue.first.title, equals('Tum Hi Ho'));
      expect(queue.map((t) => t.title), containsAll(['Tum Hi Ho', 'Khuda Bhi', 'Khuda Jaane']));
    });
  });
}
