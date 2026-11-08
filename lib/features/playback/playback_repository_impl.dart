import 'dart:async';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/history_repository.dart';
import 'package:echo_bloom/domain/repositories/playback_repository.dart';
import 'package:echo_bloom/domain/repositories/track_repository.dart';
import 'package:echo_bloom/features/playback/playback_queue.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine_impl.dart';

/// Concrete implementation of [PlaybackRepository].
/// Coordinates the [AudioEngine] abstraction, [PlaybackQueue], and [HistoryRepository].
class PlaybackRepositoryImpl implements PlaybackRepository {
  AudioEngine _audioEngine;
  AudioEngine? _standbyEngine;
  final AudioEngine Function()? _engineFactory;
  final HistoryRepository? _historyRepository;
  final TrackRepository? _trackRepository;
  final AppLogger? _logger;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();
  PlaybackQueue _queue = const PlaybackQueue();
  bool _isInitiatingPlayback = false;

  // History qualification state
  Duration _qualificationThreshold = const Duration(seconds: 5);
  Track? _activeSessionTrack;
  bool _sessionHasQualified = false;
  int _accumulatedActivePlayMs = 0;
  DateTime? _lastPlayTimestamp;
  Duration _lastObservedPosition = Duration.zero;

  // Sleep timer state
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  DateTime? _sleepTimerEndTime;
  bool _sleepAfterCurrentSong = false;
  final StreamController<Duration?> _sleepTimerController =
      StreamController<Duration?>.broadcast();

  // Crossfade & Gapless state
  Duration _crossfadeDuration = Duration.zero;
  Track? _preloadedTrack;
  bool _isNextTrackPreloading = false;
  bool _isNextTrackPreloaded = false;
  bool _isCrossfading = false;

  StreamSubscription<AudioEngineEvent>? _eventSub;
  StreamSubscription<PlaybackStatus>? _statusSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  PlaybackRepositoryImpl({
    required AudioEngine audioEngine,
    AudioEngine? standbyEngine,
    AudioEngine Function()? engineFactory,
    HistoryRepository? historyRepository,
    TrackRepository? trackRepository,
    AppLogger? logger,
  })  : _audioEngine = audioEngine,
        _standbyEngine = standbyEngine,
        _engineFactory = engineFactory,
        _historyRepository = historyRepository,
        _trackRepository = trackRepository,
        _logger = logger {
    if (_standbyEngine == null) {
      final factory = _engineFactory;
      if (factory != null) {
        _standbyEngine = factory();
      } else if (audioEngine is AudioEngineImpl) {
        _standbyEngine = AudioEngineImpl(playerId: 'secondary', logger: _logger);
      }
    }
    _initEngineListeners();
    if (audioEngine is AudioEngineImpl) {
      audioEngine.onMediaAction = _handleMediaAction;
    }
  }

  /// Standby audio engine instance used for gapless pre-buffering and overlapping crossfade.
  AudioEngine? get standbyEngine => _standbyEngine;

  /// Whether an overlapping crossfade transition is currently active.
  bool get isCrossfading => _isCrossfading;

  /// Whether the upcoming track in the queue is already decoded and preloaded.
  bool get isNextTrackPreloaded => _isNextTrackPreloaded;

  /// The preloaded standby track.
  Track? get preloadedTrack => _preloadedTrack;

  void _handleMediaAction(String action) {
    switch (action) {
      case 'next':
        skipToNext();
        break;
      case 'previous':
        skipToPrevious();
        break;
    }
  }

  void _rebindPrimaryEngineSubscriptions() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _initEngineListeners();
  }

  void _initEngineListeners() {
    _eventSub = _audioEngine.events.listen((event) {
      switch (event.type) {
        case AudioEngineEventType.trackEnded:
          _handleTrackEnded();
          break;
        case AudioEngineEventType.error:
          _currentState = _currentState.copyWith(
            status: PlaybackStatus.error,
            errorMessage: event.errorMessage ?? 'Playback error occurred',
          );
          _emitState();
          break;
        case AudioEngineEventType.statusChanged:
          if (event.status != null) {
            if (_isInitiatingPlayback && event.status == PlaybackStatus.paused) {
              break;
            }
            _currentState = _currentState.copyWith(status: event.status);
            _emitState();
          }
          break;
        case AudioEngineEventType.positionDiscontinuity:
          if (event.position != null) {
            _currentState = _currentState.copyWith(position: event.position);
            _emitState();
          }
          break;
      }
    });

    _statusSub = _audioEngine.statusStream.listen((status) {
      if (_isInitiatingPlayback && status == PlaybackStatus.paused) {
        return;
      }
      if (status != PlaybackStatus.playing) {
        _lastPlayTimestamp = null;
      } else {
        _lastPlayTimestamp ??= DateTime.now();
      }
      _currentState = _currentState.copyWith(status: status);
      _emitState();
    });

    _posSub = _audioEngine.positionStream.listen((position) {
      _updateListeningProgress(position);
      final prevSec = _currentState.position.inSeconds;
      _currentState = _currentState.copyWith(position: position);
      if (position.inSeconds != prevSec) {
        _emitState();
      }
    });

    _durSub = _audioEngine.durationStream.listen((duration) {
      _currentState = _currentState.copyWith(duration: duration);
      _emitState();
    });
  }

  void _updateListeningProgress(Duration position) {
    if (_activeSessionTrack == null) return;

    if (_currentState.status == PlaybackStatus.playing) {
      final now = DateTime.now();
      if (_lastPlayTimestamp != null) {
        final elapsedWallMs = now.difference(_lastPlayTimestamp!).inMilliseconds;
        final deltaPosMs = (position.inMilliseconds - _lastObservedPosition.inMilliseconds).abs();
        if (elapsedWallMs > 0 && elapsedWallMs < 2000 && deltaPosMs <= 2500) {
          _accumulatedActivePlayMs += elapsedWallMs;
        }
      }
      _lastPlayTimestamp = now;
      _lastObservedPosition = position;

      final trackDur = _activeSessionTrack!.duration;
      final effectiveThreshold = (trackDur > Duration.zero && trackDur < _qualificationThreshold)
          ? Duration(milliseconds: (trackDur.inMilliseconds * 0.8).round())
          : _qualificationThreshold;

      if (!_sessionHasQualified && _accumulatedActivePlayMs >= effectiveThreshold.inMilliseconds) {
        _sessionHasQualified = true;
        _logger?.info(
          'Track ${_activeSessionTrack!.title} reached qualification threshold (${_accumulatedActivePlayMs}ms)',
          tag: 'PlaybackRepository',
        );
        if (_historyRepository != null) {
          unawaited(_historyRepository.recordPlay(
            track: _activeSessionTrack!,
            playedDuration: Duration(milliseconds: _accumulatedActivePlayMs),
            completed: false,
          ));
        }
      }

      // Crossfade & Gapless preloading checks
      if (_currentState.duration > Duration.zero) {
        final remaining = _currentState.duration - position;
        final preloadThreshold = _crossfadeDuration > Duration.zero
            ? _crossfadeDuration + const Duration(seconds: 4)
            : const Duration(seconds: 4);

        if (!_isNextTrackPreloading &&
            !_isNextTrackPreloaded &&
            !_isCrossfading &&
            _queue.hasNext &&
            remaining > Duration.zero &&
            remaining <= preloadThreshold) {
          unawaited(_preloadNextTrack());
        }

        if (_crossfadeDuration > Duration.zero &&
            !_isCrossfading &&
            _queue.hasNext &&
            remaining > Duration.zero &&
            remaining <= _crossfadeDuration) {
          unawaited(_performOverlappingCrossfade());
        }
      }
    } else {
      _lastPlayTimestamp = null;
      _lastObservedPosition = position;
    }
  }

  Future<void> _preloadNextTrack() async {
    if (_isNextTrackPreloading || _isNextTrackPreloaded || _standbyEngine == null || !_queue.hasNext) {
      return;
    }

    final nextTrack = _queue.peekNext();
    if (nextTrack == null) return;

    _isNextTrackPreloading = true;
    try {
      Track trackToPreload = nextTrack;
      if (trackToPreload.sourceType == TrackSourceType.remoteStream &&
          (trackToPreload.mediaUri.isEmpty || !trackToPreload.mediaUri.startsWith('http')) &&
          _trackRepository != null) {
        final resolvedUri = await _trackRepository.resolveStreamUri(
          trackToPreload.mediaUri.isNotEmpty ? trackToPreload.mediaUri : trackToPreload.id,
          trackToPreload,
        );
        if (resolvedUri.isNotEmpty && (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://'))) {
          trackToPreload = trackToPreload.copyWith(mediaUri: resolvedUri);
        }
      }

      await _standbyEngine!.load(trackToPreload);
      _preloadedTrack = trackToPreload;
      _isNextTrackPreloaded = true;
      _logger?.info('Standby engine preloaded track: ${trackToPreload.title}', tag: 'PlaybackRepository');
    } catch (e) {
      _logger?.warning('Failed to preload next track on standby engine: $e', tag: 'PlaybackRepository');
      _preloadedTrack = null;
      _isNextTrackPreloaded = false;
    } finally {
      _isNextTrackPreloading = false;
    }
  }

  Future<void> _handleTrackEnded() async {
    if (_isCrossfading) return;
    final finishedTrack = _currentState.currentTrack;
    if (finishedTrack != null && _historyRepository != null) {
      final playedDur = _sessionHasQualified
          ? finishedTrack.duration
          : Duration(milliseconds: _accumulatedActivePlayMs);
      if (_sessionHasQualified || playedDur.inMilliseconds >= 2000) {
        unawaited(_historyRepository.recordPlay(
          track: finishedTrack,
          playedDuration: finishedTrack.duration,
          completed: true,
        ));
      }
    }

    _activeSessionTrack = null;
    _sessionHasQualified = false;
    _accumulatedActivePlayMs = 0;
    _lastPlayTimestamp = null;
    _lastObservedPosition = Duration.zero;

    if (_sleepAfterCurrentSong) {
      _sleepAfterCurrentSong = false;
      await stop();
      await cancelSleepTimer();
      return;
    }

    if (_currentState.repeatMode == RepeatMode.one && finishedTrack != null) {
      await seek(Duration.zero);
      await play();
    } else if (_queue.hasNext) {
      await skipToNext();
    } else {
      await stop();
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  @override
  Stream<PlaybackState> get playbackStateStream => _stateController.stream;

  @override
  PlaybackState get currentState => _currentState;

  PlaybackQueue get currentQueue => _queue;

  @override
  Future<Result<void, Failure>> playTrack(Track track) async {
    try {
      Track trackToPlay = track;

      if (track.sourceType == TrackSourceType.remoteStream) {
        if (track.mediaUri.isEmpty || !track.mediaUri.startsWith('http')) {
          _currentState = _currentState.copyWith(
            currentTrack: track,
            status: PlaybackStatus.loading,
            clearErrorMessage: true,
          );
          _emitState();

          if (_trackRepository != null) {
            final resolvedUri = await _trackRepository.resolveStreamUri(
              track.mediaUri.isNotEmpty ? track.mediaUri : track.id,
              track,
            );
            if (resolvedUri.isNotEmpty &&
                (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://'))) {
              trackToPlay = track.copyWith(mediaUri: resolvedUri);
              unawaited(_trackRepository.upsertTracks([trackToPlay]));
            } else {
              _currentState = _currentState.copyWith(
                status: PlaybackStatus.error,
                errorMessage: 'Unable to play this song right now.',
              );
              _emitState();
              return const Result.err(AudioFailure(message: 'Unable to play this song right now.'));
            }
          }
        }
      }

      if (_queue.originalList.isEmpty || !_queue.originalList.any((t) => t.id == trackToPlay.id)) {
        _queue = _queue.setTracks([trackToPlay], initialIndex: 0);
      } else {
        final trackIdx = _queue.currentList.indexWhere((t) => t.id == trackToPlay.id);
        if (trackIdx >= 0) {
          _queue = _queue.copyWith(currentIndex: trackIdx);
        }
      }

      _currentState = _currentState.copyWith(
        currentTrack: trackToPlay,
        position: Duration.zero,
        duration: trackToPlay.duration > Duration.zero ? trackToPlay.duration : Duration.zero,
        status: PlaybackStatus.loading,
        clearErrorMessage: true,
      );
      _emitState();

      _isInitiatingPlayback = true;
      try {
        bool loadSucceeded = false;
        try {
          await _audioEngine.load(trackToPlay);
          loadSucceeded = true;
        } catch (e) {
          if (trackToPlay.sourceType == TrackSourceType.remoteStream && _trackRepository != null) {
            _logger?.info('Initial remote stream load failed for "${trackToPlay.title}", resolving fresh stream...', tag: 'PlaybackRepository');
            final resolvedUri = await _trackRepository.resolveStreamUri(
              trackToPlay.remotePermaUrl ?? (trackToPlay.id.isNotEmpty ? trackToPlay.id : trackToPlay.title),
              trackToPlay,
            );
            if (resolvedUri.isNotEmpty &&
                (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://')) &&
                resolvedUri != trackToPlay.mediaUri) {
              trackToPlay = trackToPlay.copyWith(mediaUri: resolvedUri);
              unawaited(_trackRepository.upsertTracks([trackToPlay]));
              await _audioEngine.load(trackToPlay);
              loadSucceeded = true;
            }
          }
          if (!loadSucceeded) {
            rethrow;
          }
        }

        await _audioEngine.play();
        _currentState = _currentState.copyWith(
          status: PlaybackStatus.playing,
          currentTrack: trackToPlay,
        );
        _emitState();
      } finally {
        _isInitiatingPlayback = false;
      }

      // Initialize active listening session for YouTube-style history qualification
      _activeSessionTrack = trackToPlay;
      _sessionHasQualified = false;
      _accumulatedActivePlayMs = 0;
      _lastPlayTimestamp = DateTime.now();
      _lastObservedPosition = Duration.zero;

      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to play track ${track.title}', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      _currentState = _currentState.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Playback error: $e',
      );
      _emitState();
      return Result.err(AudioFailure(message: 'Could not play track: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setQueue(List<Track> queue, {int initialIndex = 0}) async {
    try {
      if (queue.isEmpty) {
        await stop();
        _queue = const PlaybackQueue();
        return const Result.ok(null);
      }

      _queue = _queue.setTracks(queue, initialIndex: initialIndex);
      final active = _queue.currentTrack;
      if (active != null) {
        return await playTrack(active);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set playback queue', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set queue: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addToQueue(Track track) async {
    try {
      _queue = _queue.addTrack(track);
      if (_currentState.currentTrack == null) {
        return await playTrack(track);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to add track to queue', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not add to queue: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> playNext(Track track) async {
    try {
      _queue = _queue.insertNext(track);
      if (_currentState.currentTrack == null) {
        return await playTrack(track);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to insert track next', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not play next: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> play() async {
    try {
      if (_currentState.currentTrack == null && _queue.currentTrack != null) {
        return await playTrack(_queue.currentTrack!);
      }
      await _audioEngine.play();
      _currentState = _currentState.copyWith(status: PlaybackStatus.playing);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to play', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not start playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> pause() async {
    try {
      await _audioEngine.pause();
      if (_isCrossfading && _standbyEngine != null) {
        try {
          await _standbyEngine!.pause();
        } catch (_) {}
      }
      _currentState = _currentState.copyWith(status: PlaybackStatus.paused);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to pause', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not pause playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> togglePlayPause() async {
    if (_currentState.isPlaying) {
      return await pause();
    } else {
      return await play();
    }
  }

  @override
  Future<Result<void, Failure>> stop() async {
    try {
      await _audioEngine.stop();
      if (_standbyEngine != null) {
        try {
          await _standbyEngine!.stop();
        } catch (_) {}
      }
      _isCrossfading = false;
      _isNextTrackPreloaded = false;
      _isNextTrackPreloading = false;
      _preloadedTrack = null;
      _currentState = _currentState.copyWith(
        status: PlaybackStatus.idle,
        position: Duration.zero,
      );
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to stop playback', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not stop playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> seek(Duration position) async {
    try {
      _lastObservedPosition = position;
      _lastPlayTimestamp = DateTime.now();
      await _audioEngine.seek(position);
      _currentState = _currentState.copyWith(position: position);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to seek', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not seek: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> skipToNext() async {
    if (_queue.isEmpty || !_queue.hasNext) {
      return const Result.ok(null);
    }

    final nextTrack = _queue.peekNext();
    if (nextTrack == null) {
      return const Result.ok(null);
    }

    // Overlapping crossfade branch
    if (_crossfadeDuration > Duration.zero) {
      await _performOverlappingCrossfade(nextTrack);
      return const Result.ok(null);
    }

    // Instant gapless switch branch if next track already preloaded
    if (_isNextTrackPreloaded && _preloadedTrack != null && _standbyEngine != null) {
      final preloaded = _preloadedTrack!;
      try {
        await _standbyEngine!.play();
        await _audioEngine.stop();

        if (_audioEngine is AudioEngineImpl && _standbyEngine is AudioEngineImpl) {
          await AudioEngineImpl.swapNativePlayers();
        }

        final temp = _audioEngine;
        _audioEngine = _standbyEngine!;
        _standbyEngine = temp;
        _rebindPrimaryEngineSubscriptions();

        _queue = _queue.next();

        if (_activeSessionTrack != null && _historyRepository != null) {
          final playedDur = _sessionHasQualified
              ? _activeSessionTrack!.duration
              : Duration(milliseconds: _accumulatedActivePlayMs);
          if (_sessionHasQualified || playedDur.inMilliseconds >= 2000) {
            unawaited(_historyRepository.recordPlay(
              track: _activeSessionTrack!,
              playedDuration: playedDur,
              completed: true,
            ));
          }
        }

        _activeSessionTrack = preloaded;
        _sessionHasQualified = false;
        _accumulatedActivePlayMs = 0;
        _lastPlayTimestamp = DateTime.now();
        _lastObservedPosition = Duration.zero;

        _isNextTrackPreloaded = false;
        _preloadedTrack = null;

        _currentState = _currentState.copyWith(
          currentTrack: preloaded,
          status: PlaybackStatus.playing,
          position: Duration.zero,
          duration: preloaded.duration,
        );
        _emitState();
        return const Result.ok(null);
      } catch (e) {
        _logger?.warning('Gapless switch error: $e, falling back to standard load', tag: 'PlaybackRepository');
      }
    }

    _queue = _queue.next();
    final active = _queue.currentTrack;
    if (active != null) {
      return await playTrack(active);
    }
    return const Result.ok(null);
  }

  Future<void> _performOverlappingCrossfade([Track? targetNextTrack]) async {
    if (_isCrossfading || _standbyEngine == null) return;

    final nextTrack = targetNextTrack ?? _preloadedTrack ?? _queue.peekNext();
    if (nextTrack == null) return;

    _isCrossfading = true;
    _logger?.info('Starting overlapping crossfade transition to ${nextTrack.title}', tag: 'PlaybackRepository');

    try {
      Track preparedTrack = nextTrack;
      if (!_isNextTrackPreloaded || _preloadedTrack?.id != nextTrack.id) {
        if (preparedTrack.sourceType == TrackSourceType.remoteStream &&
            (preparedTrack.mediaUri.isEmpty || !preparedTrack.mediaUri.startsWith('http')) &&
            _trackRepository != null) {
          final resolvedUri = await _trackRepository.resolveStreamUri(
            preparedTrack.mediaUri.isNotEmpty ? preparedTrack.mediaUri : preparedTrack.id,
            preparedTrack,
          );
          if (resolvedUri.isNotEmpty && (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://'))) {
            preparedTrack = preparedTrack.copyWith(mediaUri: resolvedUri);
          }
        }
        await _standbyEngine!.load(preparedTrack);
        _preloadedTrack = preparedTrack;
        _isNextTrackPreloaded = true;
      }

      final activeNextTrack = _preloadedTrack ?? preparedTrack;
      final originalVolume = _currentState.volume;

      // Start standby player at zero volume while primary continues playing
      await _standbyEngine!.setVolume(0.0);
      await _standbyEngine!.play();

      // Overlapping volume ramp: outgoing drops 1.0 -> 0.0, incoming rises 0.0 -> 1.0
      final durationMs = _crossfadeDuration.inMilliseconds.clamp(100, 10000);
      const steps = 10;
      final stepDelay = Duration(milliseconds: (durationMs / steps).round());

      for (int i = 1; i <= steps; i++) {
        final ratio = i / steps;
        final outgoingVol = (originalVolume * (1.0 - ratio)).clamp(0.0, 1.0);
        final incomingVol = (originalVolume * ratio).clamp(0.0, 1.0);

        try {
          await Future.wait([
            _audioEngine.setVolume(outgoingVol),
            _standbyEngine!.setVolume(incomingVol),
          ]);
        } catch (_) {}
        await Future<void>.delayed(stepDelay);
      }

      // Stop outgoing player and restore baseline volume
      try {
        await _audioEngine.stop();
        await _audioEngine.setVolume(originalVolume);
      } catch (_) {}

      // Swap native hardware media players if running on native platform
      if (_audioEngine is AudioEngineImpl && _standbyEngine is AudioEngineImpl) {
        await AudioEngineImpl.swapNativePlayers();
      }

      // Swap engine references
      final temp = _audioEngine;
      _audioEngine = _standbyEngine!;
      _standbyEngine = temp;
      _rebindPrimaryEngineSubscriptions();

      // Advance queue
      if (targetNextTrack != null && _queue.peekNext()?.id != targetNextTrack.id) {
        final idx = _queue.currentList.indexWhere((t) => t.id == targetNextTrack.id);
        if (idx >= 0) {
          _queue = _queue.copyWith(currentIndex: idx);
        } else {
          _queue = _queue.next();
        }
      } else {
        _queue = _queue.next();
      }

      // Record play completion for outgoing track in history
      if (_activeSessionTrack != null && _historyRepository != null) {
        final playedDur = _sessionHasQualified
            ? _activeSessionTrack!.duration
            : Duration(milliseconds: _accumulatedActivePlayMs);
        if (_sessionHasQualified || playedDur.inMilliseconds >= 2000) {
          unawaited(_historyRepository.recordPlay(
            track: _activeSessionTrack!,
            playedDuration: playedDur,
            completed: true,
          ));
        }
      }

      // Reset active session tracking for newly promoted track
      _activeSessionTrack = activeNextTrack;
      _sessionHasQualified = false;
      _accumulatedActivePlayMs = 0;
      _lastPlayTimestamp = DateTime.now();
      _lastObservedPosition = Duration.zero;

      _isNextTrackPreloaded = false;
      _preloadedTrack = null;

      _currentState = _currentState.copyWith(
        currentTrack: activeNextTrack,
        status: PlaybackStatus.playing,
        position: Duration.zero,
        duration: activeNextTrack.duration,
      );
      _emitState();
      _logger?.info('Overlapping crossfade complete. Now playing: ${activeNextTrack.title}', tag: 'PlaybackRepository');
    } catch (e, stack) {
      _logger?.error('Error during overlapping crossfade: $e', tag: 'PlaybackRepository', error: e, stackTrace: stack);
    } finally {
      _isCrossfading = false;
    }
  }

  @override
  Future<Result<void, Failure>> skipToPrevious() async {
    if (_queue.isEmpty) {
      return const Result.ok(null);
    }

    if (_currentState.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return const Result.ok(null);
    }

    if (!_queue.hasPrevious) {
      await seek(Duration.zero);
      return const Result.ok(null);
    }

    _queue = _queue.previous();
    final prevTrack = _queue.currentTrack;
    if (prevTrack != null) {
      return await playTrack(prevTrack);
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setRepeatMode(RepeatMode mode) async {
    _queue = _queue.setRepeatMode(mode);
    _currentState = _currentState.copyWith(repeatMode: mode);
    _emitState();
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> toggleShuffle() async {
    _queue = _queue.toggleShuffle();
    _currentState = _currentState.copyWith(isShuffleEnabled: _queue.isShuffled);
    _emitState();
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setVolume(double volume) async {
    try {
      await _audioEngine.setVolume(volume);
      _currentState = _currentState.copyWith(volume: volume);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set volume', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set volume: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setSpeed(double speed) async {
    try {
      await _audioEngine.setSpeed(speed);
      _currentState = _currentState.copyWith(playbackSpeed: speed);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set speed', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set speed: $e', cause: e));
    }
  }

  @override
  void setHistoryQualificationThreshold(Duration threshold) {
    _qualificationThreshold = threshold;
  }

  @override
  Duration get historyQualificationThreshold => _qualificationThreshold;

  @override
  Future<Result<void, Failure>> setSleepTimer(Duration? duration, {bool stopAfterCurrent = false}) async {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();

    if (stopAfterCurrent) {
      _sleepAfterCurrentSong = true;
      _sleepTimerEndTime = null;
      _sleepTimerController.add(null);
      return const Result.ok(null);
    }

    _sleepAfterCurrentSong = false;
    if (duration == null || duration <= Duration.zero) {
      _sleepTimerEndTime = null;
      _sleepTimerController.add(null);
      return const Result.ok(null);
    }

    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimerController.add(duration);

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = currentSleepTimerRemaining;
      if (remaining == null || remaining <= Duration.zero) {
        timer.cancel();
        _sleepTimerController.add(null);
      } else {
        _sleepTimerController.add(remaining);
      }
    });

    _sleepTimer = Timer(duration, () async {
      _sleepTicker?.cancel();
      _sleepTimerEndTime = null;
      _sleepTimerController.add(null);
      await pause();
    });

    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimerEndTime = null;
    _sleepAfterCurrentSong = false;
    _sleepTimerController.add(null);
    return const Result.ok(null);
  }

  @override
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  @override
  Duration? get currentSleepTimerRemaining {
    if (_sleepTimerEndTime == null) return null;
    final diff = _sleepTimerEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void setCrossfadeDuration(Duration duration) {
    _crossfadeDuration = duration;
  }

  @override
  Duration get crossfadeDuration => _crossfadeDuration;

  @override
  Future<Result<void, Failure>> reorderQueue(int oldIndex, int newIndex) async {
    _queue = _queue.reorder(oldIndex, newIndex);
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> removeTrackFromQueue(String trackId) async {
    _queue = _queue.removeTrack(trackId);
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> clearQueue() async {
    _queue = _queue.clear();
    await stop();
    return const Result.ok(null);
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimerController.close();
    _eventSub?.cancel();
    _statusSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateController.close();
    try {
      _audioEngine.stop();
      _standbyEngine?.stop();
    } catch (_) {}
  }
}

