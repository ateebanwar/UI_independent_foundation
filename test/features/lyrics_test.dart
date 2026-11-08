import 'package:echo_bloom/data/remote/clients/jiosaavn_client.dart';
import 'package:echo_bloom/features/lyrics/lyrics_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockJioSaavnClient extends Mock implements JioSaavnClient {}

void main() {
  group('LyricsServiceImpl Tests', () {
    late MockJioSaavnClient mockClient;
    late LyricsServiceImpl service;

    setUp(() {
      mockClient = MockJioSaavnClient();
      service = LyricsServiceImpl(jioSaavnClient: mockClient);
    });

    test('parses timestamped LRC format lyrics into synchronized lines', () async {
      const rawLrc = '''
[00:12.30]First line of the song
[00:18.50]Second line with emotional melody
[01:05.10]Chorus comes in strong
''';

      when(() => mockClient.fetchLyrics('Kesariya')).thenAnswer((_) async => rawLrc);

      final result = await service.getLyricsForTrack('track-1', 'Kesariya');
      expect(result.isOk, isTrue);

      final lyrics = result.valueOrNull!;
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.syncedLines.length, equals(3));
      expect(lyrics.syncedLines[0].text, equals('First line of the song'));
      expect(lyrics.syncedLines[0].timestamp, equals(const Duration(seconds: 12, milliseconds: 300)));
      expect(lyrics.syncedLines[1].text, equals('Second line with emotional melody'));
      expect(lyrics.syncedLines[1].timestamp, equals(const Duration(seconds: 18, milliseconds: 500)));
      expect(lyrics.syncedLines[2].text, equals('Chorus comes in strong'));
      expect(lyrics.syncedLines[2].timestamp, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 100)));
    });

    test('sanitizes HTML tags from raw lyrics and unescapes entities', () async {
      const htmlLyrics = 'Kabhi jo baadal barse&amp;lt;br&amp;gt;Main dekhoon tujhe aankhein bhar ke<br/>Tu lage mujhe pehli baarish ki duaa&#039;';

      when(() => mockClient.fetchLyrics('Baadal')).thenAnswer((_) async => htmlLyrics);

      final result = await service.getLyricsForTrack('track-2', 'Baadal');
      expect(result.isOk, isTrue);

      final lyrics = result.valueOrNull!;
      expect(lyrics.plainLyrics, isNotNull);
      expect(lyrics.plainLyrics, contains("duaa'"));
    });

    test('handles empty or unavailable lyrics safely without throwing', () async {
      when(() => mockClient.fetchLyrics('Unknown')).thenAnswer((_) async => null);

      final result = await service.getLyricsForTrack('track-3', 'Unknown');
      expect(result.isOk, isTrue);

      final lyrics = result.valueOrNull!;
      expect(lyrics.trackId, equals('track-3'));
      expect(lyrics.plainLyrics, isNull);
      expect(lyrics.syncedLines, isEmpty);
      expect(lyrics.isSynced, isFalse);
    });
  });
}
