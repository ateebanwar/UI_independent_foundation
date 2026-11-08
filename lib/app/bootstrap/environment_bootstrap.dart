import 'package:echo_bloom/app/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Bootstraps Flutter engine bindings and environment configuration.
abstract final class EnvironmentBootstrap {
  static Future<AppConfig> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kReleaseMode) {
      return AppConfig.production();
    } else {
      return AppConfig.development();
    }
  }
}

