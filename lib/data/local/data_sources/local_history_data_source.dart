import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/mappers/history_mapper.dart';
import 'package:echo_bloom/data/mappers/track_mapper.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/history_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Concrete local data source for playback history in SQLite.
class LocalHistoryDataSource {
  final AppDatabase _appDatabase;
  final Uuid _uuid;

  LocalHistoryDataSource(this._appDatabase, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  Database get _db => _appDatabase.database;

  Future<void> recordPlay({
    required Track track,
    required Duration playedDuration,
    required bool completed,
    DateTime? playedAt,
  }) async {
    final timestamp = (playedAt ?? DateTime.now()).millisecondsSinceEpoch;
    final id = _uuid.v4();

    // 1. Ensure track exists in tracks table so foreign key constraints are met
    final existingTrack = await _db.query('tracks', columns: ['id'], where: 'id = ?', whereArgs: [track.id]);
    if (existingTrack.isEmpty) {
      await _db.insert('tracks', TrackMapper.toDbMap(track), conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 2. Insert into legacy playback_history
    await _db.insert('playback_history', {
      'id': id,
      'track_id': track.id,
      'played_at': timestamp,
      'played_duration_ms': playedDuration.inMilliseconds,
      'completed': completed ? 1 : 0,
    });

    // 3. Insert into YouTube-style listening_sessions with complete offline metadata
    await _db.insert('listening_sessions', {
      'id': id,
      'track_id': track.id,
      'title': track.title,
      'artist': track.artist,
      'album': track.album,
      'artwork_uri': track.artworkUri,
      'source_type': track.sourceType.index,
      'remote_provider': track.remoteProvider,
      'played_at': timestamp,
      'duration_listened_ms': playedDuration.inMilliseconds,
      'track_duration_ms': track.duration.inMilliseconds,
      'completed': completed ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 4. Update play_counts table
    final existingCount = await _db.query('play_counts', where: 'track_id = ?', whereArgs: [track.id]);
    if (existingCount.isEmpty) {
      await _db.insert('play_counts', {
        'track_id': track.id,
        'play_count': 1,
        'last_played_at': timestamp,
        'total_listened_ms': playedDuration.inMilliseconds,
      });
    } else {
      final currentCount = (existingCount.first['play_count'] as num?)?.toInt() ?? 0;
      final totalListened = (existingCount.first['total_listened_ms'] as num?)?.toInt() ?? 0;
      await _db.update(
        'play_counts',
        {
          'play_count': currentCount + 1,
          'last_played_at': timestamp,
          'total_listened_ms': totalListened + playedDuration.inMilliseconds,
        },
        where: 'track_id = ?',
        whereArgs: [track.id],
      );
    }
  }

  Future<List<PlayHistoryItem>> getRecentHistory({int limit = 50}) async {
    // Prefer listening_sessions as it retains full offline metadata even if original track was removed
    try {
      final rows = await _db.query(
        'listening_sessions',
        orderBy: 'played_at DESC',
        limit: limit,
      );
      if (rows.isNotEmpty) {
        return rows.map((r) {
          final track = Track(
            id: r['track_id'] as String,
            title: r['title'] as String,
            artist: r['artist'] as String,
            album: r['album'] as String?,
            duration: Duration(milliseconds: (r['track_duration_ms'] as num?)?.toInt() ?? 0),
            mediaUri: '',
            sourceType: TrackSourceType.values[(r['source_type'] as num?)?.toInt() ?? 0],
            artworkUri: r['artwork_uri'] as String?,
            dateAdded: DateTime.fromMillisecondsSinceEpoch((r['played_at'] as num).toInt()),
            remoteProvider: r['remote_provider'] as String?,
          );
          return PlayHistoryItem(
            id: r['id'] as String,
            track: track,
            playedAt: DateTime.fromMillisecondsSinceEpoch((r['played_at'] as num).toInt()),
            playedDuration: Duration(milliseconds: (r['duration_listened_ms'] as num?)?.toInt() ?? 0),
            completed: (r['completed'] as num? ?? 0) == 1,
          );
        }).toList();
      }
    } catch (_) {}

    // Fallback to playback_history JOIN tracks
    final rows = await _db.rawQuery('''
      SELECT 
        h.id as history_id,
        h.played_at,
        h.played_duration_ms,
        h.completed,
        t.*
      FROM playback_history h
      INNER JOIN tracks t ON h.track_id = t.id
      ORDER BY h.played_at DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map((r) => HistoryMapper.fromDbMap(r)).toList();
  }

  Future<List<Track>> getMostPlayedTracks({int limit = 20}) async {
    // Check play_counts first
    try {
      final countRows = await _db.rawQuery('''
        SELECT t.*, pc.play_count
        FROM tracks t
        INNER JOIN play_counts pc ON t.id = pc.track_id
        ORDER BY pc.play_count DESC, pc.last_played_at DESC
        LIMIT ?;
      ''', [limit]);
      if (countRows.isNotEmpty) {
        return countRows.map(TrackMapper.fromDbMap).toList();
      }
    } catch (_) {}

    final rows = await _db.rawQuery('''
      SELECT 
        t.*,
        COUNT(h.id) as play_count
      FROM tracks t
      INNER JOIN playback_history h ON t.id = h.track_id
      GROUP BY t.id
      ORDER BY play_count DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<int> getPlayCount(String trackId) async {
    try {
      final rows = await _db.query('play_counts', columns: ['play_count'], where: 'track_id = ?', whereArgs: [trackId]);
      if (rows.isNotEmpty) {
        return (rows.first['play_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    final rows = await _db.rawQuery('SELECT COUNT(*) as count FROM playback_history WHERE track_id = ?', [trackId]);
    if (rows.isNotEmpty) {
      return (rows.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<DateTime?> getLastPlayed(String trackId) async {
    try {
      final rows = await _db.query('play_counts', columns: ['last_played_at'], where: 'track_id = ?', whereArgs: [trackId]);
      if (rows.isNotEmpty) {
        final ms = (rows.first['last_played_at'] as num?)?.toInt();
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    final rows = await _db.query('playback_history', columns: ['played_at'], where: 'track_id = ?', orderBy: 'played_at DESC', limit: 1);
    if (rows.isNotEmpty) {
      final ms = (rows.first['played_at'] as num?)?.toInt();
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  Future<void> deleteHistoryItem(String historyId) async {
    await _db.delete('listening_sessions', where: 'id = ?', whereArgs: [historyId]);
    await _db.delete('playback_history', where: 'id = ?', whereArgs: [historyId]);
  }

  Future<List<PlayHistoryItem>> searchHistory(String query) async {
    final pattern = '%$query%';
    try {
      final rows = await _db.query(
        'listening_sessions',
        where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
        whereArgs: [pattern, pattern, pattern],
        orderBy: 'played_at DESC',
      );
      return rows.map((r) {
        final track = Track(
          id: r['track_id'] as String,
          title: r['title'] as String,
          artist: r['artist'] as String,
          album: r['album'] as String?,
          duration: Duration(milliseconds: (r['track_duration_ms'] as num?)?.toInt() ?? 0),
          mediaUri: '',
          sourceType: TrackSourceType.values[(r['source_type'] as num?)?.toInt() ?? 0],
          artworkUri: r['artwork_uri'] as String?,
          dateAdded: DateTime.fromMillisecondsSinceEpoch((r['played_at'] as num).toInt()),
          remoteProvider: r['remote_provider'] as String?,
        );
        return PlayHistoryItem(
          id: r['id'] as String,
          track: track,
          playedAt: DateTime.fromMillisecondsSinceEpoch((r['played_at'] as num).toInt()),
          playedDuration: Duration(milliseconds: (r['duration_listened_ms'] as num?)?.toInt() ?? 0),
          completed: (r['completed'] as num? ?? 0) == 1,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearHistory() async {
    await _db.delete('playback_history');
    try {
      await _db.delete('listening_sessions');
      await _db.delete('play_counts');
    } catch (_) {}
  }
}

