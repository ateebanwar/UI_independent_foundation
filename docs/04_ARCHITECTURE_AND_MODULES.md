# Echo Bloom — Architecture and Modules Specification

## 1. Architectural Philosophy

Echo Bloom is designed as a **strictly UI-independent, headless audio player foundation** following Domain-Driven Design (DDD) and Clean Architecture principles. Any presentation layer (mobile UI, desktop UI, headless CLI, or background service) can bind directly to the documented public Riverpod providers and repository contracts without altering underlying business rules.

```mermaid
flowchart TD
    subgraph UI Layer ["Future UI Layer (Independent)"]
        CustomScreens["Custom Views / Widgets / Miniplayers"]
    end

    subgraph Presentation Layer ["State Management (Riverpod)"]
        PlayCtrl["PlaybackController"]
        SearchCtrl["SearchController"]
        ReleaseCtrl["ReleasesController"]
        DownCtrl["DownloadController"]
        HistCtrl["HistoryController"]
        EqCtrl["EqualizerController"]
    end

    subgraph Domain Layer ["Domain Layer (Pure Dart)"]
        Entities["Entities (Track, SyncRelease, PlaybackState, UserProfile)"]
        RepoContracts["Repository Interfaces (Playback, Track, Releases, History)"]
        ResultMonad["Result<T, Failure> & Error Types"]
    end

    subgraph Data Layer ["Data Layer"]
        RepoImpls["Repository Implementations"]
        LocalDS["Local SQLite DataSources"]
        RemoteDS["Remote Music DataSources (JioSaavn, Gaana)"]
        Mappers["Mappers & Data Transfer Objects"]
    end

    subgraph Infrastructure Layer ["Infrastructure Layer"]
        AudioEng["AudioEngine & Low-Level DSP Pipeline"]
        NetClient["ResilientHttpClient (Retry, Rate-Limit, Cache)"]
        SQLiteDB["AppDatabase & Versioned Migrations (V1-V4)"]
        FileStorage["OfflineAudioStorage (File System)"]
    end

    CustomScreens --> Presentation Layer
    Presentation Layer --> Domain Layer
    Data Layer --> Domain Layer
    Presentation Layer --> Data Layer
    Data Layer --> Infrastructure Layer
```

---

## 2. Layer Breakdown & Boundaries

### 2.1 Domain Layer (`lib/domain/`)
- Contains 100% pure Dart business models and repository contracts.
- **Entities**: [`Track`](file:///d:/FLutter/redesign%20UI/lib/domain/entities/track.dart), [`SyncRelease`](file:///d:/FLutter/redesign%20UI/lib/domain/entities/sync_release.dart), [`PlaybackState`](file:///d:/FLutter/redesign%20UI/lib/domain/entities/playback_state.dart), [`UserProfile`](file:///d:/FLutter/redesign%20UI/lib/domain/entities/user_profile.dart), [`EqualizerConfiguration`](file:///d:/FLutter/redesign%20UI/lib/domain/entities/equalizer_configuration.dart).
- **Contracts**: [`PlaybackRepository`](file:///d:/FLutter/redesign%20UI/lib/domain/repositories/playback_repository.dart), [`TrackRepository`](file:///d:/FLutter/redesign%20UI/lib/domain/repositories/track_repository.dart), [`SyncReleasesRepository`](file:///d:/FLutter/redesign%20UI/lib/domain/repositories/sync_releases_repository.dart), [`HistoryRepository`](file:///d:/FLutter/redesign%20UI/lib/domain/repositories/history_repository.dart).
- **Rules**: Zero imports from Flutter widgets, SQLite, or networking packages.

### 2.2 Data Layer (`lib/data/`)
- Implements domain contracts using SQLite data sources, remote HTTP clients, and local file storage.
- **Local Data Sources**: [`LocalTrackDataSource`](file:///d:/FLutter/redesign%20UI/lib/data/local/data_sources/local_track_data_source.dart), [`LocalHistoryDataSource`](file:///d:/FLutter/redesign%20UI/lib/data/local/data_sources/local_history_data_source.dart), [`LocalSyncReleasesDataSource`](file:///d:/FLutter/redesign%20UI/lib/data/local/data_sources/local_sync_releases_data_source.dart).
- **Remote Data Sources**: [`JioSaavnClient`](file:///d:/FLutter/redesign%20UI/lib/data/remote/clients/jiosaavn_client.dart), [`GaanaClient`](file:///d:/FLutter/redesign%20UI/lib/data/remote/clients/gaana_client.dart).
- **Database**: [`AppDatabase`](file:///d:/FLutter/redesign%20UI/lib/data/local/database/app_database.dart), [`DatabaseMigrator`](file:///d:/FLutter/redesign%20UI/lib/data/local/database/database_migrator.dart), [`DatabaseBackupService`](file:///d:/FLutter/redesign%20UI/lib/data/local/database/database_backup_service.dart).

### 2.3 Infrastructure Layer (`lib/infrastructure/`)
- Handles low-level platform APIs and driver abstractions.
- **Audio Engine**: [`AudioEngine`](file:///d:/FLutter/redesign%20UI/lib/infrastructure/audio/audio_engine.dart) and [`AudioEngineImpl`](file:///d:/FLutter/redesign%20UI/lib/infrastructure/audio/audio_engine_impl.dart). Decoupled from concrete packages (`just_audio`, `audioplayers`) so audio driver changes require zero modifications in the domain or controller layers.
- **Networking**: [`ResilientHttpClient`](file:///d:/FLutter/redesign%20UI/lib/infrastructure/networking/resilient_http_client.dart) with backoff retry, rate-limit protection, and parameter redaction.
- **Storage**: [`OfflineAudioStorage`](file:///d:/FLutter/redesign%20UI/lib/infrastructure/storage/offline_audio_storage.dart).

### 2.4 Feature Controllers (`lib/features/`)
- Riverpod `StateNotifier` controllers orchestrating business logic and exposing immutable UI states.
- Controllers include `PlaybackController`, `SearchController`, `ReleasesController`, `DownloadController`, `HistoryController`, `EqualizerController`, and `FavoritesController`.

### 2.5 Public Foundation Entry Point (`lib/echo_bloom_foundation.dart`)
- Clean public facade exporting all necessary entities, repository contracts, providers, and database services so external UI modules need only one import:
  ```dart
  import 'package:echo_bloom/echo_bloom_foundation.dart';
  ```
