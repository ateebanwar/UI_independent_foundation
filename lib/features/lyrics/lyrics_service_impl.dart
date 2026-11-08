import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/data/remote/clients/jiosaavn_client.dart';
import 'package:echo_bloom/features/lyrics/lyrics_contract.dart';

/// Real, online and offline capable implementation of [LyricsService].
/// Fetches synchronized or plain lyrics from JioSaavn, decodes HTML entities,
/// and parses timestamped LRC lines.
class LyricsServiceImpl implements LyricsService {
  final JioSaavnClient _jioSaavnClient;
  final AppLogger? _logger;
  final Map<String, Lyrics> _memoryCache = {};

  LyricsServiceImpl({
    JioSaavnClient? jioSaavnClient,
    AppLogger? logger,
  })  : _jioSaavnClient = jioSaavnClient ?? JioSaavnClient(),
        _logger = logger;

  @override
  Future<Result<Lyrics, Failure>> getLyricsForTrack(String trackId, [String? trackTitle]) async {
    final query = (trackTitle != null && trackTitle.trim().isNotEmpty)
        ? trackTitle.trim()
        : trackId;

    if (_memoryCache.containsKey(query)) {
      return Result.ok(_memoryCache[query]!);
    }

    try {
      final rawLyrics = await _jioSaavnClient.fetchLyrics(query);
      if (rawLyrics == null || rawLyrics.trim().isEmpty) {
        final emptyLyrics = Lyrics(trackId: trackId);
        _memoryCache[query] = emptyLyrics;
        return Result.ok(emptyLyrics);
      }

      final cleanText = _sanitizeLyrics(rawLyrics);
      final syncedLines = _parseLrcLines(cleanText);

      final lyrics = Lyrics(
        trackId: trackId,
        plainLyrics: cleanText,
        syncedLines: syncedLines,
        isSynced: syncedLines.isNotEmpty,
      );

      _memoryCache[query] = lyrics;
      return Result.ok(lyrics);
    } catch (e, stack) {
      _logger?.error('Error fetching lyrics for $query', tag: 'LyricsService', error: e, stackTrace: stack);
      return Result.err(NetworkFailure(message: 'Failed to fetch lyrics: $e', cause: e));
    }
  }

  String _sanitizeLyrics(String raw) {
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  List<LyricLine> _parseLrcLines(String text) {
    final lrcRegex = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{2,3}))?\](.*)');
    final lines = text.split('\n');
    final parsed = <LyricLine>[];

    for (final line in lines) {
      final match = lrcRegex.firstMatch(line.trim());
      if (match != null) {
        final min = int.tryParse(match.group(1) ?? '0') ?? 0;
        final sec = int.tryParse(match.group(2) ?? '0') ?? 0;
        final msStr = match.group(3) ?? '0';
        final ms = int.tryParse(msStr.padRight(3, '0')) ?? 0;
        final text = (match.group(4) ?? '').trim();

        final timestamp = Duration(minutes: min, seconds: sec, milliseconds: ms);
        parsed.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    parsed.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return parsed;
  }
}

