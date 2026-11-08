import 'package:echo_bloom/data/local/database/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Schema migration: version 4.
/// Introduces YouTube-style listening sessions, dedicated play counts,
/// synchronized releases, and persistent download queue state.
class V4AdvancedFoundationSchema implements Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    // 1. YouTube-style listening sessions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS listening_sessions (
        id TEXT PRIMARY KEY,
        track_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        artwork_uri TEXT,
        source_type INTEGER NOT NULL,
        remote_provider TEXT,
        played_at INTEGER NOT NULL,
        duration_listened_ms INTEGER NOT NULL,
        track_duration_ms INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_played_at ON listening_sessions(played_at DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_track_id ON listening_sessions(track_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_title ON listening_sessions(title COLLATE NOCASE);');

    // 2. Dedicated play counts and last played table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS play_counts (
        track_id TEXT PRIMARY KEY,
        play_count INTEGER NOT NULL DEFAULT 1,
        last_played_at INTEGER NOT NULL,
        total_listened_ms INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_play_counts_count ON play_counts(play_count DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_play_counts_last_played ON play_counts(last_played_at DESC);');

    // 3. Sync Releases collections table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_releases (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        release_date TEXT,
        release_type TEXT NOT NULL DEFAULT 'album',
        artwork_uri TEXT,
        track_count INTEGER NOT NULL DEFAULT 0,
        synced_at INTEGER NOT NULL,
        remote_provider TEXT NOT NULL DEFAULT 'jiosaavn',
        remote_url TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_releases_date ON sync_releases(release_date DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_releases_synced ON sync_releases(synced_at DESC);');

    // 4. Sync Release Tracks junction table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_release_tracks (
        release_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (release_id, track_id),
        FOREIGN KEY (release_id) REFERENCES sync_releases(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_release_tracks_order ON sync_release_tracks(release_id, position ASC);');

    // 5. Download tasks queue table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS download_tasks (
        track_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        media_uri TEXT NOT NULL,
        artwork_uri TEXT,
        status TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0.0,
        bytes_downloaded INTEGER NOT NULL DEFAULT 0,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dl_tasks_status ON download_tasks(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_dl_tasks_created ON download_tasks(created_at ASC);');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS download_tasks;');
    await db.execute('DROP TABLE IF EXISTS sync_release_tracks;');
    await db.execute('DROP TABLE IF EXISTS sync_releases;');
    await db.execute('DROP TABLE IF EXISTS play_counts;');
    await db.execute('DROP TABLE IF EXISTS listening_sessions;');
  }
}

