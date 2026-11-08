# DEPENDENCY AUDIT & RUNTIME PACKAGE INVENTORY
## Echo Bloom — Reusable Music Player Foundation

**Author:** Principal Software Architect  
**Project:** `d:\FLutter\redesign UI`  
**Date:** 2026-11-09  

---

## 1. Executive Dependency Summary

The Echo Bloom foundation adheres to a strict zero-bloat dependency policy. Every package in `pubspec.yaml` was scrutinized for licensing, bundle size overhead, native plugin footprint, and necessity for headless music player functionality.

Monolithic UI kits, animation libraries, heavy icon packs, and analytics SDKs have been completely excluded.

---

## 2. Complete Dependency Inventory

| Package Name | Specified Version | Resolved Version | License | Justification & Architectural Role | Native Plugin Overhead |
| :--- | :---: | :---: | :---: | :--- | :---: |
| **`flutter_riverpod`** | `^2.6.1` | 2.6.1 | MIT | Reactive state management, dependency injection, UI-independent state streams. | Pure Dart (0 KB native) |
| **`sqflite`** | `^2.4.1` | 2.4.1 | BSD-2-Clause | Android/iOS native SQLite persistence engine with WAL support. | Minimal C/JNI (~450 KB) |
| **`sqflite_common_ffi`**| `^2.3.4+4` | 2.3.4+4 | BSD-2-Clause | Windows/Linux native SQLite FFI bindings for desktop testing and execution. | Desktop only (0 KB mobile) |
| **`sqflite_common_ffi_web`**| `^0.4.3+4` | 0.4.5+4 | BSD-2-Clause | WebAssembly SQLite binding for browser execution. | Web only (0 KB mobile) |
| **`path`** | `^1.9.1` | 1.9.1 | BSD-3-Clause | Safe file system path manipulation and cross-platform path normalization. | Pure Dart (0 KB native) |
| **`path_provider`** | `^2.1.5` | 2.1.5 | BSD-3-Clause | OS-sanctioned directory resolution (cache, documents, external music storage). | Lightweight Java (~35 KB) |
| **`equatable`** | `^2.0.7` | 2.0.7 | MIT | Value equality comparison for domain entities (`Track`, `Playlist`, `State`). | Pure Dart (0 KB native) |
| **`uuid`** | `^4.5.1` | 4.5.1 | MIT | Cryptographically random unique IDs for download tasks, sessions, and playlists. | Pure Dart (0 KB native) |
| **`permission_handler`**| `^11.3.1` | 11.4.0 | MIT | Runtime permission queries for Android audio, storage, and notification access. | Lightweight Android (~65 KB) |
| **`image_picker`** | `^1.1.2` | 1.1.2 | BSD-3-Clause | Headless contract for picking custom playlist cover art and user profile avatars. | Android Activity (~80 KB) |
| **`http`** | `^1.3.0` | 1.3.0 | BSD-3-Clause | Streaming HTTP client for chunked downloads, JioSaavn/Gaana API queries. | Pure Dart (0 KB native) |
| **`web`** | `^1.1.1` | 1.1.1 | BSD-3-Clause | Modern Dart interop for Web Audio API (`AudioContext`, `BiquadFilterNode`). | Web only (0 KB mobile) |
| **`ffi`** | `^2.1.3` | 2.1.3 | BSD-3-Clause | C-interop bindings for Windows desktop audio and native system calls. | Pure Dart (0 KB mobile) |

### Development & Test Dependencies
- **`flutter_test`:** Flutter SDK testing harness.
- **`flutter_lints` (`^5.0.0`):** Strict static analysis rules.
- **`mocktail` (`^1.0.4`):** Type-safe mock library for repository and client tests without code generation.

---

## 3. Eliminated Redundancies & Anti-Bloat Strategy

1. **Zero UI/Widget Libraries:** No Google Fonts runtime downloading, Lottie animations, Cupertino/Material widgets, or heavy visual chart packages are linked.
2. **Icon Tree-Shaking:** Flutter's built-in icon tree-shaker pruned the default `MaterialIcons-Regular.otf` font from **1,645 KB down to 1.7 KB (99.9% reduction)**.
3. **No Heavy Analytical SDKs:** Zero tracking, Firebase, or advertising SDKs.
4. **ABI Split Native Overhead:** Instead of bundling `armeabi-v7a`, `arm64-v8a`, and `x86_64` `.so` files into a single fat 45 MB APK, ABI splits isolate only the required binary for each CPU architecture, saving ~20-25 MB per user install.

