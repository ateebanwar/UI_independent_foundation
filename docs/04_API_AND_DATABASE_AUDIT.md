# 04. API AND DATABASE AUDIT: SCHEMAS, PROTOCOLS, AND LIVE STATUS

**Project**: Echo Bloom (UI-Independent Foundation Reconstruction)  
**Reference Workspace**: `d:\FLutter\project` (READ-ONLY)  
**Target Workspace**: `d:\FLutter\redesign UI` (WRITABLE)  
**Date**: November 2026  

---

## 1. Local SQLite Database Architecture

Echo Bloom operates on a **strictly local-first** persistence model. There are zero cloud databases, zero external authentication servers, and zero mandatory network sync requirements.

### 1.1 Schema Evolution and Migration History

The schema is governed by `DatabaseMigrator`, which executes discrete, versioned migration classes inside atomic SQLite transactions.

#### Version 1 (`V1InitialSchema`)
* **`tracks`**:
  * `id TEXT PRIMARY KEY`
  * `title TEXT NOT NULL`, `artist TEXT NOT NULL`, `album TEXT`
  * `duration_ms INTEGER NOT NULL`
  * `media_uri TEXT NOT NULL UNIQUE` (file path, content URI, or streaming URL)
  * `source_type INTEGER NOT NULL DEFAULT 0` (0: local, 1: downloaded, 2: remoteStream)
  * `artwork_uri TEXT`, `track_number INTEGER`, `disc_number INTEGER`, `year INTEGER`, `genre TEXT`, `bit_rate INTEGER`, `sample_rate INTEGER`, `file_size INTEGER NOT NULL DEFAULT 0`
  * `date_added INTEGER NOT NULL`, `date_modified INTEGER`
  * `is_favorite INTEGER NOT NULL DEFAULT 0`
  * **Indexes**: `idx_tracks_title`, `idx_tracks_artist`, `idx_tracks_album`, `idx_tracks_is_favorite`, `idx_tracks_date_added`.
* **`playlists`**:
  * `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `description TEXT`, `artwork_uri TEXT`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`, `is_smart INTEGER NOT NULL DEFAULT 0`
  * **Index**: `idx_playlists_name`.
* **`playlist_items`**:
  * `playlist_id TEXT NOT NULL`, `track_id TEXT NOT NULL`, `position INTEGER NOT NULL`, `added_at INTEGER NOT NULL`
  * Composite PK: `(playlist_id, track_id)`
  * Foreign Keys: `ON DELETE CASCADE` on both `playlist_id` and `track_id`.
  * **Index**: `idx_playlist_items_order` on `(playlist_id, position ASC)`.
* **`playback_history`**:
  * `id TEXT PRIMARY KEY`, `track_id TEXT NOT NULL`, `played_at INTEGER NOT NULL`, `played_duration_ms INTEGER NOT NULL`, `completed INTEGER NOT NULL DEFAULT 0`
  * FK: `track_id REFERENCES tracks(id) ON DELETE CASCADE`.
  * **Indexes**: `idx_history_played_at`, `idx_history_track_id`.
* **`key_value_store`**:
  * `key TEXT PRIMARY KEY`, `value_text TEXT`, `value_int INTEGER`, `value_real REAL`, `value_type TEXT NOT NULL`.

#### Version 2 (`V2OnlineTracksSchema`)
* Adds metadata columns to `tracks` for remote provider identification and stream resolution:
  * `ALTER TABLE tracks ADD COLUMN remote_provider TEXT;` ('jiosaavn' or 'gaana')
  * `ALTER TABLE tracks ADD COLUMN remote_provider_id TEXT;`
  * `ALTER TABLE tracks ADD COLUMN remote_perma_url TEXT;`

#### Version 3 (`V3DownloadedPlaylistsSchema`)
* **`downloaded_playlists`**:
  * `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `description TEXT`, `artwork_uri TEXT`, `source_type TEXT NOT NULL DEFAULT 'curated'`, `remote_id TEXT`, `total_tracks INTEGER NOT NULL DEFAULT 0`, `downloaded_tracks INTEGER NOT NULL DEFAULT 0`, `status TEXT NOT NULL DEFAULT 'downloaded'`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`
  * **Index**: `idx_dl_playlists_created`.
* **`downloaded_playlist_items`**:
  * `playlist_id TEXT NOT NULL`, `track_id TEXT NOT NULL`, `position INTEGER NOT NULL`, `download_status TEXT NOT NULL DEFAULT 'completed'`
  * Composite PK: `(playlist_id, track_id)` with `ON DELETE CASCADE`.
  * **Indexes**: `idx_dl_items_order`, `idx_dl_items_track`.
* **`offline_audio_blobs`** (Web / Edge persistent audio storage):
  * `track_id TEXT PRIMARY KEY`, `audio_data BLOB NOT NULL`, `mime_type TEXT NOT NULL DEFAULT 'audio/mp4'`, `file_size INTEGER NOT NULL`, `saved_at INTEGER NOT NULL`.

### 1.2 Desktop Persistence Remediation
In the original implementation:
```dart
} else if (defaultTargetPlatform == TargetPlatform.windows || ...) {
  sqfliteFfiInit();
  factory = customFactory ?? databaseFactoryFfi;
  dbPath = inMemoryDatabasePath; // CRITICAL FLAW: wiped on every exit
}
```
In the reconstructed foundation, desktop persistence uses `path_provider` to resolve the application support directory:
```dart
final appDir = await getApplicationSupportDirectory();
final dbDir = Directory(p.join(appDir.path, 'databases'));
if (!dbDir.existsSync()) await dbDir.create(recursive: true);
dbPath = p.join(dbDir.path, _databaseName);
```
Data now survives application restart on Windows desktop.

---

## 2. Remote Music APIs Audit & Live Verification

### 2.1 JioSaavn API
* **Base URL**: `https://saavnapi-nine.vercel.app`
* **Live Status**: **OPERATIONAL** (HTTP 200 confirmed during audit testing).
* **Endpoints**:
  * Search: `GET /result/?query=<ENCODED_QUERY>`
  * Album: `GET /album/?query=<ALBUM_URL_OR_ID>`
  * Song Details: `GET /song/?query=<PERMA_URL>`
  * Lyrics: `GET /lyrics/?query=<SONG_ID_OR_PERMA_URL>`
* **Response Characteristics**:
  * Returns JSON containing array of song objects with fields `id`, `song` (title), `singers` / `primary_artists`, `album`, `image`, `media_url` (direct AAC/MP4 320kbps or 160kbps stream), `has_lyrics`, `duration`, and `perma_url`.
  * String fields contain HTML entities (`&quot;`, `&#039;`, `&amp;`), requiring `unescapeHtml` normalization.
* **Lyrics Discovery**:
  * Live testing during audit confirmed:
    ```
    GET https://saavnapi-nine.vercel.app/lyrics/?query=https://www.jiosaavn.com/song/tum-hi-ho/EToxUyFpcwQ
    Response: { "lyrics": "Hum Tere Bin Ab Reh Nahi Sakte<br>Tere Bina Kya Wajood Mera...", "status": true }
    ```
  * The reference project never wired this up, leaving `DefaultLyricsService` as an empty stub. The reconstructed foundation connects directly to this endpoint.

### 2.2 Gaana API
* **Base URL**: `https://shnwazdev-gaana-api.vercel.app`
* **Live Status**: **UNAVAILABLE / DEPLOYMENT DISABLED**
  * HTTP Test Result: `HTTP 402 Payment Required: DEPLOYMENT_DISABLED` (Vercel deployment suspended due to account/plan status).
* **Endpoints (Contract Reference)**:
  * Search: `GET /api/search?q=<QUERY>&type=song`
  * Stream: `GET /api/stream?seokey=<SEOKEY>`
* **Architectural Handling**:
  * We preserve all contracts and data client models for Gaana as required by Directive Section 6.2.
  * In accordance with Directive Section 6.3, we do NOT fabricate responses.
  * `RemoteMusicDataSourceImpl` catches network/HTTP failures from Gaana gracefully and falls back to JioSaavn or returns clean error results without crashing.

---

## 3. Storage Subsystem & Directory Layout

### Native Device Directories (Android & Windows)
* **Database File**: `<AppSupportDir>/databases/sound_foundry.db`
* **Offline Audio Files**: `<AppDocumentsDir>/downloads/<safe_track_id>.m4a`
* **Artwork Cache**: `<TemporaryDir>/art_cache/<track_id>.jpg`

### Web Browser Storage (Edge / Chrome)
* **IndexedDB**:
  * SQLite DB file mapped into IndexedDB via `sqflite_common_ffi_web`.
  * Audio binary payloads stored in `offline_audio_blobs` table as raw binary BLOBs and converted on playback to ephemeral Object URLs via `URL.createObjectURL(blob)`.
