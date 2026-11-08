import 'dart:convert';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// Service responsible for local SQLite database backups, restores, and integrity verification.
class DatabaseBackupService {
  final AppDatabase _appDatabase;
  final AppLogger? _logger;

  DatabaseBackupService({
    required AppDatabase appDatabase,
    AppLogger? logger,
  })  : _appDatabase = appDatabase,
        _logger = logger;

  Database get _db => _appDatabase.database;

  /// Verifies SQLite B-tree and relational integrity.
  Future<Result<bool, Failure>> verifyIntegrity() async {
    try {
      final rows = await _db.rawQuery('PRAGMA integrity_check;');
      final status = rows.isNotEmpty ? rows.first.values.first.toString() : '';
      final isOk = status.toLowerCase() == 'ok';
      _logger?.info('Database integrity check result: $status', tag: 'DatabaseBackupService');
      return Result.ok(isOk);
    } catch (e, stack) {
      _logger?.error('Database integrity check failed: $e', tag: 'DatabaseBackupService', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Integrity check error: $e', cause: e));
    }
  }

  /// Exports local user data (playlists, items, favorites, listening history, play counts) to JSON string.
  Future<Result<String, Failure>> exportBackup() async {
    try {
      final tracks = await _db.query('tracks');
      final playlists = await _db.query('playlists');
      final playlistItems = await _db.query('playlist_items');
      final history = await _db.query('playback_history');
      final sessions = await _db.query('listening_sessions');
      final playCounts = await _db.query('play_counts');
      final settings = await _db.query('key_value_store');

      final backupData = {
        'version': 4,
        'exported_at': DateTime.now().toIso8601String(),
        'tracks': tracks,
        'playlists': playlists,
        'playlist_items': playlistItems,
        'playback_history': history,
        'listening_sessions': sessions,
        'play_counts': playCounts,
        'key_value_store': settings,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      _logger?.info('Successfully exported database backup (${jsonStr.length} bytes)', tag: 'DatabaseBackupService');
      return Result.ok(jsonStr);
    } catch (e, stack) {
      _logger?.error('Error exporting database backup: $e', tag: 'DatabaseBackupService', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to export database backup: $e', cause: e));
    }
  }

  /// Restores user data from JSON string within an atomic transaction.
  Future<Result<int, Failure>> importBackup(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Result.err(StorageFailure(message: 'Invalid backup format: root must be a JSON object'));
      }

      int restoredCount = 0;
      await _db.transaction((txn) async {
        // 1. Tracks
        if (decoded['tracks'] is List) {
          for (final item in decoded['tracks'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('tracks', item, conflictAlgorithm: ConflictAlgorithm.replace);
              restoredCount++;
            }
          }
        }

        // 2. Playlists
        if (decoded['playlists'] is List) {
          for (final item in decoded['playlists'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('playlists', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        // 3. Playlist items
        if (decoded['playlist_items'] is List) {
          for (final item in decoded['playlist_items'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('playlist_items', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        // 4. Listening sessions
        if (decoded['listening_sessions'] is List) {
          for (final item in decoded['listening_sessions'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('listening_sessions', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        // 5. Play counts
        if (decoded['play_counts'] is List) {
          for (final item in decoded['play_counts'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('play_counts', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        // 6. Key Value Store
        if (decoded['key_value_store'] is List) {
          for (final item in decoded['key_value_store'] as List) {
            if (item is Map<String, dynamic>) {
              await txn.insert('key_value_store', item, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      });

      _logger?.info('Successfully restored database backup ($restoredCount tracks)', tag: 'DatabaseBackupService');
      return Result.ok(restoredCount);
    } catch (e, stack) {
      _logger?.error('Failed to import database backup: $e', tag: 'DatabaseBackupService', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to import backup: $e', cause: e));
    }
  }
}
