/// Centralized application constants.
abstract final class AppConstants {
  static const String appName = 'Echo Bloom';
  static const String appSubtitle = 'Let your music bloom';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String packageName = 'com.antigravity.echo_bloom';

  // Audio Playback Constants
  static const Duration seekIncrement = Duration(seconds: 10);
  static const Duration bufferDurationThreshold = Duration(seconds: 2);
  static const Duration notificationUpdateThrottle = Duration(milliseconds: 500);

  // Pagination & Storage limits
  static const int defaultPageSize = 50;
  static const int maxRecentHistoryItems = 100;
  static const int maxSearchHistoryItems = 20;
}
