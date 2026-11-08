import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';

/// Contract for networking operations.
/// Completely abstracts HTTP libraries from data sources and domain.
abstract class NetworkClient {
  Future<Result<Map<String, dynamic>, Failure>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<Result<Map<String, dynamic>, Failure>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  });
}

