import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/features/lyrics/lyrics_contract.dart';
import 'package:echo_bloom/features/lyrics/lyrics_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:echo_bloom/features/lyrics/lyrics_contract.dart';
export 'package:echo_bloom/features/lyrics/lyrics_service_impl.dart';

/// Provider for lazy lyrics resolution service.
final lyricsServiceProvider = Provider<LyricsService>((ref) {
  final logger = ref.watch(loggerProvider);
  return LyricsServiceImpl(logger: logger);
});

/// Family provider to lazily fetch lyrics on demand when the user opens the lyrics view.
final trackLyricsFamilyProvider =
    FutureProvider.family<Lyrics, String>((ref, trackIdOrTitle) async {
  final service = ref.watch(lyricsServiceProvider);
  final result = await service.getLyricsForTrack(trackIdOrTitle, trackIdOrTitle);
  return result.when(
    ok: (lyrics) => lyrics,
    err: (failure) => Lyrics(trackId: trackIdOrTitle),
  );
});

