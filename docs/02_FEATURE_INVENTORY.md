# 02. FEATURE INVENTORY: ECHO BLOOM SUBSYSTEMS

**Project**: Echo Bloom (UI-Independent Foundation Reconstruction)  
**Reference Workspace**: `d:\FLutter\project` (READ-ONLY)  
**Target Workspace**: `d:\FLutter\redesign UI` (WRITABLE)  
**Date**: November 2026  

---

## 1. Subsystem Catalog

This inventory documents all features discovered across the reference implementation source code. Every capability listed must be migrated, reconstructed, or remediated in the new independent foundation.

| Subsystem | Primary Controller / Service | Original Status | Action in Reconstructed Foundation |
|---|---|---|---|
| **1. Application Bootstrap & Config** | `AppBootstrap`, `StartupCoordinator` | Functional | Preserve & enhance with multiplatform readiness |
| **2. Local SQLite Persistence** | `AppDatabase`, `DatabaseMigrator` | Functional (Desktop Flawed) | Preserve schema v1-v3, fix Windows persistent storage |
| **3. Media Scanning & Tag Extraction** | `DefaultMediaScanner`, `AudioMetadataExtractor` | Functional | Preserve Android MediaStore + Desktop directory scanner |
| **4. Local Music Library** | `LibraryController`, `LocalTrackDataSource` | Functional | Decouple from UI, preserve pagination & sorting |
| **5. Playback Management & Queue** | `PlaybackRepositoryImpl`, `PlaybackQueue` | Functional | Preserve queue logic, shuffle, repeat, transitions |
| **6. Android Native Audio** | `MainActivity.kt`, `MediaPlaybackService.kt` | Functional | Preserve Kotlin service, add native audiofx Equalizer |
| **7. Web Audio Engine** | `WebAudioPlayer`, `AudioEngineImpl` | Functional | Preserve HTMLAudioElement, add Web Audio Equalizer |
| **8. Windows Desktop Audio** | `AudioEngineImpl` (`_startTicker`) | **Simulated / Flawed** | **Reconstruct real native Windows audio playback** |
| **9. Favorites Management** | `FavoritesController`, `TrackRepositoryImpl` | Functional | Preserve toggle, persistence, fast indexing |
| **10. Playlist Management** | `PlaylistController`, `PlaylistRepositoryImpl` | Functional | Preserve CRUD, reordering, duplicate prevention |
| **11. Playback History & Stats** | `HistoryController`, `HistoryRepositoryImpl` | Functional | Preserve logging, most-played analytics, clearing |
| **12. Multi-Provider Search** | `SearchController`, `RemoteMusicDataSourceImpl` | Functional | Preserve categories, local+remote search, debounce |
| **13. JioSaavn Online Music** | `JioSaavnClient`, `JioSaavnProvider` | Functional | Preserve search, album fetch, stream resolution |
| **14. Gaana Online Music** | `GaanaClient`, `GaanaProvider` | Disabled upstream (402) | Preserve contract & client, add robust error handling |
| **15. Download Manager** | `DownloadController` / `DefaultDownloadManager` | **Duplicated / Partial** | **Consolidate into unified, observable DownloadManager** |
| **16. Equalizer** | `EqualizerController`, `EqualizerRepositoryImpl` | **Simulated / Flawed** | **Implement genuine multi-band DSP audio filtering** |
| **17. Lyrics Subsystem** | `DefaultLyricsService`, `trackLyricsFamilyProvider` | **Placeholder** | **Implement real JioSaavn lyrics retrieval & parsing** |
| **18. User Preferences & Settings** | `SettingsController`, `SettingsRepositoryImpl` | Functional | Preserve theme, app mode, repeat, shuffle persistence |
| **19. User Profile & Onboarding** | `ProfileController`, `UserProfileRepositoryImpl` | Functional | Preserve profile setup, avatar selection, completion |
| **20. Navigation Infrastructure** | `AppRouter`, `DefaultAppRouter` | **Placeholder** | **Implement typed, decoupled, screen-agnostic router** |

---

## 2. Detailed Subsystem Specifications

### 2.1 Local Music Library
* **Domain Models**: `Track`, `Artist`, `Album`, `PaginatedList<Track>`, `PageQuery`.
* **State**: `LibraryState` (`tracks`, `artists`, `albums`, `isLoading`, `errorMessage`).
* **Operations**: `loadLibrary()`, `rescanLibrary()`, `loadMoreTracks()`.
* **Persistence**: SQLite `tracks` table with compound indexes on `title`, `artist`, `album`, `is_favorite`, `date_added`.
* **Remediation**: Expose pure Dart streams and async methods without presentation assumptions.

### 2.2 Playback Subsystem
* **Domain Models**: `PlaybackState`, `PlaybackQueue`, `Track`, `PlaybackStatus`, `RepeatMode`.
* **State**: Observable `PlaybackState` stream (status, currentTrack, position, duration, volume, speed, repeatMode, shuffle).
* **Operations**: `load(track)`, `play()`, `pause()`, `stop()`, `seek(position)`, `setVolume(volume)`, `setSpeed(speed)`, `skipToNext()`, `skipToPrevious()`, `setQueue(tracks, initialIndex)`, `addToQueue(tracks)`, `toggleShuffle()`, `cycleRepeatMode()`.
* **Lifecycle**: Handles audio interruptions, notification actions, track completions, and automatic queue progression.

### 2.3 Audio Equalizer
* **Domain Models**: `EqualizerConfiguration`, `EqualizerPreset`.
* **State**: `EqualizerState` (`isLoading`, `configuration`).
* **Bands**: 5 frequency bands: 60 Hz, 230 Hz, 910 Hz, 3,600 Hz, 14,000 Hz.
* **Gain Range**: -12.0 dB to +12.0 dB (clamped).
* **Presets**: Flat, Rock, Pop, Jazz, Classical, Vocal Boost, Bass Boost, Custom.
* **Remediation Required**: Connect equalizer gains to real platform DSP pipelines (Android `android.media.audiofx.Equalizer` and Web `BiquadFilterNode` chain) and report explicit platform capabilities.

### 2.4 Offline Download Manager
* **Domain Models**: `DownloadedPlaylist`, `Track`, `DownloadState`, `DownloadTask`, `DownloadStatus`.
* **State**: Active downloading track IDs, downloading playlist IDs, playlist progress strings, downloaded tracks list, downloaded playlists list.
* **Operations**: `downloadTrack(track)`, `downloadPlaylist(playlist, tracks)`, `cancelPlaylistDownload(id)`, `retryPlaylistDownload(id)`, `deleteDownload(track)`, `deleteDownloadedPlaylist(id)`, `loadDownloadedContent()`.
* **Persistence**: Audio stored to local disk (native) or SQLite BLOB (web); metadata stored in `tracks`, `downloaded_playlists`, and `downloaded_playlist_items`.
* **Remediation Required**: Eliminate `DefaultDownloadManager` stub; expose unified `DownloadManager` contract backed by real download execution.

### 2.5 Lyrics Subsystem
* **Domain Models**: `Lyrics`, `LyricLine`.
* **Operations**: `getLyricsForTrack(trackId, {Track? track})`.
* **Remediation Required**: Replace `DefaultLyricsService` with a real provider architecture:
  1. Retrieve online lyrics from JioSaavn (`/lyrics/?query=<id-or-permaUrl>`).
  2. Parse HTML entities (`<br>`, `&quot;`, etc.).
  3. Support synchronized LRC timestamp parsing (`[mm:ss.xx] text`) when present.
  4. Cache retrieved lyrics in memory to prevent duplicate requests.
  5. Handle offline tracks and remote provider outages gracefully.

### 2.6 Multi-Provider Search
* **Categories**: All, Songs, Artists, Albums, Playlists.
* **Providers**: Local SQLite index (offline) + JioSaavn API + Gaana API (online fallback).
* **Debounce**: 300ms debounce timer preventing network spam.
* **State**: `SearchState` (`query`, `category`, `isSearching`, `localResults`, `remoteResults`, `artistResults`, `albumResults`, `playlistResults`, `statusMessage`, `errorMessage`).

### 2.7 User Profile & Preferences
* **Profile**: Name, date of birth, gender, avatar key, completion status.
* **Settings**: Theme mode (`light`, `dark`, `system`), app mode (`offline`, `online`), volume, audio quality, repeat mode, shuffle mode.
* **Persistence**: SQLite `key_value_store`. Zero cloud dependency.
