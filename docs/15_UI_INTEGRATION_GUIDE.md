# UI Integration Guide for Future Developers

## 1. Introduction

Echo Bloom Foundation is **completely decoupled from visual widgets**. As a frontend engineer or UI designer, you do not need to write database queries, configure audio pipelines, or implement API clients. You simply import `echo_bloom_foundation.dart` and bind your Flutter widgets to the provided Riverpod providers.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echo_bloom/echo_bloom_foundation.dart';
```

---

## 2. Core Provider Cheat-Sheet

| Feature | Riverpod Provider | Type / Return Value |
| :--- | :--- | :--- |
| **Playback State** | `playbackStateProvider` | `PlaybackState` (status, currentTrack, position, duration, isPlaying) |
| **Playback Controls** | `playbackRepositoryProvider` | `PlaybackRepository` (`play`, `pause`, `skipToNext`, `skipToPrevious`, `seek`, `setQueue`) |
| **Sleep Timer** | `sleepTimerStreamProvider` | `Stream<int?>` (remaining countdown seconds or null) |
| **Search Engine** | `searchControllerProvider` | `SearchState` (query, isSearching, songs, artists, albums, playlists) |
| **Search Notifier** | `searchControllerProvider.notifier` | `SearchController` (`search`, `playAll`, `queueAll`, `setCategory`) |
| **Releases / New Albums** | `releasesControllerProvider` | `ReleasesState` (isLoading, releases, errorMessage) |
| **Downloads & Storage** | `downloadControllerProvider` | `DownloadState` (downloadedTracks, downloadingTrackIds, formattedStorageUsage) |
| **Listening History** | `historyControllerProvider` | `HistoryState` (history, isLoading, searchQuery) |
| **Equalizer** | `equalizerControllerProvider` | `EqualizerState` (configuration, bandGains, activePresetId) |
| **Equalizer Notifier** | `equalizerControllerProvider.notifier`| `EqualizerController` (`setBandGain`, `applyPreset`, `toggleEnabled`, `resetToFlat`) |
| **Playlists** | `playlistControllerProvider` | `PlaylistState` (playlists, isLoading) |
| **User Profile & Mode**| `userProfileProvider` | `UserProfileState` (profile, mode: offline/online) |

---

## 3. UI Component Examples

### 3.1 Mini-Player Widget
```dart
class MiniPlayerWidget extends ConsumerWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackStateProvider);
    final track = playback.currentTrack;

    if (track == null) return const SizedBox.shrink();

    final repo = ref.read(playbackRepositoryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black87,
      child: Row(
        children: [
          if (track.artworkUri != null)
            Image.network(track.artworkUri!, width: 48, height: 48, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                Text(track.artist, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1),
              ],
            ),
          ),
          IconButton(
            icon: Icon(playback.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: () => playback.isPlaying ? repo.pause() : repo.resume(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () => repo.skipToNext(),
          ),
        ],
      ),
    );
  }
}
```

### 3.2 Sleep Timer Dialog
```dart
void showSleepTimerPicker(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Set Sleep Timer'),
      children: [15, 30, 45, 60].map((mins) {
        return SimpleDialogOption(
          child: Text('$mins Minutes'),
          onPressed: () {
            ref.read(playbackRepositoryProvider).setSleepTimer(Duration(minutes: mins));
            Navigator.pop(ctx);
          },
        );
      }).toList(),
    ),
  );
}
```

### 3.3 Search Screen with "Play All"
```dart
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchControllerProvider);
    final searchCtrl = ref.read(searchControllerProvider.notifier);
    final playbackRepo = ref.read(playbackRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(hintText: 'Search songs, artists...'),
          onChanged: (q) => searchCtrl.search(q),
        ),
        actions: [
          if (search.songs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play All'),
              onPressed: () => searchCtrl.playAll(search.songs, playbackRepo),
            ),
        ],
      ),
      body: search.isSearching
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: search.songs.length,
              itemBuilder: (ctx, i) {
                final song = search.songs[i];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text('${song.artist} • ${song.album ?? ""}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.playlist_add),
                    onPressed: () => searchCtrl.queueAll([song], playbackRepo),
                  ),
                  onTap: () => playbackRepo.playTrack(song),
                );
              },
            ),
    );
  }
}
```
