# Echo Bloom — UI Integration Guide & Developer Handbook
**Document ID:** `docs/11_UI_INTEGRATION_GUIDE.md`  
**Execution Environment:** Google Anti Gravity  
**Project:** Echo Bloom (UI-Independent Foundation Reconstruction)  
**Target Root:** `d:\FLutter\redesign UI`  
**Package:** `echo_bloom`  
**Audience:** Future UI Engineering Team  
**Status:** READY FOR UI IMPLEMENTATION  

---

## 1. Introduction

This guide provides the UI team with complete instructions for building any visual interface on top of the Echo Bloom foundation. 

The foundation handles:
- Audio playback, queuing, seeking, volume, repeat, and shuffle.
- Local SQLite database persistence, playlists, and playback history.
- Offline media scanning and metadata indexing.
- JioSaavn and Gaana online music streaming and search.
- Offline track and playlist downloading.
- 5-band equalizer DSP controls.
- Synchronized timestamped LRC lyrics.
- User profile and offline/online mode enforcement.

**UI developers do NOT need to write database queries, HTTP API calls, or platform audio channels.** You only need to bind Flutter widgets to the Riverpod providers described below.

---

## 2. Riverpod Architecture Overview

The foundation uses **Riverpod 2.6** (`flutter_riverpod`). All widgets should extend `ConsumerWidget` or `ConsumerStatefulWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echo_bloom/features/playback/playback_providers.dart';

class NowPlayingWidget extends ConsumerWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackStateProvider);
    final track = playbackState.currentTrack;

    if (track == null) {
      return const Text('No track playing');
    }

    return Column(
      children: [
        Text(track.title, style: Theme.of(context).textTheme.titleLarge),
        Text(track.artist, style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          icon: Icon(playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => ref.read(playbackRepositoryProvider).togglePlayPause(),
        ),
      ],
    );
  }
}
```

---

## 3. Subsystem Providers & API Contracts

### 3.1 Playback Subsystem (`features/playback/playback_providers.dart`)
- **`playbackStateProvider`** (`PlaybackState`):
  - `.currentTrack` (`Track?`): The active track.
  - `.status` (`PlaybackStatus`: `idle`, `loading`, `playing`, `paused`, `error`).
  - `.position` (`Duration`): Current playback position.
  - `.duration` (`Duration`): Total active track duration.
  - `.volume` (`double`: `0.0` to `1.0`).
  - `.playbackSpeed` (`double`: `0.5` to `2.0`).
  - `.repeatMode` (`RepeatMode`: `off`, `all`, `one`).
  - `.isShuffleEnabled` (`bool`).
- **`playbackRepositoryProvider`** (`PlaybackRepository`):
  - `playTrack(Track track)`: Starts playing a specific track.
  - `setQueue(List<Track> queue, {int initialIndex})`: Loads an entire queue.
  - `addToQueue(Track track)`: Appends track to queue.
  - `playNext(Track track)`: Queues track as next item.
  - `togglePlayPause()`, `play()`, `pause()`, `stop()`.
  - `seek(Duration position)`: Jumps to timestamp.
  - `skipToNext()`, `skipToPrevious()`.
  - `setRepeatMode(RepeatMode mode)`.
  - `toggleShuffle()`.
  - `setVolume(double volume)`.
  - `setSpeed(double speed)`.

### 3.2 Media Library Subsystem (`features/library/library_providers.dart`)
- **`libraryControllerProvider`** (`LibraryState`):
  - `.tracks` (`List<Track>`): All indexed tracks.
  - `.albums` (`List<Album>`): All discovered albums.
  - `.artists` (`List<Artist>`): All discovered artists.
  - `.isScanning` (`bool`): Whether media scanner is currently active.
  - `.scannedCount` (`int`), `.totalFound` (`int`): Scan progress indicators.
- **Actions via `ref.read(libraryControllerProvider.notifier)`**:
  - `rescanLibrary()`: Triggers full media scan.
  - `filterByGenre(String? genre)`, `filterByArtist(String? artist)`.
  - `sortBy(TrackSortOption option, {bool ascending})`.

### 3.3 Playlist Subsystem (`features/playlists/playlist_providers.dart`)
- **`playlistControllerProvider`** (`List<Playlist>`): User playlists.
- **Actions via `ref.read(playlistControllerProvider.notifier)`**:
  - `createPlaylist(String name, {String? description})`.
  - `deletePlaylist(String playlistId)`.
  - `addTrackToPlaylist(String playlistId, Track track)`.
  - `removeTrackFromPlaylist(String playlistId, String trackId)`.
  - `reorderTrack(String playlistId, int oldIndex, int newIndex)`.

### 3.4 Downloads Subsystem (`features/downloads/downloads_providers.dart`)
- **`downloadControllerProvider`** (`DownloadState`):
  - `.downloadedTracks` (`List<Track>`): All downloaded offline tracks.
  - `.downloadedPlaylists` (`List<DownloadedPlaylist>`): Offline collections.
  - `.downloadingTrackIds` (`Set<String>`): Tracks actively being downloaded.
  - `.downloadingPlaylistIds` (`Set<String>`): Playlists actively being downloaded.
  - `.playlistProgress` (`Map<String, String>`): E.g., `{"pl_1": "4/10 downloaded"}`.
- **Actions via `ref.read(downloadControllerProvider.notifier)`**:
  - `downloadTrack(Track track)`: Downloads single online track for offline playback.
  - `downloadPlaylist(Playlist playlist, List<Track> tracks)`: Downloads entire playlist.
  - `deleteDownload(Track track)`: Removes downloaded audio file.
  - `deleteDownloadedPlaylist(String playlistId)`.
  - `cancelPlaylistDownload(String playlistId)`.
  - `retryPlaylistDownload(String playlistId)`.

### 3.5 Equalizer Subsystem (`features/equalizer/equalizer_providers.dart`)
- **`equalizerControllerProvider`** (`EqualizerState`):
  - `.isEnabled` (`bool`): Equalizer enabled toggle.
  - `.bands` (`List<EqualizerBand>`): 5 frequency bands (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz) with `gainDb` (-10.0 to +10.0 dB).
  - `.currentPreset` (`EqualizerPreset`: `flat`, `rock`, `pop`, `jazz`, `classical`, `bassBoost`, `custom`).
- **Actions via `ref.read(equalizerControllerProvider.notifier)`**:
  - `setBandGain(int bandIndex, double gainDb)`.
  - `applyPreset(EqualizerPreset preset)`.
  - `toggleEnabled(bool enabled)`.
  - `resetToFlat()`.

### 3.6 Live Lyrics Subsystem (`features/lyrics/lyrics_providers.dart`)
- **`lyricsControllerProvider`** (`LyricsState`):
  - `.lyrics` (`Lyrics?`): Parsed lyrics with `.lines` (`List<LyricLine>`).
  - `.currentLineIndex` (`int`): Automatically synchronized active line index matching playback position!
  - `.isLoading` (`bool`).
- **Actions via `ref.read(lyricsControllerProvider.notifier)`**:
  - `loadLyricsForTrack(Track track)`: Fetches and parses lyrics for the track.

### 3.7 Search Subsystem (`features/search/search_providers.dart`)
- **`searchControllerProvider`** (`SearchState`):
  - `.results` (`List<Track>`): Search result tracks.
  - `.isLoading` (`bool`).
  - `.activeQuery` (`String`).
- **Actions via `ref.read(searchControllerProvider.notifier)`**:
  - `search(String query)`: Automatically respects active `AppMode`! In `offline` mode, searches local SQLite index. In `online` mode, queries JioSaavn / Gaana.
  - `clear()`.

### 3.8 User Profile & App Mode (`features/profile/profile_providers.dart`)
- **`userProfileProvider`**: User info (`name`, `dateOfBirth`, `gender`, `age`).
- **`appModeProvider`**: `AppMode.offline` or `AppMode.online`. Toggling this seamlessly switches the entire app between pure local and online streaming modes!

---

## 4. UI Implementation Rules
1. **Never make direct database queries**: Always go through the appropriate repository or controller.
2. **Never import `dart:io` or `winmm.dll`**: All platform specifics are handled in `infrastructure/`.
3. **Use `ref.watch()` for UI rebuilds**: Only watch the specific state needed for each widget to maintain 60/120 FPS performance.
4. **The Headless Dashboard (`FoundationVerificationView`)**: Located at `lib/app/app.dart`. You can replace or wrap this view with your new UI routes in `lib/app/routing/app_router.dart`.
