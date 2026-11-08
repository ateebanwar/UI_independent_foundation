import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/domain/entities/sync_release.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/playback_repository.dart';
import 'package:echo_bloom/domain/repositories/sync_releases_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReleasesState extends Equatable {
  final bool isLoading;
  final List<SyncRelease> releases;
  final String? errorMessage;

  const ReleasesState({
    this.isLoading = false,
    this.releases = const [],
    this.errorMessage,
  });

  ReleasesState copyWith({
    bool? isLoading,
    List<SyncRelease>? releases,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReleasesState(
      isLoading: isLoading ?? this.isLoading,
      releases: releases ?? this.releases,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isLoading, releases, errorMessage];
}

class ReleasesController extends StateNotifier<ReleasesState> {
  final SyncReleasesRepository _repository;
  final AppLogger? _logger;

  ReleasesController(this._repository, [this._logger]) : super(const ReleasesState()) {
    loadReleases();
  }

  Future<void> loadReleases({bool forceRefresh = false}) async {
    _logger?.info('Loading releases (forceRefresh: $forceRefresh)', tag: 'ReleasesController');
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.syncReleases(forceRefresh: forceRefresh);
    state = state.copyWith(
      isLoading: false,
      releases: result.valueOrNull ?? state.releases,
      errorMessage: result.failureOrNull?.message,
    );
  }

  Future<List<Track>> getReleaseTracks(String releaseId) async {
    final result = await _repository.getReleaseTracks(releaseId);
    return result.valueOrNull ?? const [];
  }

  Future<void> playRelease(SyncRelease release, PlaybackRepository playbackRepo) async {
    _logger?.info('Playing release: ${release.title}', tag: 'ReleasesController');
    List<Track> tracksToPlay = release.tracks;
    if (tracksToPlay.isEmpty) {
      tracksToPlay = await getReleaseTracks(release.id);
    }
    if (tracksToPlay.isNotEmpty) {
      await playbackRepo.setQueue(tracksToPlay, initialIndex: 0);
    }
  }
}
