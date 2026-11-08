import 'dart:async';
import 'dart:io';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/infrastructure/storage/web_blob_url.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Unified offline audio storage service.
class OfflineAudioStorage {
  final AppDatabase _appDatabase;
  final AppLogger? _logger;

  final Map<String, String> _activeBlobUrls = {};

  OfflineAudioStorage({
    required AppDatabase appDatabase,
    AppLogger? logger,
  })  : _appDatabase = appDatabase,
        _logger = logger;

  static String safeFilename(String trackId) {
    return trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  Future<String> saveAudio({
    required String trackId,
    required List<int> bytes,
    String mimeType = 'audio/mp4',
  }) async {
    final uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (kIsWeb) {
      final db = _appDatabase.database;
      await db.insert(
        'offline_audio_blobs',
        {
          'track_id': trackId,
          'audio_data': uint8Bytes,
          'mime_type': mimeType,
          'file_size': uint8Bytes.length,
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _logger?.info('Saved offline audio blob in IndexedDB for $trackId (${uint8Bytes.length} bytes)', tag: 'OfflineAudioStorage');
      return 'offline://track/$trackId';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (!downloadDir.existsSync()) {
        await downloadDir.create(recursive: true);
      }

      final safeId = safeFilename(trackId);
      final finalFile = File('${downloadDir.path}/$safeId.m4a');

      await finalFile.writeAsBytes(uint8Bytes, flush: true);
      _logger?.info('Saved offline audio file at ${finalFile.path}', tag: 'OfflineAudioStorage');
      return finalFile.path;
    }
  }

  Future<String?> resolvePlayableUri(Track track) async {
    if (kIsWeb) {
      if (_activeBlobUrls.containsKey(track.id)) {
        return _activeBlobUrls[track.id];
      }

      final db = _appDatabase.database;
      final rows = await db.query(
        'offline_audio_blobs',
        columns: ['audio_data', 'mime_type'],
        where: 'track_id = ?',
        whereArgs: [track.id],
      );

      if (rows.isNotEmpty) {
        final blobData = rows.first['audio_data'] as Uint8List?;
        final mimeType = (rows.first['mime_type'] as String?) ?? 'audio/mp4';

        if (blobData != null && blobData.isNotEmpty) {
          final blobUrl = WebBlobUrlHelper.createBlobUrl(blobData, mimeType);
          if (blobUrl != null) {
            _activeBlobUrls[track.id] = blobUrl;
            _logger?.info('Resolved offline blob object URL for ${track.title}', tag: 'OfflineAudioStorage');
            return blobUrl;
          }
        }
      }
      return null;
    } else {
      if (track.mediaUri.startsWith('offline://')) {
        final appDir = await getApplicationDocumentsDirectory();
        final safeId = safeFilename(track.id);
        final file = File('${appDir.path}/downloads/$safeId.m4a');
        if (file.existsSync()) {
          return file.path;
        }
      }
      return track.mediaUri;
    }
  }

  Future<void> deleteAudio(String trackId) async {
    if (kIsWeb) {
      if (_activeBlobUrls.containsKey(trackId)) {
        WebBlobUrlHelper.revokeBlobUrl(_activeBlobUrls[trackId]!);
        _activeBlobUrls.remove(trackId);
      }
      final db = _appDatabase.database;
      await db.delete(
        'offline_audio_blobs',
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
      _logger?.info('Deleted offline audio blob for $trackId', tag: 'OfflineAudioStorage');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(trackId);
      final file = File('${appDir.path}/downloads/$safeId.m4a');
      if (file.existsSync()) {
        await file.delete();
        _logger?.info('Deleted offline audio file for $trackId', tag: 'OfflineAudioStorage');
      }
    }
  }

  Future<bool> isAudioDownloaded(String trackId) async {
    if (kIsWeb) {
      final db = _appDatabase.database;
      final rows = await db.query(
        'offline_audio_blobs',
        columns: ['track_id'],
        where: 'track_id = ?',
        whereArgs: [trackId],
        limit: 1,
      );
      return rows.isNotEmpty;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final safeId = safeFilename(trackId);
      final file = File('${appDir.path}/downloads/$safeId.m4a');
      return file.existsSync();
    }
  }

  void dispose() {
    if (kIsWeb) {
      for (final url in _activeBlobUrls.values) {
        WebBlobUrlHelper.revokeBlobUrl(url);
      }
      _activeBlobUrls.clear();
    }
  }
}
