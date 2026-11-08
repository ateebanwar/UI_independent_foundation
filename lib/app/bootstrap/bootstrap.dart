import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/app/bootstrap/environment_bootstrap.dart';
import 'package:echo_bloom/app/startup/startup_coordinator.dart';
import 'package:echo_bloom/app/startup/startup_task.dart';
import 'package:echo_bloom/core/logging/console_logger.dart';
import 'package:echo_bloom/data/local/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Critical database initialization startup task.
class DatabaseInitTask implements StartupTask {
  final AppDatabase _database;

  DatabaseInitTask(this._database);

  @override
  String get name => 'DatabaseInitialization';

  @override
  StartupPriority get priority => StartupPriority.critical;

  @override
  Future<void> execute() async {
    await _database.initialize();
  }
}

/// Orchestrates complete application bootstrap sequence.
abstract final class AppBootstrap {
  static Future<ProviderContainer> bootstrap() async {
    // 1. Environment & Config
    final appConfig = await EnvironmentBootstrap.initialize();
    final logger = ConsoleLogger(
      enableInRelease: appConfig.buildConfig.enableVerboseLogging,
    );

    logger.info('Bootstrapping ${appConfig.buildConfig.appName}...', tag: 'AppBootstrap');

    // 2. Build Database & Services for Startup
    final appDatabase = AppDatabase(logger: logger);

    // 3. Coordinate Startup Tasks
    final coordinator = StartupCoordinator(logger: logger);
    coordinator.registerTask(DatabaseInitTask(appDatabase));

    // Execute critical tasks synchronously before app mount
    await coordinator.runCriticalTasks();

    // 4. Create Riverpod ProviderContainer with overrides
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
        loggerProvider.overrideWithValue(logger),
        appDatabaseProvider.overrideWithValue(appDatabase),
      ],
    );

    // 5. Execute background tasks non-blockingly
    coordinator.runBackgroundTasks();

    return container;
  }
}

