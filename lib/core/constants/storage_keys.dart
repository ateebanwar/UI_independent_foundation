/// Centralized key constants for local storage, settings, and database metadata.
abstract final class StorageKeys {
  static const String databaseName = 'sound_foundry_v1.db';
  static const int databaseVersion = 3;

  // Settings keys
  static const String keyAudioQuality = 'settings_audio_quality';
  static const String keyRepeatMode = 'settings_repeat_mode';
  static const String keyShuffleMode = 'settings_shuffle_mode';
  static const String keyVolumeLevel = 'settings_volume_level';
  static const String keyLastPlayedTrackId = 'playback_last_played_track_id';
  static const String keyLastPlaybackPositionMs = 'playback_last_position_ms';
  static const String keyAppThemeMode = 'settings_theme_mode';
  static const String keyAppMode = 'settings_app_mode';
  static const String keyEqualizerConfig = 'settings_equalizer_config';
  static const String keyUserProfile = 'user_profile_data';
  static const String keyUserProfileCompleted = 'user_profile_completed';
}

