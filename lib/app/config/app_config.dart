import 'package:echo_bloom/app/config/build_config.dart';
import 'package:echo_bloom/app/config/feature_flags.dart';

/// Top-level application runtime configuration.
class AppConfig {
  final BuildConfig buildConfig;
  final FeatureFlags featureFlags;
  final String? apiBaseUrl;

  const AppConfig({
    required this.buildConfig,
    required this.featureFlags,
    this.apiBaseUrl,
  });

  /// Factory for standard development configuration.
  factory AppConfig.development() {
    return const AppConfig(
      buildConfig: BuildConfig(
        environment: AppEnvironment.development,
        appName: 'Echo Bloom (Dev)',
        packageName: 'com.antigravity.echo_bloom.dev',
        version: '1.0.0',
        buildNumber: 1,
        enableVerboseLogging: true,
      ),
      featureFlags: FeatureFlags(
        enableRemoteSearch: true,
        enableLyrics: true,
        enableCloudSync: false,
        enableDownloads: true,
        enableRecommendations: false,
      ),
    );
  }

  /// Factory for standard production configuration.
  factory AppConfig.production() {
    return const AppConfig(
      buildConfig: BuildConfig(
        environment: AppEnvironment.production,
        appName: 'Echo Bloom',
        packageName: 'com.antigravity.echo_bloom',
        version: '1.0.0',
        buildNumber: 1,
        enableVerboseLogging: false,
      ),
      featureFlags: FeatureFlags(
        enableRemoteSearch: true,
        enableLyrics: true,
        enableCloudSync: false,
        enableDownloads: true,
        enableRecommendations: false,
      ),
    );
  }
}

