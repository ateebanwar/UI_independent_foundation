import 'dart:async';
import 'dart:convert';
import 'package:echo_bloom/app/config/online_music_config.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/data/remote/clients/jiosaavn_client.dart';
import 'package:echo_bloom/domain/entities/track.dart';
import 'package:http/http.dart' as http;

/// Fallback client for Gaana unofficial API.
/// Performs fallback search and stream resolution.
class GaanaClient {
  final http.Client _httpClient;
  final AppLogger? _logger;

  GaanaClient({
    http.Client? httpClient,
    AppLogger? logger,
  })  : _httpClient = httpClient ?? http.Client(),
        _logger = logger;

  /// Searches Gaana catalog for matching tracks.
  Future<List<Track>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '${GaanaConfig.baseUrl}${GaanaConfig.searchEndpoint}?q=${Uri.encodeComponent(trimmed)}&type=song',
    );

    _logger?.info('Gaana fallback search requested: $uri', tag: 'GaanaClient');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(GaanaConfig.timeout);

      if (response.statusCode != 200) {
        _logger?.warning('Gaana returned non-200 status: ${response.statusCode}', tag: 'GaanaClient');
        return const [];
      }

      final responseBody = response.body;
      if (responseBody.trim().isEmpty || responseBody.startsWith('<') || responseBody.contains('DEPLOYMENT_DISABLED')) {
        _logger?.warning('Gaana returned non-JSON or disabled response', tag: 'GaanaClient');
        return const [];
      }

      final decoded = jsonDecode(responseBody);
      return parseTracks(decoded);
    } catch (e, stack) {
      _logger?.warning('Gaana fallback search failed: $e', tag: 'GaanaClient', error: e, stackTrace: stack);
      return const [];
    }
  }

  /// Resolves the actual playable stream URL for a Gaana track by its seokey.
  Future<String> resolveStreamUri(String seokey) async {
    final cleanKey = seokey.replaceFirst('gaana://stream?seokey=', '').trim();
    if (cleanKey.isEmpty) return '';

    final uri = Uri.parse(
      '${GaanaConfig.baseUrl}${GaanaConfig.streamEndpoint}?seokey=${Uri.encodeComponent(cleanKey)}',
    );

    _logger?.info('Gaana stream resolution requested: $uri', tag: 'GaanaClient');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/1.0 (Mobile; Flutter)',
        },
      ).timeout(GaanaConfig.timeout);

      if (response.statusCode != 200) {
        _logger?.warning('Gaana stream resolution non-200: ${response.statusCode}', tag: 'GaanaClient');
        return '';
      }

      final responseBody = response.body;
      if (responseBody.trim().isEmpty || responseBody.startsWith('<')) {
        return '';
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final streamUrl = (decoded['link'] ??
                decoded['stream'] ??
                decoded['stream_url'] ??
                decoded['audio_url'] ??
                decoded['hls_url'] ??
                '')
            .toString()
            .trim();
        return streamUrl;
      }
    } catch (e) {
      _logger?.warning('Gaana stream resolution exception: $e', tag: 'GaanaClient');
    }
    return '';
  }

  /// Safely parses raw Gaana JSON results into [Track] domain entities.
  List<Track> parseTracks(dynamic json) {
    final List<dynamic> rawList;
    if (json is List) {
      rawList = json;
    } else if (json is Map<String, dynamic>) {
      if (json['results'] is List) {
        rawList = json['results'] as List<dynamic>;
      } else if (json['data'] is List) {
        rawList = json['data'] as List<dynamic>;
      } else if (json['songs'] is List) {
        rawList = json['songs'] as List<dynamic>;
      } else {
        rawList = const [];
      }
    } else {
      rawList = const [];
    }

    final tracks = <Track>[];
    final now = DateTime.now();

    for (final item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final trackId = (map['track_id'] ?? map['id'] ?? map['seokey'] ?? '').toString().trim();
      final title = JioSaavnClient.unescapeHtml((map['title'] ?? map['track_title'] ?? map['song'] ?? '').toString());
      if (trackId.isEmpty && title.isEmpty) continue;

      final artist = JioSaavnClient.unescapeHtml(
        (map['artist'] ?? map['artists'] ?? map['primary_artist'] ?? 'Unknown Artist').toString(),
      );

      final album = map['album'] != null ? JioSaavnClient.unescapeHtml(map['album'].toString()) : null;

      final durationSec = int.tryParse(map['duration']?.toString() ?? '0') ?? 0;
      final duration = Duration(seconds: durationSec);

      final artworkUri = (map['artwork'] ?? map['image'] ?? map['albumart'])?.toString().trim();
      final seokey = (map['seokey'] ?? trackId).toString().trim();
      final streamUri = 'gaana://stream?seokey=$seokey';

      tracks.add(Track(
        id: 'gaana_$trackId',
        title: title.isNotEmpty ? title : 'Unknown Title',
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
        album: album,
        duration: duration,
        mediaUri: streamUri,
        sourceType: TrackSourceType.remoteStream,
        artworkUri: (artworkUri != null && artworkUri.isNotEmpty) ? artworkUri : null,
        dateAdded: now,
        remoteProvider: 'gaana',
        remoteProviderId: seokey,
      ));
    }

    return tracks;
  }
}
