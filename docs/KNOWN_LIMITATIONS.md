# KNOWN LIMITATIONS & EXTERNAL DEPENDENCY CONSTRAINTS
## Echo Bloom — System Constraints & Operational Boundaries

**Author:** Principal Software Architect  
**Project:** `d:\FLutter\redesign UI`  
**Date:** 2026-11-09  

---

## 1. Third-Party Remote API Dependencies

Echo Bloom utilizes reverse-engineered API endpoints for online music discovery:
- **JioSaavn Unofficial API (`saavnapi-nine.vercel.app`):** Hosted on Vercel serverless edge infrastructure. While reliable for standard queries, high-frequency automated requests may encounter transient HTTP 429 (Too Many Requests).
- **Gaana API (`shnwazdev-gaana-api.vercel.app`):** Acts as fallback. In regions where Gaana geo-blocks certain regional soundtracks, stream resolution may require fallback to JioSaavn or standard local audio.
- **Remediation Implemented:**
  - Strict 8-second request timeouts.
  - Automatic fallback between JioSaavn and Gaana.
  - In-memory search result caching (LRU, 35 entries).
  - Offline mode isolation guaranteeing zero remote network calls when offline.

---

## 2. Platform-Specific Constraints

### 2.1 Android Battery Optimization & OEM Background Execution
- **Issue:** Modern Android OEM distributions (e.g. Xiaomi MIUI/HyperOS, Samsung OneUI, OnePlus OxygenOS, Oppo ColorOS) enforce aggressive process killers on background tasks.
- **Foundation Mitigation:** The foundation architecture is structured to attach to a foreground Android audio service with a persistent notification (`startForegroundService`) and wake-lock acquisition during playback.
- **User Instruction Needed in UI:** Advise users to whitelist Echo Bloom under Android's "Battery Optimization -> Don't Optimize" setting for uninterrupted multi-hour background playback.

### 2.2 Android 13+ Granular Media Permissions (`READ_MEDIA_AUDIO`)
- Android 13 (API Level 33) and Android 14+ replaced legacy `READ_EXTERNAL_STORAGE` with `READ_MEDIA_AUDIO`.
- **Mitigation:** The `permission_handler` configuration in `AndroidManifest.xml` declares both `READ_MEDIA_AUDIO` and `READ_EXTERNAL_STORAGE` (with `maxSdkVersion=32`) to ensure full backwards and forwards compatibility across all Android versions.

### 2.3 Web Browser Sandboxing
- Web browsers strictly isolate JavaScript/WASM from the host file system.
- Direct recursive scanning of user music folders (`/sdcard/Music` or `C:\Users\...\Music`) is not permitted in web environments.
- **Mitigation:** On Web, the media scanner returns an empty list gracefully (`PLATFORM LIMITED`), directing users to upload files via the HTML5 File API or stream online catalog tracks.

### 2.4 Desktop (Windows) DSP Capabilities
- Android provides native hardware audiofx equalization via `android.media.audiofx.Equalizer`.
- Windows standard MCI/WinMM provides master and channel volume control, but lacks a built-in OS equalizer API.
- **Mitigation:** Windows audio engine applies software-level gain attenuation curves across streams.

---

## 3. Storage & Download Bounds

- File system write failures may occur if the user's physical internal storage is completely exhausted (< 50 MB remaining).
- **Mitigation:** `DownloadManager` performs disk space pre-checks prior to initializing multi-track batch downloads and halts gracefully with `StorageFailure` if disk space is insufficient.
