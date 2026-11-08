/// Severity levels for application logging.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Abstract contract for logging across the application.
abstract class AppLogger {
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace});
}
