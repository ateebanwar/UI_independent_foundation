import 'dart:async';
import 'dart:io';
import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/data/local/data_sources/downloaded_playlist_data_source.dart';
import 'package:echo_bloom/domain/entities/album.dart';
import 'package:echo_bloom/domain/entities/artist.dart';
import 'package:echo_bloom/domain/entities/downloaded_playlist.dart';
import 'package:echo_bloom/domain/entities/playlist.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/track_repository.dart';
import 'package:echo_bloom/infrastructure/storage/offline_audio_storage.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadState extends Equatable {
  final List<Track> downloadedTracks;
  final List<DownloadedPlaylist> downloadedPlaylists;
  final Set<String> downloadingTrackIds;
  final Set<String> downloadingPlaylistIds;
  final Map<String, String> playlistProgress;
  final bool isLoading;
  final String? errorMessage;

  const DownloadState({
    this.downloadedTracks = const [],
    this.downloadedPlaylists = const [],
    this.downloadingTrackIds = const {},
    this.downloadingPlaylistIds = const {},
    this.playlistProgress = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  DownloadState copyWith({
    List<Track>? downloadedTracks,
    List<DownloadedPlaylist>? downloadedPlaylists,
    Set<String>? downloadingTrackIds,
    Set<String>? downloadingPlaylistIds,
    Map<String, String>? playlistProgress,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadState(
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
      downloadedPlaylists: downloadedPlaylists ?? this.downloadedPlaylists,
      downloadingTrackIds: downloadingTrackIds ?? this.downloadingTrackIds,
      downloadingPlaylistIds: downloadingPlaylistIds ?? this.downloadingPlaylistIds,
      playlistProgress: playlistProgress ?? this.playlistProgress,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        downloadedTracks,
        downloadedPlaylists,
        downloadingTrackIds,
        downloadingPlaylistIds,
        playlistProgress,
        isLoading,
        errorMessage,
      ];
}

class DownloadController extends StateNotifier<DownloadState> {
  final TrackRepository _trackRepository;
  final DownloadedPlaylistDataSource? _downloadedPlaylistDataSource;
  final OfflineAudioStorage? _offlineStorage;
  final AppLogger? _logger;
  final http.Client _client;

  final Set<String> _cancelledPlaylists = {};

  DownloadController(
    this._trackRepository, {
    DownloadedPlaylistDataSource? downloadedPlaylistDataSource,
    OfflineAudioStorage? offlineStorage,
    AppLogger? logger,
    http.Client? client,
  })  : _downloadedPlaylistDataSource = downloadedPlaylistDataSource,
        _offlineStorage = offlineStorage,
        _logger = logger,
        _client = client ?? http.Client(),
        super(const DownloadState()) {
    loadDownloadedTracks();
  }

  Future<void> loadDownloadedTracks() => loadDownloadedContent();

  Future<void> loadDownloadedContent() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tracksRes = await _trackRepository.getDownloadedTracks();
      final tracks = tracksRes.valueOrNull ?? [];

      final validTracks = <Track>[];
      final staleTrackIds = <String>[];
      for (final t in tracks) {
        if (!kIsWeb && (t.mediaUri.startsWith('/') || t.mediaUri.contains(r':\'))) {
          if (!File(t.mediaUri).existsSync()) {
            staleTrackIds.add(t.id);
            continue;
          }
        }
        validTracks.add(t);
      }
      if (staleTrackIds.isNotEmpty) {
        await _trackRepository.deleteTracks(staleTrackIds);
      }

      final ds = _downloadedPlaylistDataSource;
      final playlists = ds != null
          ? await ds.getDownloadedPlaylists()
          : <DownloadedPlaylist>[];

      state = state.copyWith(
        downloadedTracks: validTracks,
        downloadedPlaylists: playlists,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load offline downloads: $e',
      );
    }
  }

  bool isTrackDownloaded(Track track) {
    return state.downloadedTracks.any((t) =>
        t.id == track.id ||
        (t.remoteProvider != null &&
            t.remoteProvider == track.remoteProvider &&
            t.remoteProviderId != null &&
            t.remoteProviderId == track.remoteProviderId));
  }

  bool isDownloading(String trackId) {
    return state.downloadingTrackIds.contains(trackId);
  }

  bool isPlaylistDownloading(String playlistId) {
    return state.downloadingPlaylistIds.contains(playlistId);
  }

  bool isPlaylistDownloaded(String playlistId) {
    return state.downloadedPlaylists.any((p) =>
        p.id == playlistId &&
        p.status == DownloadPlaylistStatus.downloaded);
  }

  String getPlaylistProgress(String playlistId) {
    return state.playlistProgress[playlistId] ?? '';
  }

  Future<bool> downloadTrack(Track track) async {
    if (isTrackDownloaded(track)) {
      _logger?.info('Track ${track.title} already downloaded', tag: 'DownloadController');
      return true;
    }

    if (isDownloading(track.id)) {
      return false;
    }

    final updatedDownloading = Set<String>.from(state.downloadingTrackIds)..add(track.id);
    state = state.copyWith(downloadingTrackIds: updatedDownloading, clearError: true);

    try {
      _logger?.info('Resolving stream for single song download: ${track.title}', tag: 'DownloadController');
      final streamUrl = await _trackRepository.resolveStreamUri(
        track.mediaUri.isNotEmpty ? track.mediaUri : track.id,
        track,
      );

      if (streamUrl.isEmpty || (!streamUrl.startsWith('http://') && !streamUrl.startsWith('https://'))) {
        throw Exception('Playable audio stream could not be resolved');
      }

      final response = await _client.get(
        Uri.parse(streamUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Audio download failed with HTTP status ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      if (bytes.length < 1024) {
        throw Exception('Downloaded file too small (${bytes.length} bytes)');
      }

      String offlineUri;
      final storage = _offlineStorage;
      if (storage != null) {
        offlineUri = await storage.saveAudio(
          trackId: track.id,
          bytes: bytes,
          mimeType: response.headers['content-type'] ?? 'audio/mp4',
        );
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${appDir.path}/downloads');
        if (!downloadDir.existsSync()) {
          await downloadDir.create(recursive: true);
        }
        final safeId = track.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final finalFile = File('${downloadDir.path}/$safeId.m4a');
        await finalFile.writeAsBytes(bytes, flush: true);
        offlineUri = finalFile.path;
      }

      final downloadedTrack = track.copyWith(
        mediaUri: offlineUri,
        sourceType: TrackSourceType.downloaded,
        fileSize: bytes.length,
        dateAdded: DateTime.now(),
      );

      await _trackRepository.upsertTracks([downloadedTrack]);
      await loadDownloadedContent();

      _logger?.info('Successfully stored offline track: ${track.title}', tag: 'DownloadController');
      return true;
    } catch (e, stack) {
      _logger?.error('Download failed for ${track.title}', tag: 'DownloadController', error: e, stackTrace: stack);
      state = state.copyWith(errorMessage: 'Download failed for "${track.title}": $e');
      return false;
    } finally {
      final finalDownloading = Set<String>.from(state.downloadingTrackIds)..remove(track.id);
      state = state.copyWith(downloadingTrackIds: finalDownloading);
    }
  }

  Future<bool> downloadPlaylist(Playlist playlist, List<Track> tracks) async {
    if (tracks.isEmpty) return false;

    _cancelledPlaylists.remove(playlist.id);

    final updatedDownloadingPlaylists = Set<String>.from(state.downloadingPlaylistIds)..add(playlist.id);
    final initialProgress = Map<String, String>.from(state.playlistProgress)
      ..[playlist.id] = '0/${tracks.length} downloaded';

    state = state.copyWith(
      downloadingPlaylistIds: updatedDownloadingPlaylists,
      playlistProgress: initialProgress,
      clearError: true,
    );

    final now = DateTime.now();
    final downloadedPlaylist = DownloadedPlaylist(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      artworkUri: playlist.artworkUri,
      sourceType: playlist.isSmartPlaylist ? 'curated' : 'user',
      totalTracks: tracks.length,
      downloadedTracks: 0,
      status: DownloadPlaylistStatus.downloading,
      createdAt: now,
      updatedAt: now,
    );

    final ds = _downloadedPlaylistDataSource;
    if (ds != null) {
      await ds.upsertDownloadedPlaylist(downloadedPlaylist, tracks);
    }

    int completedCount = 0;
    int failedCount = 0;

    const int concurrency = 2;
    for (int i = 0; i < tracks.length; i += concurrency) {
      if (_cancelledPlaylists.contains(playlist.id)) {
        _logger?.info('Playlist download cancelled: ${playlist.name}', tag: 'DownloadController');
        break;
      }

      final chunk = tracks.skip(i).take(concurrency).toList();
      final results = await Future.wait(chunk.map((track) async {
        if (_cancelledPlaylists.contains(playlist.id)) return false;
        if (isTrackDownloaded(track)) return true;
        return await downloadTrack(track);
      }));

      for (final success in results) {
        if (success) {
          completedCount++;
        } else {
          failedCount++;
        }
      }

      final progressStr = '$completedCount/${tracks.length} downloaded';
      final updatedProgress = Map<String, String>.from(state.playlistProgress)..[playlist.id] = progressStr;
      state = state.copyWith(playlistProgress: updatedProgress);

      if (ds != null) {
        await ds.updatePlaylistProgress(
          playlist.id,
          downloadedCount: completedCount,
          status: DownloadPlaylistStatus.downloading,
        );
      }
    }

    final isCancelled = _cancelledPlaylists.contains(playlist.id);
    final finalStatus = isCancelled
        ? DownloadPlaylistStatus.failed
        : (failedCount == 0
            ? DownloadPlaylistStatus.downloaded
            : DownloadPlaylistStatus.partiallyDownloaded);

    if (ds != null) {
      await ds.updatePlaylistProgress(
        playlist.id,
        downloadedCount: completedCount,
        status: finalStatus,
      );
    }

    _cancelledPlaylists.remove(playlist.id);
    final finalDownloadingPlaylists = Set<String>.from(state.downloadingPlaylistIds)..remove(playlist.id);
    final finalProgressMap = Map<String, String>.from(state.playlistProgress)
      ..[playlist.id] = '$completedCount/${tracks.length} downloaded';

    state = state.copyWith(
      downloadingPlaylistIds: finalDownloadingPlaylists,
      playlistProgress: finalProgressMap,
    );

    await loadDownloadedContent();
    return completedCount > 0;
  }

  Future<void> cancelPlaylistDownload(String playlistId) async {
    _cancelledPlaylists.add(playlistId);
    final updatedDownloading = Set<String>.from(state.downloadingPlaylistIds)..remove(playlistId);
    state = state.copyWith(downloadingPlaylistIds: updatedDownloading);

    final ds = _downloadedPlaylistDataSource;
    if (ds != null) {
      await ds.updatePlaylistProgress(
        playlistId,
        downloadedCount: 0,
        status: DownloadPlaylistStatus.failed,
      );
    }
    await loadDownloadedContent();
  }

  Future<void> retryPlaylistDownload(String playlistId) async {
    final ds = _downloadedPlaylistDataSource;
    if (ds == null) return;
    final playlist = await ds.getDownloadedPlaylistById(playlistId);
    if (playlist == null) return;

    final tracks = await ds.getDownloadedPlaylistTracks(playlistId);
    if (tracks.isNotEmpty) {
      await downloadPlaylist(
        Playlist(
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          artworkUri: playlist.artworkUri,
          createdAt: playlist.createdAt,
          updatedAt: DateTime.now(),
        ),
        tracks,
      );
    }
  }

  Future<void> deleteDownload(Track track) async {
    try {
      bool isShared = false;
      final ds = _downloadedPlaylistDataSource;
      if (ds != null) {
        isShared = await ds.isTrackReferencedElsewhere(track.id);
      }
      if (!isShared) {
        final storage = _offlineStorage;
        if (storage != null) {
          await storage.deleteAudio(track.id);
        } else if (!kIsWeb && File(track.mediaUri).existsSync()) {
          await File(track.mediaUri).delete();
        }
      }
      await _trackRepository.deleteTracks([track.id]);
      await loadDownloadedContent();
      _logger?.info('Deleted download for: ${track.title}', tag: 'DownloadController');
    } catch (e, stack) {
      _logger?.error('Failed to delete download: ${track.title}', tag: 'DownloadController', error: e, stackTrace: stack);
    }
  }

  Future<void> deleteDownloadedPlaylist(String playlistId) async {
    final ds = _downloadedPlaylistDataSource;
    if (ds == null) return;
    try {
      final tracks = await ds.getDownloadedPlaylistTracks(playlistId);
      await ds.deleteDownloadedPlaylist(playlistId);

      for (final track in tracks) {
        final isReferenced = await ds.isTrackReferencedElsewhere(track.id);
        if (!isReferenced && track.sourceType == TrackSourceType.downloaded) {
          final storage = _offlineStorage;
          if (storage != null) {
            await storage.deleteAudio(track.id);
          } else if (!kIsWeb && File(track.mediaUri).existsSync()) {
            await File(track.mediaUri).delete();
          }
          await _trackRepository.deleteTracks([track.id]);
        }
      }

      final progressMap = Map<String, String>.from(state.playlistProgress)..remove(playlistId);
      state = state.copyWith(playlistProgress: progressMap);

      await loadDownloadedContent();
      _logger?.info('Deleted downloaded playlist $playlistId', tag: 'DownloadController');
    } catch (e, stack) {
      _logger?.error('Failed to delete downloaded playlist: $playlistId', tag: 'DownloadController', error: e, stackTrace: stack);
    }
  }

  int get totalStorageBytes => state.downloadedTracks.fold(0, (acc, t) => acc + t.fileSize);

  String get formattedStorageUsage {
    final bytes = totalStorageBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  final Set<String> _pausedTrackIds = {};
  bool isPaused(String trackId) => _pausedTrackIds.contains(trackId);

  void pauseTrackDownload(String trackId) {
    _pausedTrackIds.add(trackId);
  }

  void resumeTrackDownload(String trackId) {
    _pausedTrackIds.remove(trackId);
  }

  Future<bool> downloadAlbum(Album album, List<Track> tracks) {
    final playlist = Playlist(
      id: 'album_${album.id}',
      name: album.title,
      description: 'Album by ${album.artist}',
      artworkUri: album.artworkUri,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return downloadPlaylist(playlist, tracks);
  }

  Future<bool> downloadArtistCollection(Artist artist, List<Track> tracks) {
    final playlist = Playlist(
      id: 'artist_${artist.id}',
      name: '${artist.name} Collection',
      description: 'Songs by ${artist.name}',
      artworkUri: artist.artworkUri,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return downloadPlaylist(playlist, tracks);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

final downloadControllerProvider =
    StateNotifierProvider<DownloadController, DownloadState>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final downloadedPlaylistDataSource = ref.watch(downloadedPlaylistDataSourceProvider);
  final offlineStorage = ref.watch(offlineAudioStorageProvider);
  final logger = ref.watch(loggerProvider);

  return DownloadController(
    trackRepo,
    downloadedPlaylistDataSource: downloadedPlaylistDataSource,
    offlineStorage: offlineStorage,
    logger: logger,
  );
});

