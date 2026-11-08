import 'dart:async';
import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/domain/entities/app_mode.dart';
import 'package:echo_bloom/domain/entities/playback_state.dart';
import 'package:echo_bloom/domain/repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState extends Equatable {
  final bool isLoading;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final double volume;
  final String audioQuality;
  final ThemeMode themeMode;
  final AppMode appMode;

  const SettingsState({
    this.isLoading = false,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.volume = 1.0,
    this.audioQuality = 'high',
    this.themeMode = ThemeMode.light,
    this.appMode = AppMode.offline,
  });

  SettingsState copyWith({
    bool? isLoading,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    double? volume,
    String? audioQuality,
    ThemeMode? themeMode,
    AppMode? appMode,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      volume: volume ?? this.volume,
      audioQuality: audioQuality ?? this.audioQuality,
      themeMode: themeMode ?? this.themeMode,
      appMode: appMode ?? this.appMode,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        repeatMode,
        isShuffleEnabled,
        volume,
        audioQuality,
        themeMode,
        appMode,
      ];
}

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepository;
  int _themeSaveCounter = 0;

  SettingsController(this._settingsRepository) : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final repeatRes = await _settingsRepository.getSavedRepeatMode();
    final shuffleRes = await _settingsRepository.getSavedShuffleMode();
    final appModeRes = await _settingsRepository.getAppMode();
    final themeModeRes = await _settingsRepository.getThemeMode();

    state = state.copyWith(
      repeatMode: repeatRes.valueOrNull ?? RepeatMode.off,
      isShuffleEnabled: shuffleRes.valueOrNull ?? false,
      appMode: appModeRes.valueOrNull ?? AppMode.offline,
      themeMode: themeModeRes.valueOrNull ?? ThemeMode.light,
    );
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    state = state.copyWith(repeatMode: mode);
    unawaited(_settingsRepository.saveRepeatMode(mode));
  }

  Future<void> setShuffleMode(bool enabled) async {
    state = state.copyWith(isShuffleEnabled: enabled);
    unawaited(_settingsRepository.saveShuffleMode(enabled));
  }

  Future<void> setAppMode(AppMode mode) async {
    state = state.copyWith(appMode: mode);
    unawaited(_settingsRepository.saveAppMode(mode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final requestCounter = ++_themeSaveCounter;

    unawaited(() async {
      try {
        await _settingsRepository.saveThemeMode(mode);
        if (_themeSaveCounter != requestCounter) {
          await _settingsRepository.saveThemeMode(state.themeMode);
        }
      } catch (_) {}
    }());
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return SettingsController(settingsRepo);
});

final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(settingsControllerProvider.select((s) => s.themeMode));
  return themeMode == ThemeMode.dark;
});

