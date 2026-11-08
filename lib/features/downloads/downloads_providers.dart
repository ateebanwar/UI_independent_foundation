import 'dart:async';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/features/downloads/download_controller.dart';
import 'package:echo_bloom/features/downloads/downloads_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:echo_bloom/features/downloads/download_controller.dart';
export 'package:echo_bloom/features/downloads/downloads_contract.dart';

class ControllerBackedDownloadManager implements DownloadManager {
  final Ref _ref;
  final StreamController<DownloadTask> _streamController = StreamController<DownloadTask>.broadcast();

  ControllerBackedDownloadManager(this._ref);

  @override
  Stream<DownloadTask> get downloadStream => _streamController.stream;

  @override
  Future<Result<void, Failure>> enqueueDownload(Track track) async {
    final controller = _ref.read(downloadControllerProvider.notifier);
    final success = await controller.downloadTrack(track);
    if (success) {
      return const Result.ok(null);
    } else {
      return const Result.err(StorageFailure(message: 'Failed to enqueue download'));
    }
  }

  @override
  Future<Result<void, Failure>> cancelDownload(String trackId) async {
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> removeDownloadedTrack(String trackId) async {
    final controller = _ref.read(downloadControllerProvider.notifier);
    final track = _ref.read(downloadControllerProvider).downloadedTracks.firstWhere(
          (t) => t.id == trackId,
          orElse: () => Track(
            id: trackId,
            title: '',
            artist: '',
            album: '',
            duration: Duration.zero,
            mediaUri: '',
            dateAdded: DateTime.now(),
          ),
        );
    if (track.mediaUri.isNotEmpty) {
      await controller.deleteDownload(track);
    }
    return const Result.ok(null);
  }
}

/// Provider for offline download manager.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return ControllerBackedDownloadManager(ref);
});
