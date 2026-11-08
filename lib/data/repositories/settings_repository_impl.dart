import 'package:echo_bloom/core/constants/storage_keys.dart';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/logging/app_logger.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/app_mode.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/repositories/settings_repository.dart';
import 'package:echo_bloom/infrastructure/storage/key_value_store.dart';
import 'package:flutter/material.dart' hide RepeatMode;

/// Concrete implementation of [SettingsRepository] backed by [KeyValueStore].
class SettingsRepositoryImpl implements SettingsRepository {
  final KeyValueStore _store;
  final AppLogger? _logger;

  SettingsRepositoryImpl({
    required KeyValueStore store,
    AppLogger? logger,
  })  : _store = store,
        _logger = logger;

  @override
  Future<Result<String?, Failure>> getString(String key, {String? defaultValue}) async {
    try {
      final value = await _store.getString(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading string setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setString(String key, String value) async {
    try {
      await _store.setString(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing string setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<bool, Failure>> getBool(String key, {bool defaultValue = false}) async {
    try {
      final value = await _store.getBool(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading bool setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setBool(String key, bool value) async {
    try {
      await _store.setBool(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing bool setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<double, Failure>> getDouble(String key, {double defaultValue = 0.0}) async {
    try {
      final value = await _store.getDouble(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading double setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setDouble(String key, double value) async {
    try {
      await _store.setDouble(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing double setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<int, Failure>> getInt(String key, {int defaultValue = 0}) async {
    try {
      final value = await _store.getInt(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading int setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setInt(String key, int value) async {
    try {
      await _store.setInt(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing int setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<RepeatMode, Failure>> getSavedRepeatMode() async {
    final res = await getInt(StorageKeys.keyRepeatMode, defaultValue: 0);
    return res.when(
      ok: (val) => Result.ok(RepeatMode.values[val.clamp(0, RepeatMode.values.length - 1)]),
      err: (f) => Result.err(f),
    );
  }

  @override
  Future<Result<void, Failure>> saveRepeatMode(RepeatMode mode) async {
    return await setInt(StorageKeys.keyRepeatMode, mode.index);
  }

  @override
  Future<Result<bool, Failure>> getSavedShuffleMode() async {
    return await getBool(StorageKeys.keyShuffleMode, defaultValue: false);
  }

  @override
  Future<Result<void, Failure>> saveShuffleMode(bool enabled) async {
    return await setBool(StorageKeys.keyShuffleMode, enabled);
  }

  @override
  Future<Result<AppMode, Failure>> getAppMode() async {
    final res = await getInt(StorageKeys.keyAppMode, defaultValue: 0);
    return res.when(
      ok: (val) => Result.ok(AppMode.values[val.clamp(0, AppMode.values.length - 1)]),
      err: (f) => Result.err(f),
    );
  }

  @override
  Future<Result<void, Failure>> saveAppMode(AppMode mode) async {
    return await setInt(StorageKeys.keyAppMode, mode.index);
  }

  @override
  Future<Result<ThemeMode, Failure>> getThemeMode() async {
    final res = await getInt(StorageKeys.keyAppThemeMode, defaultValue: 1); // 1 = ThemeMode.light
    return res.when(
      ok: (val) => Result.ok(ThemeMode.values[val.clamp(0, ThemeMode.values.length - 1)]),
      err: (f) => Result.err(f),
    );
  }

  @override
  Future<Result<void, Failure>> saveThemeMode(ThemeMode mode) async {
    return await setInt(StorageKeys.keyAppThemeMode, mode.index);
  }
}
