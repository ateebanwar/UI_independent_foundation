import 'dart:io';
import 'package:echo_bloom/app/app.dart';
import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/user_profile.dart';
import 'package:echo_bloom/domain/repositories/user_profile_repository.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/create_profile_screen.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/splash_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  @override
  Future<Result<UserProfile?, Failure>> getProfile() async => const Result.ok(null);

  @override
  Future<Result<void, Failure>> saveProfile(UserProfile userProfile) async => const Result.ok(null);

  @override
  Future<Result<bool, Failure>> isSetupCompleted() async => const Result.ok(false);

  @override
  Future<Result<void, Failure>> setSetupCompleted(bool completed) async => const Result.ok(null);
}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.contains('lyrithm_logo.png')) {
      final candidates = [
        File('assets/images/lyrithm_logo.png'),
        File('d:/FLutter/redesign UI/assets/images/lyrithm_logo.png'),
      ];
      for (final f in candidates) {
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          return ByteData.sublistView(Uint8List.fromList(bytes));
        }
      }
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('Capture Splash Screen at reference resolution 405x811',
      (tester) async {
    tester.view.physicalSize = const Size(405, 811);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(FakeUserProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    final assetBundle = TestAssetBundle();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: assetBundle,
        child: EchoBloomApp(
          container: container,
          home: const SplashWelcomeScreen(),
        ),
      ),
    );

    // Precache all Image widgets
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final widget = element.widget as Image;
        await precacheImage(widget.image, element);
      }
    });

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SplashWelcomeScreen),
      matchesGoldenFile('goldens/captured_splash.png'),
    );
  });

  testWidgets('Capture Create Profile Screen at reference resolution 405x811',
      (tester) async {
    tester.view.physicalSize = const Size(405, 811);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(FakeUserProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    final assetBundle = TestAssetBundle();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: assetBundle,
        child: EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CreateProfileScreen),
      matchesGoldenFile('goldens/captured_profile.png'),
    );
  });
}
