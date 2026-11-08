import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/equalizer_configuration.dart';

/// Contract for persistent Equalizer configuration storage.
abstract class EqualizerRepository {
  Future<Result<EqualizerConfiguration, Failure>> getConfiguration();
  Future<Result<void, Failure>> saveConfiguration(EqualizerConfiguration configuration);
}
