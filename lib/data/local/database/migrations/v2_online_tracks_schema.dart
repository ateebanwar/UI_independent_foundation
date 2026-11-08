import 'package:echo_bloom/data/local/database/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Schema migration: version 2.
class V2OnlineTracksSchema implements Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    await db.execute('ALTER TABLE tracks ADD COLUMN remote_provider TEXT;');
    await db.execute('ALTER TABLE tracks ADD COLUMN remote_provider_id TEXT;');
    await db.execute('ALTER TABLE tracks ADD COLUMN remote_perma_url TEXT;');
  }

  @override
  Future<void> down(Database db) async {
    // SQLite does not support DROP COLUMN in legacy environments; no-op for down
  }
}
