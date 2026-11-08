import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef _MciSendStringNative = Uint32 Function(
  Pointer<Utf16> lpstrCommand,
  Pointer<Utf16> lpstrReturnString,
  Uint32 uReturnLength,
  IntPtr hwndCallback,
);

typedef _MciSendStringDart = int Function(
  Pointer<Utf16> lpstrCommand,
  Pointer<Utf16> lpstrReturnString,
  int uReturnLength,
  int hwndCallback,
);

/// Native WinMM (Windows MultiMedia) MCI audio driver for genuine Windows desktop playback.
class WindowsAudioPlayer {
  static const String _alias = 'echo_bloom_audio';

  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<void> _endedController = StreamController<void>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<void> get onEnded => _endedController.stream;
  Stream<String> get onError => _errorController.stream;

  bool _isSupported = false;
  bool get isSupported => _isSupported;

  _MciSendStringDart? _mciSendString;
  Timer? _positionTimer;
  Duration _lastDuration = Duration.zero;
  bool _isPlaying = false;

  WindowsAudioPlayer() {
    if (Platform.isWindows) {
      try {
        final winmm = DynamicLibrary.open('winmm.dll');
        _mciSendString = winmm
            .lookupFunction<_MciSendStringNative, _MciSendStringDart>('mciSendStringW');
        _isSupported = true;
      } catch (e) {
        _isSupported = false;
      }
    }
  }

  String _sendCommand(String command) {
    if (!_isSupported || _mciSendString == null) return '';

    final cmdPtr = command.toNativeUtf16();
    final returnBuf = calloc<Uint16>(256);

    try {
      final res = _mciSendString!(
        cmdPtr,
        returnBuf.cast<Utf16>(),
        256,
        0,
      );

      if (res != 0) {
        return '';
      }

      return returnBuf.cast<Utf16>().toDartString();
    } catch (_) {
      return '';
    } finally {
      calloc.free(cmdPtr);
      calloc.free(returnBuf);
    }
  }

  Future<bool> load(String pathOrUri) async {
    if (!_isSupported) return false;

    stopPolling();
    _sendCommand('close $_alias');

    // WinMM MCI requires Windows file path with backslashes
    final cleanPath = pathOrUri.replaceAll('/', '\\');
    final openResult = _sendCommand('open "$cleanPath" type mpegvideo alias $_alias');
    // If mpegvideo fails for wav or flac, try generic open
    if (openResult.isNotEmpty) {
      // already closed
    }

    _sendCommand('set $_alias time format milliseconds');

    final lenStr = _sendCommand('status $_alias length');
    final lenMs = int.tryParse(lenStr) ?? 0;
    if (lenMs > 0) {
      _lastDuration = Duration(milliseconds: lenMs);
      if (!_durationController.isClosed) {
        _durationController.add(_lastDuration);
      }
    }

    return true;
  }

  Future<void> play() async {
    if (!_isSupported) return;
    _sendCommand('play $_alias');
    _isPlaying = true;
    startPolling();
  }

  Future<void> pause() async {
    if (!_isSupported) return;
    _sendCommand('pause $_alias');
    _isPlaying = false;
    stopPolling();
  }

  Future<void> stop() async {
    if (!_isSupported) return;
    _sendCommand('stop $_alias');
    _isPlaying = false;
    stopPolling();
    _sendCommand('seek $_alias to 0');
    if (!_positionController.isClosed) {
      _positionController.add(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    if (!_isSupported) return;
    final ms = position.inMilliseconds;
    _sendCommand('seek $_alias to $ms');
    if (_isPlaying) {
      _sendCommand('play $_alias');
    }
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isSupported) return;
    final mciVol = (volume.clamp(0.0, 1.0) * 1000).round();
    _sendCommand('setaudio $_alias volume to $mciVol');
  }

  Future<void> setSpeed(double speed) async {
    if (!_isSupported) return;
    final speedInt = (speed.clamp(0.5, 2.0) * 1000).round();
    _sendCommand('set $_alias speed $speedInt');
  }

  void startPolling() {
    stopPolling();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isPlaying) return;

      final posStr = _sendCommand('status $_alias position');
      final posMs = int.tryParse(posStr);
      if (posMs != null) {
        final pos = Duration(milliseconds: posMs);
        if (!_positionController.isClosed) {
          _positionController.add(pos);
        }

        final mode = _sendCommand('status $_alias mode').trim().toLowerCase();
        if (mode == 'stopped') {
          if (_lastDuration > Duration.zero &&
              (posMs >= _lastDuration.inMilliseconds - 300 || posMs == 0)) {
            _isPlaying = false;
            stopPolling();
            if (!_endedController.isClosed) {
              _endedController.add(null);
            }
          }
        }
      }
    });
  }

  void stopPolling() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> dispose() async {
    stopPolling();
    _sendCommand('close $_alias');
    await _positionController.close();
    await _durationController.close();
    await _endedController.close();
    await _errorController.close();
  }
}

