import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/infrastructure/networking/http_client.dart';
import 'package:http/http.dart' as http;

/// Bounded cache entry for HTTP GET responses.
class _CachedHttpResponse {
  final dynamic body;
  final DateTime expiresAt;

  _CachedHttpResponse(this.body, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Robust HTTP network client with request/response middleware,
/// exponential backoff retry, rate limit handling, sensitive redaction,
/// and in-memory TTL caching.
class ResilientHttpClient implements NetworkClient {
  final http.Client _client;
  final AppLogger? _logger;
  final Duration _defaultTimeout;
  final int _maxRetries;
  final Map<String, String> _defaultHeaders;
  final Map<String, _CachedHttpResponse> _cache = {};
  static const int _maxCacheEntries = 60;

  ResilientHttpClient({
    http.Client? client,
    AppLogger? logger,
    Duration defaultTimeout = const Duration(seconds: 8),
    int maxRetries = 2,
    Map<String, String>? defaultHeaders,
  })  : _client = client ?? http.Client(),
        _logger = logger,
        _defaultTimeout = defaultTimeout,
        _maxRetries = maxRetries,
        _defaultHeaders = defaultHeaders ?? {
          'Accept': 'application/json',
          'User-Agent': 'EchoBloom/2.0 (Mobile; Flutter; HeadlessFoundation)',
        };

  /// Redacts sensitive information (API keys, tokens) from URI queries or headers for secure logging.
  String redactSensitive(String text) {
    return text.replaceAll(RegExp(r'(key|token|auth|secret|password)=([^&]+)', caseSensitive: false), r'$1=REDACTED');
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? cacheDuration,
  }) async {
    final uri = Uri.parse(endpoint).replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );

    final cacheKey = uri.toString();
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      if (cached.body is Map<String, dynamic>) {
        return Result.ok(cached.body as Map<String, dynamic>);
      }
    }

    final mergedHeaders = Map<String, String>.from(_defaultHeaders);
    if (headers != null) mergedHeaders.addAll(headers);

    final safeUrl = redactSensitive(uri.toString());
    _logger?.info('HTTP GET Request: $safeUrl', tag: 'ResilientHttpClient');

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await _client.get(uri, headers: mergedHeaders).timeout(_defaultTimeout);

        // 1. Check HTTP Status
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final bodyStr = response.body.trim();
          if (bodyStr.isEmpty) {
            return const Result.ok(<String, dynamic>{});
          }
          final dynamic decoded = jsonDecode(bodyStr);
          if (decoded is Map<String, dynamic>) {
            if (cacheDuration != null && cacheDuration > Duration.zero) {
              if (_cache.length >= _maxCacheEntries) {
                _cache.remove(_cache.keys.first);
              }
              _cache[cacheKey] = _CachedHttpResponse(decoded, DateTime.now().add(cacheDuration));
            }
            return Result.ok(decoded);
          } else if (decoded is List) {
            return Result.ok(<String, dynamic>{'data': decoded});
          }
          return const Result.err(NetworkFailure(message: 'Malformed JSON response format'));
        }

        // 2. Handle Rate Limiting (429)
        if (response.statusCode == 429) {
          _logger?.warning('Rate limit hit (429) on $safeUrl', tag: 'ResilientHttpClient');
          if (attempt <= _maxRetries) {
            final retryAfterSec = int.tryParse(response.headers['retry-after'] ?? '2') ?? 2;
            await Future.delayed(Duration(seconds: min(retryAfterSec, 5)));
            continue;
          }
          return const Result.err(NetworkFailure(message: 'Provider rate limit exceeded. Please wait a moment.', statusCode: 429));
        }

        // 3. Client errors (4xx) - Non-retryable
        if (response.statusCode >= 400 && response.statusCode < 500) {
          _logger?.warning('HTTP ${response.statusCode} client error: $safeUrl', tag: 'ResilientHttpClient');
          return Result.err(NetworkFailure(message: 'Provider error (HTTP ${response.statusCode})', statusCode: response.statusCode));
        }

        // 4. Server errors (5xx) - Retryable
        if (response.statusCode >= 500 && attempt <= _maxRetries) {
          final backoffMs = (pow(2, attempt) * 500 + Random().nextInt(300)).toInt();
          _logger?.info('HTTP ${response.statusCode} server error. Retrying attempt $attempt in ${backoffMs}ms...', tag: 'ResilientHttpClient');
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        return Result.err(NetworkFailure(message: 'Remote server returned HTTP ${response.statusCode}', statusCode: response.statusCode));
      } on SocketException catch (e) {
        if (attempt <= _maxRetries) {
          final backoffMs = (pow(2, attempt) * 400).toInt();
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }
        return Result.err(NetworkFailure(message: 'Network connection unavailable: $e', cause: e));
      } on TimeoutException catch (e) {
        if (attempt <= _maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        return Result.err(NetworkFailure(message: 'Request timed out: $e', cause: e));
      } catch (e, stack) {
        _logger?.error('Unhandled network client error: $e', tag: 'ResilientHttpClient', error: e, stackTrace: stack);
        return Result.err(NetworkFailure(message: 'Network request error: $e', cause: e));
      }
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(endpoint);
    final mergedHeaders = Map<String, String>.from(_defaultHeaders);
    mergedHeaders['Content-Type'] = 'application/json';
    if (headers != null) mergedHeaders.addAll(headers);

    final safeUrl = redactSensitive(uri.toString());
    _logger?.info('HTTP POST Request: $safeUrl', tag: 'ResilientHttpClient');

    try {
      final response = await _client
          .post(uri, headers: mergedHeaders, body: jsonEncode(data ?? {}))
          .timeout(_defaultTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bodyStr = response.body.trim();
        if (bodyStr.isEmpty) return const Result.ok(<String, dynamic>{});
        final dynamic decoded = jsonDecode(bodyStr);
        if (decoded is Map<String, dynamic>) {
          return Result.ok(decoded);
        }
        return Result.ok(<String, dynamic>{'data': decoded});
      }
      return Result.err(NetworkFailure(message: 'Remote server returned HTTP ${response.statusCode}', statusCode: response.statusCode));
    } catch (e, stack) {
      _logger?.error('HTTP POST failed: $e', tag: 'ResilientHttpClient', error: e, stackTrace: stack);
      return Result.err(NetworkFailure(message: 'Network post error: $e', cause: e));
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void close() {
    _client.close();
  }
}
