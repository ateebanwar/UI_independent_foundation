import 'package:echo_bloom/domain/entities/track.dart';

/// Lightweight provider contract for remote online music services (JioSaavn, Gaana).
abstract class RemoteMusicProvider {
  String get id;
  String get displayName;
  Future<List<Track>> search(String query);
  Future<String> resolveStreamUri({Track? track, String? trackIdOrQuery});
}
