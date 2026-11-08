# UI INTEGRATION CHECKLIST & DEVELOPER GUIDE
## Echo Bloom — Headless Foundation to Presentation Layer Integration

**Author:** Principal Flutter Architect  
**Project:** `d:\FLutter\redesign UI`  
**Date:** 2026-11-09  

---

## 1. Overview for Future UI Engineers

The Echo Bloom foundation is completely decoupled from visual widgets. As a UI engineer, you do **NOT** need to write or rewrite:
- The local SQLite database, tables, or migrations.
- The audio engine, audio session bindings, or platform DSP hooks.
- The multi-provider search engine, fallback logic, or HTML decoding.
- The background download manager, chunked streaming, or atomic `.tmp` swap.
- The 5-second YouTube listening history or play count increment rules.

Your sole responsibility is designing and rendering visual screens and binding them to the documented Riverpod providers and facade methods.

---

## 2. Step 1: Application Bootstrapping

In your `lib/main.dart`, wrap the application in a `ProviderScope` and initialize the foundation before rendering the first frame:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echo_bloom/echo_bloom_foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes SQLite V4, user preferences, platform audio driver, and download recovery
  final container = await StartupCoordinator.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyMusicApp(),
    ),
  );
}
```

---

## 3. Step 2: Wiring UI Components to Foundation Providers

### 3.1 Now Playing Bar & Player Screen
Bind to `playbackControllerProvider`:
```dart
class NowPlayingWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackControllerProvider);
    final playbackRepo = ref.read(playbackRepositoryProvider);

    final track = playbackState.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(track.title, style: Theme.of(context).textTheme.titleMedium),
        Text(track.artist, style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: playbackState.position.inMilliseconds.toDouble(),
          max: (playbackState.duration.inMilliseconds > 0 
                  ? playbackState.duration.inMilliseconds 
                  : 1).toDouble(),
          onChanged: (ms) => playbackRepo.seek(Duration(milliseconds: ms.round())),
        ),
        IconButton(
          icon: Icon(playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => playbackRepo.togglePlayPause(),
        ),
      ],
    );
  }
}
```

### 3.2 Search Screen & Infinite Scroll Pagination
Bind to `searchControllerProvider`:
```dart
class SearchScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchControllerProvider);
    final searchController = ref.read(searchControllerProvider.notifier);

    return Column(
      children: [
        TextField(
          onChanged: (query) => searchController.search(query),
          decoration: const InputDecoration(hintText: 'Search songs, artists, albums...'),
        ),
        if (searchState.isSearching) const LinearProgressIndicator(),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                searchController.loadNextPage();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: searchState.remoteResults.length + (searchState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == searchState.remoteResults.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final track = searchState.remoteResults[index];
                return ListTile(
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  onTap: () => ref.read(playbackRepositoryProvider).playTrack(track),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

### 3.3 Download Action & Progress Indicator
Bind to `downloadControllerProvider`:
```dart
class DownloadButton extends ConsumerWidget {
  final Track track;
  const DownloadButton({required this.track, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadControllerProvider);
    final downloadController = ref.read(downloadControllerProvider.notifier);

    final isDownloaded = downloadState.downloadedTrackIds.contains(track.id);
    final task = downloadState.activeTasks[track.id];

    if (isDownloaded) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (task != null) {
      return CircularProgressIndicator(value: task.progress);
    }
    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () => downloadController.downloadTrack(track),
    );
  }
}
```

### 3.4 5-Band Equalizer Sliders & Presets
Bind to `equalizerControllerProvider`:
```dart
class EqualizerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerControllerProvider);
    final eqController = ref.read(equalizerControllerProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Equalizer Enabled'),
          value: eqState.isEnabled,
          onChanged: (val) => eqController.setEnabled(val),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (bandIdx) {
            return Column(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    min: -12.0,
                    max: 12.0,
                    value: eqState.bandGains[bandIdx],
                    onChanged: (gain) => eqController.setBandGain(bandIdx, gain),
                  ),
                ),
                Text('${['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'][bandIdx]}'),
              ],
            );
          }),
        ),
      ],
    );
  }
}
```

### 3.5 Real-Time Synchronized Lyrics
Bind to `lyricsControllerProvider`:
```dart
class LyricsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsState = ref.watch(lyricsControllerProvider);
    if (lyricsState.isLoading) return const CircularProgressIndicator();

    return ListView.builder(
      itemCount: lyricsState.lines.length,
      itemBuilder: (context, idx) {
        final line = lyricsState.lines[idx];
        final isCurrent = idx == lyricsState.currentLineIndex;
        return Text(
          line.text,
          style: TextStyle(
            fontSize: isCurrent ? 20 : 16,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.amber : Colors.grey,
          ),
        );
      },
    );
  }
}
```

---

## 4. UI Readiness Verification Checklist

- [x] Foundation exports all required classes via `package:echo_bloom/echo_bloom_foundation.dart`.
- [x] Working integration sample available in `example/foundation_example.dart`.
- [x] Zero breaking API dependencies for presentation layer.
- [x] All state changes broadcast reactively over Riverpod providers.
- [x] Mode switching (`AppMode.offline` vs `AppMode.online`) completely automated.

