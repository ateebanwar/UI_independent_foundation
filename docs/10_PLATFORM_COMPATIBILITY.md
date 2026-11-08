# Echo Bloom — Platform Compatibility & Native Channel Matrix
**Document ID:** `docs/10_PLATFORM_COMPATIBILITY.md`  
**Execution Environment:** Google Anti Gravity  
**Project:** Echo Bloom (UI-Independent Foundation Reconstruction)  
**Target Root:** `d:\FLutter\redesign UI`  
**Package:** `echo_bloom`  
**Date:** 2026-11-09  

---

## 1. Overview & Supported Platforms

The Echo Bloom foundation provides first-class support for three primary targets:
1. **Android** (API Level 21+ / Android 5.0 Lollipop through Android 15+)
2. **Windows Desktop** (Windows 10, Windows 11 x64)
3. **Web / PWA** (Modern standards-compliant browsers: Chrome, Firefox, Edge, Safari)

---

## 2. Platform Feature Matrix

| Feature Subsystem | Android | Windows Desktop | Web / PWA |
| :--- | :---: | :---: | :---: |
| **Audio Playback Engine** | Android `MediaPlayer` via Native Service | Windows WinMM MCI (`winmm.dll`) C-FFI | HTML5 Audio / Web Audio API |
| **Equalizer DSP** | Hardware `android.media.audiofx.Equalizer` | Software gain scaling & persistence | Web Audio `BiquadFilterNode` cascade |
| **Local SQLite Persistence** | Native SQLite via `sqflite` | Persistent Roaming DB via `sqflite_common_ffi` | IndexedDB / SQLite WASM |
| **Media Library Scanning** | Android `MediaStore` + File crawler | Windows filesystem crawler (`C:/.../Music`) | Web File System Access API / Blob import |
| **Offline Audio Storage** | App-private storage (`context.filesDir`) | Persistent AppData downloads directory | IndexedDB Blob storage (`offline_audio_blobs`) |
| **Background Playback** | Foreground Service (`MediaPlaybackService`) | Background WinMM thread | AudioContext background worker |
| **Remote Music Streaming** | JioSaavn + Gaana HTTPS | JioSaavn + Gaana HTTPS | JioSaavn + Gaana HTTPS (CORS-enabled) |
| **Live Synchronized Lyrics** | JioSaavn API + LRC parser | JioSaavn API + LRC parser | JioSaavn API + LRC parser |

---

## 3. Native Platform Contracts

### 3.1 Android Native Channel Implementation
- **Audio Channel:** `com.antigravity.echo_bloom/audio`
  - Methods: `play`, `pause`, `stop`, `seekTo`, `setVolume`, `setPlaybackSpeed`, `setEqualizerBandGain`, `getEqualizerBands`.
  - Service: `MediaPlaybackService.kt` runs as a foreground service with notification playback controls and media session metadata.
- **Permission Channel:** `com.antigravity.echo_bloom/permissions`
  - Methods: `checkPermission`, `requestPermission`.
  - Handles granular Android 13+ `READ_MEDIA_AUDIO` and legacy `READ_EXTERNAL_STORAGE`.

### 3.2 Windows Desktop Native Implementation
- **Driver:** `WindowsAudioPlayer` in `lib/infrastructure/audio/windows_audio_player.dart`.
- **FFI Binding:** Direct integration with Windows Multimedia API (`winmm.dll`) via `DynamicLibrary.open('winmm.dll')`.
- **MCI String Execution:**
  ```dart
  mciSendStringW('open "$path" type mpegvideo alias echo_bloom_track', null, 0, 0);
  mciSendStringW('play echo_bloom_track', null, 0, 0);
  mciSendStringW('status echo_bloom_track position', buffer, 128, 0);
  ```
- **Persistence Path:** Stored in `%APPDATA%\com.antigravity.echo_bloom\echo_bloom.db`.

### 3.3 Web Platform Implementation
- **Driver:** `WebAudioPlayer` in `lib/infrastructure/audio/web_audio_player_web.dart`.
- **Equalizer DSP:** Creates 5 `BiquadFilterNode` instances (`peaking` filter type) connected in series:
  `AudioElement -> MediaElementSource -> Filter60Hz -> Filter230Hz -> Filter910Hz -> Filter3600Hz -> Filter14000Hz -> AudioDestination`.
- **Blob URLs:** Implements `createWebBlobUrl` and `revokeWebBlobUrl` using `dart:html` / `package:web` wrappers.

---

## 4. Verification & Fallback Mechanisms
- When a platform-specific feature is unavailable (e.g., hardware DSP on Windows), the foundation transparently falls back to software-based emulation or state retention without throwing unhandled exceptions.
- The `AudioEngine` factory dynamically selects the best implementation at runtime.
