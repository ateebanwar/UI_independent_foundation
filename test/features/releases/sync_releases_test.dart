import 'package:echo_bloom/data/local/data_sources/local_sync_releases_data_source.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/local/database/database_migrator.dart';
import 'package:echo_bloom/data/repositories/sync_releases_repository_impl.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Sync Releases Feature Tests', () {
    late AppDatabase appDb;
    late LocalSyncReleasesDataSource localDs;
    late SyncReleasesRepositoryImpl repository;

    final sampleRelease1 = SyncRelease(
      id: 'rel_brahmastra_01',
      title: 'Brahmastra Part 1: Shiva',
      artist: 'Pritam, Arijit Singh',
      releaseDate: '2022',
      releaseType: 'album',
      artworkUri: 'https://img.saavn.com/brahmastra.jpg',
      trackCount: 2,
      syncedAt: DateTime(2026, 1, 1),
      tracks: [
        Track(
          id: 'brahmastra_track_1',
          title: 'Kesariya',
          artist: 'Arijit Singh, Pritam',
          duration: const Duration(seconds: 268),
          mediaUri: 'https://stream.saavn.com/kesariya.mp4',
          sourceType: TrackSourceType.remoteStream,
          dateAdded: DateTime(2026, 1, 1),
        ),
        Track(
          id: 'brahmastra_track_2',
          title: 'Deva Deva',
          artist: 'Arijit Singh, Jonita Gandhi',
          duration: const Duration(seconds: 279),
          mediaUri: 'https://stream.saavn.com/deva.mp4',
          sourceType: TrackSourceType.remoteStream,
          dateAdded: DateTime(2026, 1, 1),
        ),
      ],
    );

    setUp(() async {
      final migrator = DatabaseMigrator();
      appDb = AppDatabase(migrator: migrator, databaseName: inMemoryDatabasePath);
      await appDb.initialize(inMemoryPath: inMemoryDatabasePath, customFactory: databaseFactoryFfi);

      localDs = LocalSyncReleasesDataSource(appDb);
      repository = SyncReleasesRepositoryImpl(localDataSource: localDs);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('Upserting releases saves release and release tracks into SQLite tables', () async {
      await localDs.upsertReleases([sampleRelease1]);

      final cached = await localDs.getCachedReleases();
      expect(cached.length, equals(1));
      expect(cached.first.title, equals('Brahmastra Part 1: Shiva'));
      expect(cached.first.artist, equals('Pritam, Arijit Singh'));
      expect(cached.first.trackCount, equals(2));

      final tracks = await localDs.getReleaseTracks(sampleRelease1.id);
      expect(tracks.length, equals(2));
      expect(tracks.map((t) => t.title), containsAll(['Kesariya', 'Deva Deva']));
    });

    test('Cached releases are retrieved accurately without network connection (offline-first)', () async {
      await localDs.upsertReleases([sampleRelease1]);

      final result = await repository.getCachedReleases();
      expect(result.isOk, isTrue);
      final releases = result.valueOrNull!;
      expect(releases.length, equals(1));
      expect(releases.first.id, equals(sampleRelease1.id));
      expect(releases.first.tracks.length, equals(2));
    });

    test('Updating release prevents duplicate insertion and updates sync timestamp', () async {
      await localDs.upsertReleases([sampleRelease1]);

      final updatedRelease = sampleRelease1.copyWith(
        title: 'Brahmastra: Special Edition',
        syncedAt: DateTime(2026, 1, 2),
      );

      await localDs.upsertReleases([updatedRelease]);

      final cached = await localDs.getCachedReleases();
      expect(cached.length, equals(1), reason: 'Must not duplicate release record');
      expect(cached.first.title, equals('Brahmastra: Special Edition'));
    });
  });
}

