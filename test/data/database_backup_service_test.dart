import 'dart:convert';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/local/database/database_backup_service.dart';
import 'package:echo_bloom/data/local/database/database_migrator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('DatabaseBackupService Tests', () {
    late AppDatabase appDb;
    late DatabaseBackupService backupService;

    setUp(() async {
      final migrator = DatabaseMigrator();
      appDb = AppDatabase(migrator: migrator, databaseName: inMemoryDatabasePath);
      await appDb.initialize(inMemoryPath: inMemoryDatabasePath, customFactory: databaseFactoryFfi);
      backupService = DatabaseBackupService(appDatabase: appDb);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('verifyIntegrity returns true for healthy SQLite database', () async {
      final result = await backupService.verifyIntegrity();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isTrue);
    });

    test('exportBackup exports database tables into structured JSON', () async {
      // Seed some tracks and a playlist
      await appDb.database.insert('tracks', {
        'id': 't1',
        'title': 'Test Song',
        'artist': 'Test Artist',
        'album': 'Test Album',
        'duration_ms': 180000,
        'media_uri': 'https://example.com/audio.mp3',
        'is_favorite': 1,
        'date_added': 1000,
      });

      await appDb.database.insert('playlists', {
        'id': 'p1',
        'name': 'My Favorites',
        'created_at': 1000,
        'updated_at': 1000,
      });

      final result = await backupService.exportBackup();
      expect(result.isOk, isTrue);
      final jsonStr = result.valueOrNull!;

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], equals(4));
      expect(decoded['tracks'], isA<List>());
      expect((decoded['tracks'] as List).length, equals(1));
      expect((decoded['tracks'] as List).first['title'], equals('Test Song'));
      expect((decoded['playlists'] as List).length, equals(1));
    });

    test('importBackup restores tracks and playlists atomically', () async {
      final backupPayload = jsonEncode({
        'version': 4,
        'exported_at': DateTime.now().toIso8601String(),
        'tracks': [
          {
            'id': 'restored_1',
            'title': 'Restored Song',
            'artist': 'Restored Artist',
            'album': 'Restored Album',
            'duration_ms': 200000,
            'media_uri': 'https://example.com/restored.mp3',
            'is_favorite': 1,
            'date_added': 2000,
          }
        ],
        'playlists': [
          {
            'id': 'restored_p1',
            'name': 'Restored Playlist',
            'created_at': 2000,
            'updated_at': 2000,
          }
        ],
        'playlist_items': [],
        'playback_history': [],
        'listening_sessions': [],
        'play_counts': [
          {
            'track_id': 'restored_1',
            'play_count': 5,
            'last_played_at': 2500,
          }
        ],
        'key_value_store': [],
      });

      final result = await backupService.importBackup(backupPayload);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, equals(1));

      // Verify row exists in DB
      final tracks = await appDb.database.query('tracks', where: 'id = ?', whereArgs: ['restored_1']);
      expect(tracks.length, equals(1));
      expect(tracks.first['title'], equals('Restored Song'));

      final counts = await appDb.database.query('play_counts', where: 'track_id = ?', whereArgs: ['restored_1']);
      expect(counts.length, equals(1));
      expect(counts.first['play_count'], equals(5));
    });

    test('importBackup rejects non-object JSON gracefully', () async {
      final result = await backupService.importBackup('["not", "a", "map"]');
      expect(result.isErr, isTrue);
    });
  });
}
