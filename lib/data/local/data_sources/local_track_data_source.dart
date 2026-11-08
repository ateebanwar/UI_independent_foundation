
import 'package:echo_bloom/core/types/pagination.dart';
import 'dart:io';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/data/mappers/track_mapper.dart';
import 'package:echo_bloom/domain/entities/album.dart';
import 'package:echo_bloom/domain/entities/artist.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Concrete local data source executing indexed SQLite queries for tracks.
class LocalTrackDataSource {
  final AppDatabase _appDatabase;

  const LocalTrackDataSource(this._appDatabase);

  Database get _db => _appDatabase.database;

  Future<PaginatedList<Track>> getTracks(PageQuery query) async {
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE source_type != ?;',
      [TrackSourceType.remoteStream.index],
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    final sortCol = query.sortBy ?? 'title';
    final sortOrder = query.ascending ? 'ASC' : 'DESC';

    final rows = await _db.query(
      'tracks',
      where: 'source_type != ?',
      whereArgs: [TrackSourceType.remoteStream.index],
      orderBy: '$sortCol COLLATE NOCASE $sortOrder',
      limit: query.limit,
      offset: query.offset,
    );

    final items = rows.map(TrackMapper.fromDbMap).toList();
    return PaginatedList(
      items: items,
      totalCount: totalCount,
      offset: query.offset,
      limit: query.limit,
    );
  }

  Future<Track?> getTrackById(String id) async {
    final rows = await _db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TrackMapper.fromDbMap(rows.first);
  }

  Future<List<Track>> searchTracks(String searchTerm) async {
    final pattern = '%$searchTerm%';
    final rows = await _db.query(
      'tracks',
      where: '(title LIKE ? OR artist LIKE ? OR album LIKE ?) AND source_type != ?',
      whereArgs: [pattern, pattern, pattern, TrackSourceType.remoteStream.index],
      orderBy: 'title COLLATE NOCASE ASC',
      limit: 100,
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Artist>> getArtists() async {
    final rows = await _db.rawQuery('''
      SELECT 
        artist as name,
        COUNT(*) as track_count,
        COUNT(DISTINCT album) as album_count,
        MIN(artwork_uri) as artwork_uri
      FROM tracks
      GROUP BY artist COLLATE NOCASE
      ORDER BY artist COLLATE NOCASE ASC;
    ''');

    return rows.map((r) => Artist(
      id: r['name'] as String,
      name: r['name'] as String,
      trackCount: r['track_count'] as int,
      albumCount: r['album_count'] as int,
      artworkUri: r['artwork_uri'] as String?,
    )).toList();
  }

  Future<List<Album>> getAlbums() async {
    final rows = await _db.rawQuery('''
      SELECT 
        COALESCE(album, 'Unknown Album') as title,
        artist,
        MIN(year) as year,
        COUNT(*) as track_count,
        MIN(artwork_uri) as artwork_uri
      FROM tracks
      WHERE album IS NOT NULL AND album != ''
      GROUP BY album COLLATE NOCASE, artist COLLATE NOCASE
      ORDER BY album COLLATE NOCASE ASC;
    ''');

    return rows.map((r) => Album(
      id: '${r['title']}_${r['artist']}',
      title: r['title'] as String,
      artist: r['artist'] as String,
      year: r['year'] as int?,
      trackCount: r['track_count'] as int,
      artworkUri: r['artwork_uri'] as String?,
    )).toList();
  }

  Future<List<Track>> getTracksByArtist(String artistName) async {
    final rows = await _db.query(
      'tracks',
      where: 'artist = ? COLLATE NOCASE',
      whereArgs: [artistName],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Track>> getTracksByAlbum(String albumName) async {
    final rows = await _db.query(
      'tracks',
      where: 'album = ? COLLATE NOCASE',
      whereArgs: [albumName],
      orderBy: 'track_number ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Track>> getFavoriteTracks() async {
    final rows = await _db.query(
      'tracks',
      where: 'is_favorite = 1',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<Track>> getDownloadedTracks() async {
    final rows = await _db.query(
      'tracks',
      where: 'source_type = ?',
      whereArgs: [TrackSourceType.downloaded.index],
      orderBy: 'date_added DESC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<bool> toggleFavorite(String trackId, [Track? track]) async {
    final existing = await getTrackById(trackId);
    if (existing == null && track != null) {
      await upsertTracks([track.copyWith(isFavorite: true)]);
      return true;
    }
    if (existing == null) return false;

    final newFavoriteStatus = !existing.isFavorite;
    await _db.update(
      'tracks',
      {'is_favorite': newFavoriteStatus ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
    return newFavoriteStatus;
  }

  Future<int> upsertTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return 0;

    int affected = 0;
    await _db.transaction((txn) async {
      for (final track in tracks) {
        final data = TrackMapper.toDbMap(track);
        final count = await txn.update(
          'tracks',
          data,
          where: 'id = ?',
          whereArgs: [track.id],
        );
        if (count > 0) {
          affected += count;
        } else {
          await txn.insert(
            'tracks',
            data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          affected++;
        }
      }
    });
    return affected;
  }

  Future<int> deleteTracks(List<String> trackIds) async {
    if (trackIds.isEmpty) return 0;
    return await _db.delete(
      'tracks',
      where: 'id IN (${List.filled(trackIds.length, '?').join(',')})',
      whereArgs: trackIds,
    );
  }

  Future<int> getTrackCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE source_type != ?;',
      [TrackSourceType.remoteStream.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getFolders() async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT media_uri FROM tracks
      WHERE source_type = ?
    ''', [TrackSourceType.localFile.index]);

    final folders = <String>{};
    for (final row in rows) {
      final uri = row['media_uri'] as String;
      final lastSlash = uri.lastIndexOf(RegExp(r'[/\\]'));
      if (lastSlash > 0) {
        folders.add(uri.substring(0, lastSlash));
      }
    }
    final sorted = folders.toList()..sort();
    return sorted;
  }

  Future<List<Track>> getTracksInFolder(String folderPath) async {
    final pattern = '$folderPath%';
    final rows = await _db.query(
      'tracks',
      where: 'media_uri LIKE ? AND source_type = ?',
      whereArgs: [pattern, TrackSourceType.localFile.index],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(TrackMapper.fromDbMap).toList();
  }

  Future<List<String>> cleanMissingLocalFiles() async {
    final rows = await _db.query(
      'tracks',
      where: 'source_type = ?',
      whereArgs: [TrackSourceType.localFile.index],
    );
    final missingIds = <String>[];
    for (final r in rows) {
      final uri = r['media_uri'] as String;
      if (!kIsWeb && (uri.startsWith('/') || uri.contains(r':\'))) {
        try {
          if (!File(uri).existsSync()) {
            missingIds.add(r['id'] as String);
          }
        } catch (_) {}
      }
    }
    if (missingIds.isNotEmpty) {
      await deleteTracks(missingIds);
    }
    return missingIds;
  }
}
