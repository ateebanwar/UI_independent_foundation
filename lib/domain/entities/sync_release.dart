import 'package:echo_bloom/domain/entities/track.dart';
import 'package:equatable/equatable.dart';

/// Represents a synchronized album, single, or curated release collection.
class SyncRelease extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? releaseDate;
  final String releaseType;
  final String? artworkUri;
  final int trackCount;
  final DateTime syncedAt;
  final String remoteProvider;
  final String? remoteUrl;
  final List<Track> tracks;

  const SyncRelease({
    required this.id,
    required this.title,
    required this.artist,
    this.releaseDate,
    this.releaseType = 'album',
    this.artworkUri,
    this.trackCount = 0,
    required this.syncedAt,
    this.remoteProvider = 'jiosaavn',
    this.remoteUrl,
    this.tracks = const [],
  });

  SyncRelease copyWith({
    String? id,
    String? title,
    String? artist,
    String? releaseDate,
    String? releaseType,
    String? artworkUri,
    int? trackCount,
    DateTime? syncedAt,
    String? remoteProvider,
    String? remoteUrl,
    List<Track>? tracks,
  }) {
    return SyncRelease(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      releaseDate: releaseDate ?? this.releaseDate,
      releaseType: releaseType ?? this.releaseType,
      artworkUri: artworkUri ?? this.artworkUri,
      trackCount: trackCount ?? this.trackCount,
      syncedAt: syncedAt ?? this.syncedAt,
      remoteProvider: remoteProvider ?? this.remoteProvider,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      tracks: tracks ?? this.tracks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        releaseDate,
        releaseType,
        artworkUri,
        trackCount,
        syncedAt,
        remoteProvider,
        remoteUrl,
        tracks,
      ];
}

