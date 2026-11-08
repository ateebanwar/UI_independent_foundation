# 06. GAPS AND REMEDIATION SPECIFICATION

**Project**: Echo Bloom (UI-Independent Foundation Reconstruction)  
**Reference Workspace**: `d:\FLutter\project` (READ-ONLY)  
**Target Workspace**: `d:\FLutter\redesign UI` (WRITABLE)  
**Date**: November 2026  

---

## 1. Remediation Plan by Defect

### 1. GAP-01: Windows Desktop Audio Playback
* **Discovered Issue**: In `lib/infrastructure/audio/audio_engine_impl.dart`, when running on Windows desktop (`!kIsWeb && !Platform.isAndroid`), `play()` merely triggers `_startTicker()`. This updates a position integer every 50ms without producing actual sound.
* **Remediation**:
  * Implement `WindowsAudioEngine` using Windows Multimedia / WinMM (`winmm.dll` `mciSendStringW`) via `dart:ffi`.
  * Commands implemented:
    * `open "<path>" type mpegvideo alias player` (or waveaudio)
    * `play player`
    * `pause player`
    * `stop player`
    * `seek player to <position_ms>`
    * `setaudio player volume to <0-1000>`
    * `status player mode`, `status player position`, `status player length`
    * `close player`
  * For remote HTTP/HTTPS streaming URLs, automatically stream/cache the audio file to a temporary media cache file, enabling instant WinMM native playback on Windows.
  * Real position updates and track completion events are dispatched via the standard `AudioEngine` event streams.

### 2. GAP-02: Windows Desktop Database In-Memory Wiping
* **Discovered Issue**: In `lib/data/local/database/app_database.dart`:
  ```dart
  } else if (defaultTargetPlatform == TargetPlatform.windows || ...) {
    sqfliteFfiInit();
    factory = customFactory ?? databaseFactoryFfi;
    dbPath = inMemoryDatabasePath;
  }
  ```
  This creates a transient SQLite database in RAM. When the app exits, all user playlists, history, scanned library tracks, favorites, and settings are permanently destroyed.
* **Remediation**:
  * Use `path_provider` (`getApplicationSupportDirectory()`) on Windows desktop:
    ```dart
    final supportDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(supportDir.path, 'databases'));
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }
    dbPath = p.join(dbDir.path, _databaseName);
    ```
  * Verified database persistence: tracks, playlists, favorites, and settings survive application restarts.

### 3. GAP-03: Equalizer Signal Processing
* **Discovered Issue**: `EqualizerController` stores 5 band gains in SQLite via `EqualizerRepositoryImpl`, but `AudioEngineImpl` does not send these gains to any audio processing hardware or software filter. The equalizer has zero acoustic effect.
* **Remediation**:
  * **Android**: Update `MainActivity.kt` and `MediaPlaybackService.kt` to bind to `android.media.audiofx.Equalizer(0, mediaPlayer.audioSessionId)`. Connect MethodChannel calls `setEqualizerGains` and `setEqualizerEnabled` directly to the native audio session.
  * **Web**: In `WebAudioPlayer`, construct a Web Audio API audio graph with 5 cascading `BiquadFilterNode`s (60Hz lowshelf, 230Hz peaking, 910Hz peaking, 3.6kHz peaking, 14kHz highshelf) connected between the `HTMLAudioElement` source node and `AudioContext.destination`.
  * **Capability Reporting**: Expose `EqualizerCapabilities` (supported bands, min/max gain in dB, hardware vs software filter) so client UIs know whether active audio processing is supported on the running platform.

### 4. GAP-04: Download Architecture Consolidation
* **Discovered Issue**: The codebase contains duplicate directories:
  * `lib/features/download/download_controller.dart`: Functional controller that downloads songs, saves files, updates SQLite, and manages playlist downloads.
  * `lib/features/downloads/downloads_contract.dart`: Abstract `DownloadManager` with `DefaultDownloadManager` returning empty stubs.
* **Remediation**:
  * Unify both under `lib/features/downloads/`:
    * `downloads_contract.dart`: Defines `DownloadManager`, `DownloadTask`, `DownloadStatus`.
    * `download_manager_impl.dart`: Implements `DownloadManager` with a real streaming HTTP download pipeline, concurrency limiter, disk persistence, and progress streams.
    * `download_controller.dart`: StateNotifier providing reactive `DownloadState` for UI observation.
  * Eliminate the dead placeholder `DefaultDownloadManager`.

### 5. GAP-05: Lyrics Subsystem Implementation
* **Discovered Issue**: `DefaultLyricsService` in `lib/features/lyrics/lyrics_contract.dart` returns empty `Result.ok(Lyrics(trackId: trackId))` without attempting to fetch lyrics.
* **Remediation**:
  * The investigation proved that the deployed JioSaavn API has an active lyrics endpoint:
    `GET https://saavnapi-nine.vercel.app/lyrics/?query=<SONG_ID_OR_PERMA_URL>`
  * Implement `JioSaavnLyricsProvider` implementing `LyricsProvider`.
  * In `LyricsServiceImpl`:
    1. Check track metadata: if `track.remotePermaUrl` or `track.remoteProviderId` exists, query the JioSaavn lyrics endpoint.
    2. Normalize text: unescape HTML entities (`&quot;`, `&amp;`), replace `<br>` tags with newlines, trim whitespace.
    3. Parse synchronized lyrics: detect timestamps in format `[mm:ss.xx] line text` and build `List<LyricLine>`.
    4. Implement an in-memory cache to prevent duplicate HTTP queries.
    5. Handle offline or unavailable lyrics with clear `Failure` states.

### 6. GAP-06: Gaana API Outage Handling
* **Discovered Issue**: `https://shnwazdev-gaana-api.vercel.app` returns `HTTP 402 Payment Required: DEPLOYMENT_DISABLED`.
* **Remediation**:
  * Retain `GaanaClient` and `GaanaProvider` contracts to satisfy Directive Section 6.2.
  * Ensure `RemoteMusicDataSourceImpl` catches HTTP 402 / non-200 responses cleanly with a timeout, logs the status, and falls back to JioSaavn without stalling the user's search or crashing the application.

### 7. GAP-07 & GAP-08: UI Decoupling and Router Infrastructure
* **Discovered Issue**: `DefaultAppRouter` returns `null` for `onGenerateRoute`. Navigation was tightly coupled to screens inside `EntryGate` and `MainNavigationShell`.
* **Remediation**:
  * Create a clean, screen-independent navigation infrastructure in `lib/app/routing/`:
    * Typed route definitions (`LibraryRoute`, `PlayerRoute`, `PlaylistDetailRoute(playlistId)`, `ArtistDetailRoute(artistName)`).
    * Screen-agnostic route handler contract that allows any future UI system (Material, Cupertino, Neumorphic, Custom) to bind its own visual builders without changing core contracts.
  * Decouple all feature state notifiers: ensure no controller imports `BuildContext`, `Widget`, or visual styling.
