import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/data/local/data_sources/local_sync_releases_data_source.dart';
import 'package:echo_bloom/data/remote/clients/jiosaavn_client.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/sync_releases_repository.dart';

/// Concrete implementation of [SyncReleasesRepository].
/// Coordinates remote release retrieval with local SQLite caching.
class SyncReleasesRepositoryImpl implements SyncReleasesRepository {
  final LocalSyncReleasesDataSource _localDataSource;
  final JioSaavnClient _jioSaavnClient;
  final AppLogger? _logger;

  SyncReleasesRepositoryImpl({
    required LocalSyncReleasesDataSource localDataSource,
    JioSaavnClient? jioSaavnClient,
    AppLogger? logger,
  })  : _localDataSource = localDataSource,
        _jioSaavnClient = jioSaavnClient ?? JioSaavnClient(logger: logger),
        _logger = logger;

  @override
  Future<Result<List<SyncRelease>, Failure>> syncReleases({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = await _localDataSource.getCachedReleases();
        if (cached.isNotEmpty) {
          final now = DateTime.now();
          final mostRecentSync = cached.first.syncedAt;
          if (now.difference(mostRecentSync).inHours < 4) {
            _logger?.info('Returning fresh cached releases (${cached.length})', tag: 'SyncReleasesRepository');
            return Result.ok(cached);
          }
        }
      }

      _logger?.info('Fetching live releases from JioSaavn catalog...', tag: 'SyncReleasesRepository');
      final tracks = await _jioSaavnClient.search('latest releases hindi');
      if (tracks.isEmpty) {
        final cachedFallback = await _localDataSource.getCachedReleases();
        return Result.ok(cachedFallback);
      }

      // Group tracks by album/release
      final releaseMap = <String, List<Track>>{};
      for (final track in tracks) {
        final key = (track.album != null && track.album!.isNotEmpty)
            ? track.album!
            : track.title;
        releaseMap.putIfAbsent(key, () => []).add(track);
      }

      final now = DateTime.now();
      final freshReleases = <SyncRelease>[];

      releaseMap.forEach((title, releaseTracks) {
        final first = releaseTracks.first;
        final releaseId = 'rel_${title.hashCode}';
        final releaseDate = first.year != null ? first.year.toString() : now.year.toString();

        freshReleases.add(SyncRelease(
          id: releaseId,
          title: title,
          artist: first.artist,
          releaseDate: releaseDate,
          releaseType: releaseTracks.length > 1 ? 'album' : 'single',
          artworkUri: first.artworkUri,
          trackCount: releaseTracks.length,
          syncedAt: now,
          remoteProvider: 'jiosaavn',
          remoteUrl: first.remotePermaUrl,
          tracks: releaseTracks,
        ));
      });

      await _localDataSource.upsertReleases(freshReleases);
      _logger?.info('Synchronized and persisted ${freshReleases.length} releases', tag: 'SyncReleasesRepository');

      return Result.ok(freshReleases);
    } catch (e, stack) {
      _logger?.error('Error synchronizing releases: $e', tag: 'SyncReleasesRepository', error: e, stackTrace: stack);
      final cachedFallback = await _localDataSource.getCachedReleases();
      if (cachedFallback.isNotEmpty) {
        return Result.ok(cachedFallback);
      }
      return Result.err(NetworkFailure(message: 'Failed to synchronize releases: $e', cause: e));
    }
  }

  @override
  Future<Result<List<SyncRelease>, Failure>> getCachedReleases() async {
    try {
      final cached = await _localDataSource.getCachedReleases();
      return Result.ok(cached);
    } catch (e, stack) {
      _logger?.error('Error fetching cached releases: $e', tag: 'SyncReleasesRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get cached releases: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Track>, Failure>> getReleaseTracks(String releaseId) async {
    try {
      final tracks = await _localDataSource.getReleaseTracks(releaseId);
      return Result.ok(tracks);
    } catch (e, stack) {
      _logger?.error('Error fetching release tracks for $releaseId: $e', tag: 'SyncReleasesRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to get release tracks: $e', cause: e));
    }
  }
}
