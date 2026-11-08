# 05. MIGRATION MATRIX: SUBSYSTEM TRACEABILITY

**Project**: Echo Bloom (UI-Independent Foundation Reconstruction)  
**Reference Workspace**: `d:\FLutter\project` (READ-ONLY)  
**Target Workspace**: `d:\FLutter\redesign UI` (WRITABLE)  
**Date**: November 2026  

---

## 1. Migration Traceability Matrix

| Component | Original Source (`project/`) | Destination (`redesign UI/`) | Migration Type | Dependencies | Status | Test Status | Notes |
|---|---|---|---|---|---|---|---|
| **App Bootstrap** | `lib/app/bootstrap/bootstrap.dart` | `lib/app/bootstrap/bootstrap.dart` | Adaptation | Riverpod, Config, DB, Logger | Planned | Pending | Adapt for UI-independent startup |
| **Dependency Bootstrap** | `lib/app/bootstrap/dependency_bootstrap.dart` | `lib/app/bootstrap/dependency_bootstrap.dart` | Adaptation | All layers | Planned | Pending | Add unified download and lyrics providers |
| **Environment Bootstrap** | `lib/app/bootstrap/environment_bootstrap.dart` | `lib/app/bootstrap/environment_bootstrap.dart` | Direct | Config | Planned | Pending | Preserve build config & feature flags |
| **App & Build Config** | `lib/app/config/*` | `lib/app/config/*` | Direct | None | Planned | Pending | Preserve config and endpoints |
| **Startup Coordinator** | `lib/app/startup/*` | `lib/app/startup/*` | Direct | Logging | Planned | Pending | Preserve priority task pipeline |
| **Navigation Router** | `lib/app/routing/app_router.dart` | `lib/app/routing/app_router.dart` | Reconstruction | Widgets, Navigator | Planned | Pending | Replace stub with typed route contracts |
| **Core Result Monad** | `lib/core/result/result.dart` | `lib/core/result/result.dart` | Direct | Equatable | Planned | Pending | Preserve sealed Result class |
| **Core Failures** | `lib/core/errors/failures.dart` | `lib/core/errors/failures.dart` | Direct | Equatable | Planned | Pending | Preserve typed failure hierarchy |
| **Core AppExceptions** | `lib/core/errors/app_exception.dart` | `lib/core/errors/app_exception.dart` | Direct | None | Planned | Pending | Preserve exception classes |
| **Core Logger** | `lib/core/logging/*` | `lib/core/logging/*` | Direct | None | Planned | Pending | Preserve console logger & contract |
| **Core Time & Clock** | `lib/core/time/clock.dart` | `lib/core/time/clock.dart` | Direct | None | Planned | Pending | Preserve deterministic clock |
| **Core Pagination** | `lib/core/types/pagination.dart` | `lib/core/types/pagination.dart` | Direct | Equatable | Planned | Pending | Preserve PageQuery & PaginatedList |
| **Core Constants** | `lib/core/constants/*` | `lib/core/constants/*` | Direct | None | Planned | Pending | Storage keys and constants |
| **Domain Entities** | `lib/domain/entities/*` (11 files) | `lib/domain/entities/*` | Direct | Equatable | Planned | Pending | Pure business entities without UI |
| **Repository Contracts** | `lib/domain/repositories/*` (7 files) | `lib/domain/repositories/*` | Direct | Entities, Result | Planned | Pending | Pure domain interfaces |
| **Database Migrator** | `lib/data/local/database/database_migrator.dart` | `lib/data/local/database/database_migrator.dart` | Direct | Sqflite | Planned | Pending | Preserve atomic versioned migrations |
| **Database Migrations** | `lib/data/local/database/migrations/*` (v1-v3) | `lib/data/local/database/migrations/*` | Direct | Sqflite | Planned | Pending | Preserve schemas v1, v2, and v3 |
| **SQLite AppDatabase** | `lib/data/local/database/app_database.dart` | `lib/data/local/database/app_database.dart` | Reconstruction | Sqflite FFI, PathProvider | Planned | Pending | Replace in-memory path with persistent path on Windows |
| **Local Data Sources** | `lib/data/local/data_sources/*` (4 files) | `lib/data/local/data_sources/*` | Direct | Sqflite, Mappers | Planned | Pending | Tracks, playlists, history, downloads |
| **Data Mappers** | `lib/data/mappers/*` (3 files) | `lib/data/mappers/*` | Direct | Entities | Planned | Pending | DB Row <-> Entity conversion |
| **JioSaavn Client** | `lib/data/remote/clients/jiosaavn_client.dart` | `lib/data/remote/clients/jiosaavn_client.dart` | Adaptation | HTTP, Entities | Planned | Pending | Add `/lyrics/` API endpoint integration |
| **Gaana Client** | `lib/data/remote/clients/gaana_client.dart` | `lib/data/remote/clients/gaana_client.dart` | Direct | HTTP, Entities | Planned | Pending | Preserve client, handle 402 gracefully |
| **Remote Music Data Source** | `lib/data/remote/data_sources/remote_music_data_source_impl.dart` | `lib/data/remote/data_sources/remote_music_data_source_impl.dart` | Adaptation | Clients, Cache | Planned | Pending | Enhanced fallback error resilience |
| **Repositories (Data)** | `lib/data/repositories/*` (6 files) | `lib/data/repositories/*` | Adaptation | DataSources, Contracts | Planned | Pending | Connect to enhanced data sources |
| **AudioEngine Contract** | `lib/infrastructure/audio/audio_engine.dart` | `lib/infrastructure/audio/audio_engine.dart` | Direct | Entities | Planned | Pending | Audio engine abstraction |
| **AudioEngineImpl** | `lib/infrastructure/audio/audio_engine_impl.dart` | `lib/infrastructure/audio/audio_engine_impl.dart` | Reconstruction | Platform channels, Web, WinMM | Planned | Pending | Implement real Windows audio and DSP equalizer |
| **Android MediaPlayer Service** | `android/.../MainActivity.kt` & `MediaPlaybackService.kt` | `android/.../MainActivity.kt` & `MediaPlaybackService.kt` | Adaptation | Kotlin, Android SDK | Planned | Pending | Add android.media.audiofx Equalizer |
| **Web Audio Driver** | `lib/infrastructure/audio/web_audio_player_web.dart` | `lib/infrastructure/audio/web_audio_player_web.dart` | Adaptation | package:web | Planned | Pending | Connect Web Audio BiquadFilterNode chain |
| **Media Scanner** | `lib/infrastructure/platform/media_scanner.dart` | `lib/infrastructure/platform/media_scanner.dart` | Direct | Platform channel, IO | Planned | Pending | MediaStore & directory scanning |
| **Key-Value & Audio Storage** | `lib/infrastructure/storage/*` | `lib/infrastructure/storage/*` | Direct | SQLite, IO | Planned | Pending | KV store and offline audio storage |
| **Library Feature** | `lib/features/library/*` | `lib/features/library/*` | Direct | Repositories, Riverpod | Planned | Pending | Library state notifier & providers |
| **Playback Feature** | `lib/features/playback/*` | `lib/features/playback/*` | Direct | AudioEngine, Queue | Planned | Pending | Playback repository and queue logic |
| **Playlists Feature** | `lib/features/playlists/*` | `lib/features/playlists/*` | Direct | Repositories, Riverpod | Planned | Pending | Playlist controller & providers |
| **Favorites Feature** | `lib/features/favorites/*` | `lib/features/favorites/*` | Direct | Repositories, Riverpod | Planned | Pending | Favorites controller & providers |
| **Search Feature** | `lib/features/search/*` | `lib/features/search/*` | Direct | Repositories, Riverpod | Planned | Pending | Search controller & categories |
| **History Feature** | `lib/features/history/*` | `lib/features/history/*` | Direct | Repositories, Riverpod | Planned | Pending | History controller & providers |
| **Settings Feature** | `lib/features/settings/*` | `lib/features/settings/*` | Direct | Repositories, Riverpod | Planned | Pending | Settings controller & providers |
| **Profile Feature** | `lib/features/profile/*` | `lib/features/profile/*` | Direct | Repositories, Riverpod | Planned | Pending | Profile controller & providers |
| **Equalizer Feature** | `lib/features/equalizer/*` | `lib/features/equalizer/*` | Adaptation | AudioEngine, Repositories | Planned | Pending | Wire to real DSP audio engine |
| **Download Subsystem** | `lib/features/download/*` & `downloads/*` | `lib/features/downloads/*` | Reconstruction | Repositories, Storage | Planned | Pending | Consolidate duplicate controllers |
| **Lyrics Subsystem** | `lib/features/lyrics/*` | `lib/features/lyrics/*` | Reconstruction | JioSaavnClient, Entities | Planned | Pending | Replace stub with real lyrics provider |
| **Presentation Screens** | `lib/presentation/screens/*` | *Excluded from Core* | Exclusion | Flutter Widgets | Excluded | N/A | UI deliberately excluded per directive |
