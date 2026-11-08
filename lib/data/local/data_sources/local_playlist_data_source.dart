import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/mappers/playlist_mapper.dart';
import 'package:echo_bloom/data/mappers/track_mapper.dart';
import 'package:echo_bloom/domain/entities/playlist.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Concrete local data source for managing playlists and playlist tracks in SQLite.
class LocalPlaylistDataSource {
  final AppDatabase _appDatabase;
  final Uuid _uuid;

  LocalPlaylistDataSource(this._appDatabase, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  Database get _db => _appDatabase.database;

  Future<List<Playlist>> getPlaylists() async {
    final rows = await _db.rawQuery('''
      SELECT 
        p.*,
        COUNT(pi.track_id) as track_count,
        COALESCE(SUM(t.duration_ms), 0) as total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id
      LEFT JOIN tracks t ON pi.track_id = t.id
      GROUP BY p.id
      ORDER BY p.name COLLATE NOCASE ASC;
    ''');

    return rows.map(PlaylistMapper.fromDbMap).toList();
  }

  Future<Playlist?> getPlaylistById(String id) async {
    final rows = await _db.rawQuery('''
      SELECT 
        p.*,
        COUNT(pi.track_id) as track_count,
        COALESCE(SUM(t.duration_ms), 0) as total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id
      LEFT JOIN tracks t ON pi.track_id = t.id
      WHERE p.id = ?
      GROUP BY p.id
      LIMIT 1;
    ''', [id]);

    if (rows.isEmpty) return null;
    return PlaylistMapper.fromDbMap(rows.first);
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final rows = await _db.rawQuery('''
      SELECT t.*
      FROM tracks t
      INNER JOIN playlist_items pi ON t.id = pi.track_id
      WHERE pi.playlist_id = ?
      ORDER BY pi.position ASC;
    ''', [playlistId]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final id = _uuid.v4();
    final playlist = Playlist(
      id: id,
      name: name,
      description: description,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await _db.insert('playlists', PlaylistMapper.toDbMap(playlist));
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    await _db.update(
      'playlists',
      PlaylistMapper.toDbMap(playlist),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    Track? track,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;

    if (track != null) {
      await _db.insert(
        'tracks',
        TrackMapper.toDbMap(track),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final maxPosResult = await _db.rawQuery(
      'SELECT MAX(position) as max_pos FROM playlist_items WHERE playlist_id = ?;',
      [playlistId],
    );
    final maxPos = Sqflite.firstIntValue(maxPosResult) ?? -1;
    final nextPos = maxPos + 1;

    await _db.insert(
      'playlist_items',
      {
        'playlist_id': playlistId,
        'track_id': trackId,
        'position': nextPos,
        'added_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _db.update(
      'playlists',
      {'updated_at': timestamp},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    await _db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );

    await _db.update(
      'playlists',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> reorderTrack({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final items = await _db.query(
      'playlist_items',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) {
      return;
    }

    final mutableItems = List<Map<String, dynamic>>.from(items);
    final movedItem = mutableItems.removeAt(oldIndex);
    mutableItems.insert(newIndex, movedItem);

    final batch = _db.batch();
    for (var i = 0; i < mutableItems.length; i++) {
      batch.update(
        'playlist_items',
        {'position': i},
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, mutableItems[i]['track_id']],
      );
    }
    await batch.commit(noResult: true);
  }
}
