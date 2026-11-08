import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/app_mode.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/track_repository.dart';
import 'package:echo_bloom/features/search/search_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  group('SearchController Tests — Mode Isolation & Online Integration', () {
    late MockTrackRepository mockRepo;
    late SearchController controller;

    final localTrack = Track(
      id: 'local_1',
      title: 'Local Song',
      artist: 'Local Artist',
      duration: const Duration(seconds: 200),
      mediaUri: '/storage/music/local.mp3',
      sourceType: TrackSourceType.localFile,
      dateAdded: DateTime.now(),
    );

    final remoteTrack = Track(
      id: 'jiosaavn_1',
      title: 'Remote Song',
      artist: 'Online Artist',
      duration: const Duration(seconds: 240),
      mediaUri: 'https://aac.saavncdn.com/online.mp4',
      sourceType: TrackSourceType.remoteStream,
      dateAdded: DateTime.now(),
    );

    setUp(() {
      mockRepo = MockTrackRepository();
    });

    test('In AppMode.offline: search queries ONLY local repository, ZERO remote calls', () async {
      when(() => mockRepo.searchTracks('Local')).thenAnswer((_) async => Result.ok([localTrack]));

      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('Local', immediate: true);

      expect(controller.state.localResults.length, 1);
      expect(controller.state.localResults.first.title, 'Local Song');
      expect(controller.state.remoteResults, isEmpty);

      verify(() => mockRepo.searchTracks('Local')).called(1);
      verifyNever(() => mockRepo.searchRemoteTracks(any()));
    });

    test('In AppMode.online: search queries remote tracks', () async {
      when(() => mockRepo.searchRemoteTracks('Online')).thenAnswer((_) async => Result.ok([remoteTrack]));

      controller = SearchController(mockRepo, AppMode.online);
      await controller.search('Online', immediate: true);

      expect(controller.state.remoteResults.length, 1);
      expect(controller.state.remoteResults.first.title, 'Remote Song');
      expect(controller.state.localResults, isEmpty);

      verify(() => mockRepo.searchRemoteTracks('Online')).called(1);
      verifyNever(() => mockRepo.searchTracks(any()));
    });

    test('Empty query resets state to default without calling repositories', () async {
      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('   ', immediate: true);

      expect(controller.state.query, '');
      expect(controller.state.localResults, isEmpty);
      expect(controller.state.remoteResults, isEmpty);
      verifyNever(() => mockRepo.searchTracks(any()));
      verifyNever(() => mockRepo.searchRemoteTracks(any()));
    });

    test('Switching AppMode updates search results for active query', () async {
      when(() => mockRepo.searchTracks('Song')).thenAnswer((_) async => Result.ok([localTrack]));
      when(() => mockRepo.searchRemoteTracks('Song')).thenAnswer((_) async => Result.ok([remoteTrack]));

      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('Song', immediate: true);
      expect(controller.state.localResults.length, 1);

      controller.setAppMode(AppMode.online);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.remoteResults.length, 1);
      expect(controller.state.remoteResults.first.title, 'Remote Song');
      expect(controller.state.localResults, isEmpty);
    });

    test('loadNextPage appends subsequent results and increments page count', () async {
      final manyTracks = List.generate(
        25,
        (i) => Track(
          id: 'track_$i',
          title: 'Track #$i',
          artist: 'Artist',
          duration: const Duration(seconds: 180),
          mediaUri: '/storage/music/track_$i.mp3',
          sourceType: TrackSourceType.localFile,
          dateAdded: DateTime.now(),
        ),
      );

      when(() => mockRepo.searchTracks('Track')).thenAnswer((_) async => Result.ok(manyTracks));

      controller = SearchController(mockRepo, AppMode.offline);
      await controller.search('Track', immediate: true);

      expect(controller.state.page, 1);
      expect(controller.state.hasMore, true);
      expect(controller.state.localResults.length, 25);

      await controller.loadNextPage();
      expect(controller.state.isLoadingMore, false);
    });

    test('Online loadNextPage requests next page and appends new unique remote tracks', () async {
      final page1Tracks = List.generate(
        10,
        (i) => Track(
          id: 'remote_page1_$i',
          title: 'Online Song P1 #$i',
          artist: 'Online Artist',
          duration: const Duration(seconds: 210),
          mediaUri: 'https://stream/p1_$i.mp4',
          sourceType: TrackSourceType.remoteStream,
          dateAdded: DateTime.now(),
        ),
      );

      final page2Tracks = List.generate(
        10,
        (i) => Track(
          id: 'remote_page2_$i',
          title: 'Online Song P2 #$i',
          artist: 'Online Artist',
          duration: const Duration(seconds: 210),
          mediaUri: 'https://stream/p2_$i.mp4',
          sourceType: TrackSourceType.remoteStream,
          dateAdded: DateTime.now(),
        ),
      );

      when(() => mockRepo.searchRemoteTracks('Pop', page: 1, limit: 20))
          .thenAnswer((_) async => Result.ok(page1Tracks));
      when(() => mockRepo.searchRemoteTracks('Pop', page: 2, limit: 20))
          .thenAnswer((_) async => Result.ok(page2Tracks));

      controller = SearchController(mockRepo, AppMode.online);
      await controller.search('Pop', immediate: true);

      expect(controller.state.page, 1);
      expect(controller.state.hasMore, true);
      expect(controller.state.remoteResults.length, 10);

      await controller.loadNextPage();

      expect(controller.state.page, 2);
      expect(controller.state.remoteResults.length, 20);
      expect(controller.state.isLoadingMore, false);
      verify(() => mockRepo.searchRemoteTracks('Pop', page: 2, limit: 20)).called(1);
    });
  });
}

