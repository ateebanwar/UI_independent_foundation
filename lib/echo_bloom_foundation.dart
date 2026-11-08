/// Echo Bloom — Reusable Music Player Foundation
/// Core public entry point exposing domain entities, repository contracts,
/// audio engines, database migrators, and Riverpod providers for any custom UI.
library;

// Core Monads & Types
export 'package:echo_bloom/core/errors/failures.dart';
export 'package:echo_bloom/core/logging/app_logger.dart';
export 'package:echo_bloom/core/logging/console_logger.dart';
export 'package:echo_bloom/core/result/result.dart';
export 'package:echo_bloom/core/types/pagination.dart';

// Domain Entities
export 'package:echo_bloom/domain/entities/album.dart';
export 'package:echo_bloom/domain/entities/app_mode.dart';
export 'package:echo_bloom/domain/entities/artist.dart';
export 'package:echo_bloom/domain/entities/downloaded_playlist.dart';
export 'package:echo_bloom/domain/entities/equalizer_configuration.dart';
export 'package:echo_bloom/domain/entities/equalizer_preset.dart';
export 'package:echo_bloom/domain/entities/playback_state.dart';
export 'package:echo_bloom/domain/entities/playlist.dart';
export 'package:echo_bloom/domain/entities/sync_release.dart';
export 'package:echo_bloom/domain/entities/track.dart';
export 'package:echo_bloom/domain/entities/user_profile.dart';

// Repository Contracts
export 'package:echo_bloom/domain/repositories/equalizer_repository.dart';
export 'package:echo_bloom/domain/repositories/history_repository.dart';
export 'package:echo_bloom/domain/repositories/playback_repository.dart';
export 'package:echo_bloom/domain/repositories/playlist_repository.dart';
export 'package:echo_bloom/domain/repositories/settings_repository.dart';
export 'package:echo_bloom/domain/repositories/sync_releases_repository.dart';
export 'package:echo_bloom/domain/repositories/track_repository.dart';
export 'package:echo_bloom/domain/repositories/user_profile_repository.dart';

// Audio & Infrastructure
export 'package:echo_bloom/infrastructure/audio/audio_engine.dart';
export 'package:echo_bloom/infrastructure/networking/http_client.dart';
export 'package:echo_bloom/infrastructure/networking/resilient_http_client.dart';

// Database & Migrations
export 'package:echo_bloom/data/local/database/app_database.dart';
export 'package:echo_bloom/data/local/database/database_backup_service.dart';
export 'package:echo_bloom/data/local/database/database_migrator.dart';

// Dependency Bootstrap
export 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';

// Feature Controllers & Providers
export 'package:echo_bloom/features/downloads/download_controller.dart';
export 'package:echo_bloom/features/downloads/downloads_providers.dart';
export 'package:echo_bloom/features/equalizer/equalizer_controller.dart';
export 'package:echo_bloom/features/favorites/favorites_controller.dart';
export 'package:echo_bloom/features/history/history_controller.dart';
export 'package:echo_bloom/features/library/library_controller.dart';
export 'package:echo_bloom/features/library/library_providers.dart';
export 'package:echo_bloom/features/lyrics/lyrics_contract.dart';
export 'package:echo_bloom/features/lyrics/lyrics_providers.dart';
export 'package:echo_bloom/features/playback/playback_providers.dart';
export 'package:echo_bloom/features/playback/playback_queue.dart';
export 'package:echo_bloom/features/playlists/playlist_controller.dart';
export 'package:echo_bloom/features/playlists/playlist_providers.dart';
export 'package:echo_bloom/features/profile/profile_controller.dart';
export 'package:echo_bloom/features/releases/releases_controller.dart';
export 'package:echo_bloom/features/releases/releases_providers.dart';
export 'package:echo_bloom/features/search/search_controller.dart';
export 'package:echo_bloom/features/settings/settings_controller.dart';
