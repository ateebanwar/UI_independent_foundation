import 'package:echo_bloom/core/types/pagination.dart';
import 'package:echo_bloom/domain/entities/album.dart';
import 'package:echo_bloom/domain/entities/artist.dart';
import 'package:echo_bloom/domain/entities/playlist.dart';
import 'package:echo_bloom/domain/entities/track.dart';

/// Contract for remote music catalog, discovery, and streaming endpoints.
abstract class RemoteMusicDataSource {
  Future<PaginatedList<Track>> fetchTracks(PageQuery query);
  Future<Track?> fetchTrackById(String id);
  Future<List<Track>> searchRemoteCatalog(String query, {int page = 1, int limit = 20});
  Future<List<Artist>> fetchArtists([String? query]);
  Future<List<Album>> fetchAlbums([String? query]);
  Future<List<Track>> fetchAlbumTracks(String albumUrlOrId);
  Future<List<Playlist>> fetchDiscoveryPlaylists();
  Future<List<Track>> fetchPlaylistTracks(String playlistIdOrQuery);
  Future<String> resolveStreamUri(String trackIdOrUri, [Track? track]);
}

