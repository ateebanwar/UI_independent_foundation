import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/mappers/track_mapper.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:sqflite/sqflite.dart';

/// Local SQLite data source for synchronizing and storing release collections.
class LocalSyncReleasesDataSource {
  final AppDatabase _appDatabase;

  LocalSyncReleasesDataSource(this._appDatabase);

  Database get _db => _appDatabase.database;

  Future<void> upsertReleases(List<SyncRelease> releases) async {
    if (releases.isEmpty) return;

    await _db.transaction((txn) async {
      for (final release in releases) {
        await txn.insert(
          'sync_releases',
          {
            'id': release.id,
            'title': release.title,
            'artist': release.artist,
            'release_date': release.releaseDate,
            'release_type': release.releaseType,
            'artwork_uri': release.artworkUri,
            'track_count': release.trackCount,
            'synced_at': release.syncedAt.millisecondsSinceEpoch,
            'remote_provider': release.remoteProvider,
            'remote_url': release.remoteUrl,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (int i = 0; i < release.tracks.length; i++) {
          final track = release.tracks[i];
          final existing = await txn.query('tracks', columns: ['id'], where: 'id = ?', whereArgs: [track.id]);
          if (existing.isEmpty) {
            await txn.insert('tracks', TrackMapper.toDbMap(track), conflictAlgorithm: ConflictAlgorithm.ignore);
          }

          await txn.insert(
            'sync_release_tracks',
            {
              'release_id': release.id,
              'track_id': track.id,
              'position': i,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<List<SyncRelease>> getCachedReleases() async {
    final rows = await _db.query(
      'sync_releases',
      orderBy: 'synced_at DESC, release_date DESC',
    );

    final releases = <SyncRelease>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final tracks = await getReleaseTracks(id);
      releases.add(SyncRelease(
        id: id,
        title: row['title'] as String,
        artist: row['artist'] as String,
        releaseDate: row['release_date'] as String?,
        releaseType: (row['release_type'] as String?) ?? 'album',
        artworkUri: row['artwork_uri'] as String?,
        trackCount: (row['track_count'] as num?)?.toInt() ?? tracks.length,
        syncedAt: DateTime.fromMillisecondsSinceEpoch((row['synced_at'] as num).toInt()),
        remoteProvider: (row['remote_provider'] as String?) ?? 'jiosaavn',
        remoteUrl: row['remote_url'] as String?,
        tracks: tracks,
      ));
    }
    return releases;
  }

  Future<List<Track>> getReleaseTracks(String releaseId) async {
    final rows = await _db.rawQuery('''
      SELECT t.* FROM tracks t
      INNER JOIN sync_release_tracks srt ON srt.track_id = t.id
      WHERE srt.release_id = ?
      ORDER BY srt.position ASC
    ''', [releaseId]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }
}
