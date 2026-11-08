import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/data/local/data_sources/local_sync_releases_data_source.dart';
import 'package:echo_bloom/data/repositories/sync_releases_repository_impl.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/repositories/sync_releases_repository.dart';
import 'package:echo_bloom/features/releases/releases_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localSyncReleasesDataSourceProvider = Provider<LocalSyncReleasesDataSource>((ref) {
  final appDb = ref.watch(appDatabaseProvider);
  return LocalSyncReleasesDataSource(appDb);
});

final syncReleasesRepositoryProvider = Provider<SyncReleasesRepository>((ref) {
  final localDs = ref.watch(localSyncReleasesDataSourceProvider);
  final logger = ref.watch(loggerProvider);
  return SyncReleasesRepositoryImpl(
    localDataSource: localDs,
    logger: logger,
  );
});

final releasesControllerProvider = StateNotifierProvider<ReleasesController, ReleasesState>((ref) {
  final repo = ref.watch(syncReleasesRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  return ReleasesController(repo, logger);
});

final syncReleasesListProvider = Provider<List<SyncRelease>>((ref) {
  return ref.watch(releasesControllerProvider).releases;
});
