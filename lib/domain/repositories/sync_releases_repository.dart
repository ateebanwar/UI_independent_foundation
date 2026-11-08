import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/entities/track.dart';

/// Contract for synchronizing, persisting, and querying new music releases.
abstract class SyncReleasesRepository {
  /// Fetches and synchronizes fresh new releases from remote providers.
  /// Persists retrieved releases to local SQLite storage.
  Future<Result<List<SyncRelease>, Failure>> syncReleases({bool forceRefresh = false});

  /// Retrieves cached releases from local database (offline-safe).
  Future<Result<List<SyncRelease>, Failure>> getCachedReleases();

  /// Retrieves all tracks associated with a specific release.
  Future<Result<List<Track>, Failure>> getReleaseTracks(String releaseId);
}
