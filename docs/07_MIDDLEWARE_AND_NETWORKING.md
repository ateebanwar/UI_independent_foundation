# Networking Middleware & Resilient HTTP Client

## 1. Design Overview

Network requests in music streaming applications require robust resilience against fluctuating connectivity, server rate limiting (HTTP 429), intermittent server failures (HTTP 5xx), and credential exposure in logs.

The foundation introduces [`ResilientHttpClient`](file:///d:/FLutter/redesign%20UI/lib/infrastructure/networking/resilient_http_client.dart), implementing a resilient HTTP layer around `http.Client`.

---

## 2. Key Middleware Capabilities

### 2.1 Exponential Backoff & Jittered Retries
When a network connection fails due to a `SocketException` or temporary server 5xx error, `ResilientHttpClient` automatically retries up to 3 times with exponential backoff:
$$\text{delay} = 2^{\text{attempt}} \times 500\text{ ms} + \text{jitter}(0 \dots 300\text{ ms})$$
This prevents the "thundering herd" problem and shields upstream streaming providers.

### 2.2 Rate Limit (HTTP 429) Handling
- When an API endpoint responds with HTTP 429, the middleware inspects the `Retry-After` header.
- The request pauses for the specified duration (capped at 5 seconds) before retrying.
- If repeated attempts remain rate-limited, it yields a graceful, user-friendly `NetworkFailure(message: 'Provider rate limit exceeded. Please wait a moment.', statusCode: 429)`.

### 2.3 URL & Sensitive Header Redaction
All logger statements filter and redact sensitive query parameters (e.g., `api_key`, `token`, `secret`, `auth`, `password`) so credentials are never leaked to logs or console outputs:
```dart
String _sanitizeUrl(Uri uri) {
  // Automatically masks api_key=***, token=***, etc.
}
```

### 2.4 TTL-Based In-Memory Caching
- Configurable response cache to prevent duplicate network calls for repeated queries within a short window (default 3 minutes).
- Significantly cuts cellular data consumption and speeds up autocomplete search suggestions.

---

## 3. Usage Example

```dart
final client = ResilientHttpClient(
  maxRetries: 3,
  timeout: const Duration(seconds: 12),
  logger: ConsoleLogger(),
);

final result = await client.getJson(
  Uri.parse('https://saavnapi-nine.vercel.app/result/?query=Khuda'),
  cacheDuration: const Duration(minutes: 5),
);

result.when(
  ok: (jsonMap) => print('Search results received: ${jsonMap.length} items'),
  err: (failure) => print('Handled failure: ${failure.message}'),
);
```

