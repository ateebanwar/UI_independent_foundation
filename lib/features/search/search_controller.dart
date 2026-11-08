import 'dart:async';
import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/data/remote/clients/jiosaavn_client.dart';
import 'package:echo_bloom/domain/entities/album.dart';
import 'package:echo_bloom/domain/entities/app_mode.dart';
import 'package:echo_bloom/domain/entities/artist.dart';
import 'package:echo_bloom/domain/entities/playlist.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:echo_bloom/domain/repositories/playback_repository.dart';
import 'package:echo_bloom/domain/repositories/track_repository.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SearchCategory {
  all,
  songs,
  artists,
  albums,
  playlists,
}

class SearchState extends Equatable {
  final String query;
  final SearchCategory category;
  final bool isSearching;
  final List<Track> localResults;
  final List<Track> remoteResults;
  final List<Artist> artistResults;
  final List<Album> albumResults;
  final List<Playlist> playlistResults;
  final String? errorMessage;
  final String? statusMessage;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const SearchState({
    this.query = '',
    this.category = SearchCategory.all,
    this.isSearching = false,
    this.localResults = const [],
    this.remoteResults = const [],
    this.artistResults = const [],
    this.albumResults = const [],
    this.playlistResults = const [],
    this.errorMessage,
    this.statusMessage,
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  SearchState copyWith({
    String? query,
    SearchCategory? category,
    bool? isSearching,
    List<Track>? localResults,
    List<Track>? remoteResults,
    List<Artist>? artistResults,
    List<Album>? albumResults,
    List<Playlist>? playlistResults,
    String? errorMessage,
    String? statusMessage,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      isSearching: isSearching ?? this.isSearching,
      localResults: localResults ?? this.localResults,
      remoteResults: remoteResults ?? this.remoteResults,
      artistResults: artistResults ?? this.artistResults,
      albumResults: albumResults ?? this.albumResults,
      playlistResults: playlistResults ?? this.playlistResults,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        query,
        category,
        isSearching,
        localResults,
        remoteResults,
        artistResults,
        albumResults,
        playlistResults,
        errorMessage,
        statusMessage,
        page,
        hasMore,
        isLoadingMore,
      ];
}

class SearchController extends StateNotifier<SearchState> {
  final TrackRepository _trackRepository;
  final JioSaavnClient _jioSaavnClient = JioSaavnClient();
  AppMode _appMode;
  Timer? _debounceTimer;
  int _searchSequence = 0;

  SearchController(this._trackRepository, [this._appMode = AppMode.offline])
      : super(const SearchState());

  void setAppMode(AppMode mode) {
    if (_appMode != mode) {
      _appMode = mode;
      if (state.query.isNotEmpty) {
        search(state.query, immediate: true);
      }
    }
  }

  void setCategory(SearchCategory newCategory) {
    if (state.category != newCategory) {
      state = state.copyWith(category: newCategory);
    }
  }

  Future<void> search(String query, {bool immediate = false}) async {
    final trimmed = JioSaavnClient.normalizeQuery(query);
    if (trimmed.isEmpty) {
      _debounceTimer?.cancel();
      state = state.copyWith(
        query: '',
        localResults: const [],
        remoteResults: const [],
        artistResults: const [],
        albumResults: const [],
        playlistResults: const [],
        isSearching: false,
        page: 1,
        hasMore: false,
        isLoadingMore: false,
        clearError: true,
        clearStatus: true,
      );
      return;
    }

    _debounceTimer?.cancel();

    if (immediate || _appMode == AppMode.offline) {
      await _executeSearch(trimmed);
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _executeSearch(trimmed);
      });
    }
  }

  Future<void> _executeSearch(String trimmed) async {
    final sequence = ++_searchSequence;

    state = state.copyWith(
      query: trimmed,
      isSearching: true,
      statusMessage: _appMode == AppMode.online ? 'Searching online catalog...' : 'Searching library...',
      clearError: true,
    );

    if (_appMode == AppMode.offline) {
      final localRes = await _trackRepository.searchTracks(trimmed);
      if (sequence != _searchSequence) return;

      final tracks = localRes.valueOrNull ?? [];
      final artists = _jioSaavnClient.extractArtists(tracks);
      final albums = _jioSaavnClient.extractAlbums(tracks);

      state = state.copyWith(
        isSearching: false,
        localResults: tracks,
        remoteResults: const [],
        artistResults: artists,
        albumResults: albums,
        playlistResults: const [],
        page: 1,
        hasMore: tracks.length >= 20,
        isLoadingMore: false,
        errorMessage: localRes.failureOrNull?.message,
        clearStatus: true,
      );
    } else {
      final remoteRes = await _trackRepository.searchRemoteTracks(trimmed);
      if (sequence != _searchSequence) return;

      final tracks = remoteRes.valueOrNull ?? [];
      final failure = remoteRes.failureOrNull;

      final artists = _jioSaavnClient.extractArtists(tracks);
      final albums = _jioSaavnClient.extractAlbums(tracks);

      List<Playlist> matchedPlaylists = [];
      try {
        final discoveryPlaylistsRes = await _trackRepository.getDiscoveryPlaylists();
        final List<Playlist> allDiscovery = discoveryPlaylistsRes.valueOrNull ?? <Playlist>[];
        matchedPlaylists = allDiscovery.where((p) {
          final lower = trimmed.toLowerCase();
          final nameMatches = p.name.toLowerCase().contains(lower);
          final descMatches = p.description?.toLowerCase().contains(lower) ?? false;
          return nameMatches || descMatches;
        }).toList();
        if (matchedPlaylists.isEmpty && allDiscovery.isNotEmpty) {
          matchedPlaylists = allDiscovery.take(3).toList();
        }
      } catch (_) {}

      state = state.copyWith(
        isSearching: false,
        remoteResults: tracks,
        localResults: const [],
        artistResults: artists,
        albumResults: albums,
        playlistResults: matchedPlaylists,
        page: 1,
        hasMore: tracks.length >= 10,
        isLoadingMore: false,
        errorMessage: failure != null && tracks.isEmpty
            ? 'Unable to search online music right now. Please check your network connection.'
            : null,
        clearStatus: true,
      );
    }
  }

  /// Loads the next page of search results for paginated exploration.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore || state.isSearching || state.query.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      if (_appMode == AppMode.offline) {
        final res = await _trackRepository.searchTracks(state.query);
        final allTracks = res.valueOrNull ?? [];
        final offset = state.localResults.length;
        final nextSlice = allTracks.skip(offset).take(20).toList();
        if (nextSlice.isEmpty) {
          state = state.copyWith(isLoadingMore: false, hasMore: false);
        } else {
          state = state.copyWith(
            isLoadingMore: false,
            page: nextPage,
            hasMore: allTracks.length > (offset + nextSlice.length),
            localResults: [...state.localResults, ...nextSlice],
          );
        }
      } else {
        final res = await _trackRepository.searchRemoteTracks(state.query);
        final tracks = res.valueOrNull ?? [];
        final existingIds = state.remoteResults.map((t) => t.id).toSet();
        final newTracks = tracks.where((t) => !existingIds.contains(t.id)).toList();
        state = state.copyWith(
          isLoadingMore: false,
          page: nextPage,
          hasMore: false,
          remoteResults: [...state.remoteResults, ...newTracks],
        );
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> playAll(List<Track> tracks, PlaybackRepository playbackRepo) async {
    if (tracks.isEmpty) return;
    await playbackRepo.setQueue(tracks, initialIndex: 0);
  }

  Future<void> queueAll(List<Track> tracks, PlaybackRepository playbackRepo) async {
    if (tracks.isEmpty) return;
    for (final track in tracks) {
      await playbackRepo.addToQueue(track);
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final trackRepo = ref.watch(trackRepositoryProvider);
  final settings = ref.watch(settingsControllerProvider);
  final controller = SearchController(trackRepo, settings.appMode);
  ref.listen<SettingsState>(settingsControllerProvider, (prev, next) {
    if (prev?.appMode != next.appMode) {
      controller.setAppMode(next.appMode);
    }
  });
  return controller;
});

final searchFocusTriggerProvider = StateProvider<bool>((ref) => false);

