import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream provider for real-time playback state updates.
final playbackStateStreamProvider = StreamProvider<PlaybackState>((ref) {
  final playbackRepository = ref.watch(playbackRepositoryProvider);
  return playbackRepository.playbackStateStream;
});

/// Current playback state snapshot.
final currentPlaybackStateProvider = Provider<PlaybackState>((ref) {
  final asyncState = ref.watch(playbackStateStreamProvider);
  return asyncState.valueOrNull ?? ref.watch(playbackRepositoryProvider).currentState;
});

/// Isolated current active track provider.
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(currentPlaybackStateProvider.select((s) => s.currentTrack));
});

/// Isolated playback status provider.
final playbackStatusProvider = Provider<PlaybackStatus>((ref) {
  return ref.watch(currentPlaybackStateProvider.select((s) => s.status));
});

/// Isolated duration provider.
final playbackDurationProvider = Provider<Duration>((ref) {
  return ref.watch(currentPlaybackStateProvider.select((s) => s.duration));
});

/// Isolated shuffle provider.
final isShuffleEnabledProvider = Provider<bool>((ref) {
  return ref.watch(currentPlaybackStateProvider.select((s) => s.isShuffleEnabled));
});

/// Isolated repeat mode provider.
final repeatModeProvider = Provider<RepeatMode>((ref) {
  return ref.watch(currentPlaybackStateProvider.select((s) => s.repeatMode));
});

/// High-frequency position stream provider (strictly isolated).
final playbackPositionStreamProvider = StreamProvider<Duration>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return engine.positionStream;
});

