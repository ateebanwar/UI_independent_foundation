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

/// Direct playback state provider alias for easy consumption.
final playbackStateProvider = Provider<PlaybackState>((ref) {
  return ref.watch(currentPlaybackStateProvider);
});

/// Sleep timer stream provider emitting remaining duration.
final sleepTimerStreamProvider = StreamProvider<Duration?>((ref) {
  final repo = ref.watch(playbackRepositoryProvider);
  return repo.sleepTimerStream;
});

/// Current remaining duration for sleep timer.
final sleepTimerRemainingProvider = Provider<Duration?>((ref) {
  final asyncRemaining = ref.watch(sleepTimerStreamProvider);
  return asyncRemaining.valueOrNull ?? ref.watch(playbackRepositoryProvider).currentSleepTimerRemaining;
});

/// Current crossfade duration provider.
final crossfadeDurationProvider = Provider<Duration>((ref) {
  return ref.watch(playbackRepositoryProvider).crossfadeDuration;
});

