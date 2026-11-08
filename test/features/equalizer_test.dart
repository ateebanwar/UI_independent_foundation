import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/equalizer_configuration.dart';
import 'package:echo_bloom/domain/entities/equalizer_preset.dart';
import 'package:echo_bloom/domain/repositories/equalizer_repository.dart';
import 'package:echo_bloom/features/equalizer/equalizer_controller.dart';
import 'package:echo_bloom/infrastructure/audio/audio_engine_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeEqualizerRepository implements EqualizerRepository {
  EqualizerConfiguration _config = const EqualizerConfiguration();

  @override
  Future<Result<EqualizerConfiguration, Failure>> getConfiguration() async => Result.ok(_config);

  @override
  Future<Result<void, Failure>> saveConfiguration(EqualizerConfiguration configuration) async {
    _config = configuration;
    return const Result.ok(null);
  }
}

void main() {
  group('Equalizer Domain & Controller Tests', () {
    test('EqualizerPreset has all default presets with 5 bands', () {
      expect(EqualizerPreset.defaultPresets.length, greaterThanOrEqualTo(5));
      for (final preset in EqualizerPreset.defaultPresets) {
        expect(preset.bandGains.length, equals(5));
      }
    });

    test('EqualizerConfiguration clamps min and max gains', () {
      expect(EqualizerConfiguration.minGain, equals(-12.0));
      expect(EqualizerConfiguration.maxGain, equals(12.0));
      expect(EqualizerConfiguration.bandLabels.length, equals(5));
    });

    test('EqualizerController updates band gains and informs AudioEngine', () async {
      final repo = FakeEqualizerRepository();
      final engine = AudioEngineImpl();
      final controller = EqualizerController(repository: repo, audioEngine: engine);

      await controller.loadConfiguration();
      expect(controller.state.configuration.bandGains, equals([0.0, 0.0, 0.0, 0.0, 0.0]));

      await controller.setBandGain(0, 6.5);
      expect(controller.state.configuration.bandGains[0], equals(6.5));
      expect(controller.state.configuration.activePresetId, equals('custom'));
      expect(engine.currentEqualizerGains[0], equals(6.5));

      final rockPreset = EqualizerPreset.defaultPresets.firstWhere((p) => p.id == 'rock');
      await controller.applyPreset(rockPreset);
      expect(controller.state.configuration.activePresetId, equals('rock'));
      expect(controller.state.configuration.bandGains, equals(rockPreset.bandGains));
      expect(engine.currentEqualizerGains, equals(rockPreset.bandGains));

      await controller.resetToFlat();
      expect(controller.state.configuration.bandGains, equals([0.0, 0.0, 0.0, 0.0, 0.0]));
      expect(controller.state.configuration.activePresetId, equals('flat'));
    });
  });
}

