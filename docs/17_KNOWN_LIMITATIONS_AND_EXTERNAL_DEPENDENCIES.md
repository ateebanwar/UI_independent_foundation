# Known Limitations & External Dependencies

## 1. Third-Party API Endpoints

The online music catalog and stream extraction rely on public API endpoints:
- **JioSaavn API:** `https://saavnapi-nine.vercel.app`
- **Gaana API:** `https://gaana-api-two.vercel.app`

### Limitations & Mitigation
- **Server Cold-Starts:** Because these instances are hosted on Vercel serverless containers, cold-starts occasionally take 1-2 seconds. `ResilientHttpClient` mitigates this with exponential retries and caching.
- **Provider IP Blocks / Rate Limits:** If high query volume triggers HTTP 429, `ResilientHttpClient` honors the `Retry-After` header. If JioSaavn fails entirely, `RemoteMusicDataSourceImpl` automatically falls back to Gaana.
- **Self-Hosting:** Developers can self-host their own instance of Sumanjay's JioSaavn API or configure a custom proxy URL in `JioSaavnClient(baseUrl: '...')`.

---

## 2. Platform Permissions & Capabilities

### 2.1 Android
- **Local Audio Storage:** Requires `READ_MEDIA_AUDIO` on Android 13+ (API 33+) or `READ_EXTERNAL_STORAGE` on Android 12 and below. These are checked via `permission_handler`.
- **Hardware Equalizer:** Android hardware audio processing depends on the active device chipset. Custom ROMs or devices without `audiofx` libraries may fall back to default audio output.

### 2.2 Web (Browsers)
- **Autoplay Policies:** Browsers (Chrome, Safari, Firefox) prevent audio from playing before a user gesture (tap/click). The engine properly surfaces this as a pause state rather than crashing.
- **CORS:** Streaming audio endpoints require proper CORS headers (`Access-Control-Allow-Origin: *`).

### 2.3 iOS
- Background playback requires the `audio` background mode in `Info.plist`.

---

## 3. Storage & Database Integrity
- The SQLite database handles concurrent reads, but writes are synchronized sequentially. Batch operations should always use `db.transaction(...)`.
- `DatabaseBackupService` should be scheduled periodically to ensure user playlist recovery in case of catastrophic device hardware failure.

