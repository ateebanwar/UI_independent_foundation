import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:equatable/equatable.dart';

enum DownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  canceled,
}

class DownloadTask extends Equatable {
  final String trackId;
  final DownloadStatus status;
  final double progress;
  final String? targetPath;

  const DownloadTask({
    required this.trackId,
    required this.status,
    this.progress = 0.0,
    this.targetPath,
  });

  @override
  List<Object?> get props => [trackId, status, progress, targetPath];
}

/// Abstract contract for offline track download manager.
abstract class DownloadManager {
  Stream<DownloadTask> get downloadStream;
  Future<Result<void, Failure>> enqueueDownload(Track track);
  Future<Result<void, Failure>> cancelDownload(String trackId);
  Future<Result<void, Failure>> removeDownloadedTrack(String trackId);
}

