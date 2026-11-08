import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/user_profile.dart';

/// Contract for local-only user profile persistence and setup completion state.
abstract class UserProfileRepository {
  Future<Result<UserProfile?, Failure>> getProfile();
  Future<Result<void, Failure>> saveProfile(UserProfile profile);
  Future<Result<bool, Failure>> isSetupCompleted();
  Future<Result<void, Failure>> setSetupCompleted(bool completed);
}
