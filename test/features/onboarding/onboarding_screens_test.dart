import 'package:echo_bloom/app/app.dart';
import 'package:echo_bloom/app/bootstrap/dependency_bootstrap.dart';
import 'package:echo_bloom/core/errors/failures.dart';
import 'package:echo_bloom/core/result/result.dart';
import 'package:echo_bloom/domain/entities/user_profile.dart';
import 'package:echo_bloom/domain/repositories/user_profile_repository.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/create_profile_screen.dart';
import 'package:echo_bloom/features/onboarding/presentation/screens/splash_welcome_screen.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/gender_selector_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/lyrithm_logo_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/neumorphic_avatar_widget.dart';
import 'package:echo_bloom/features/onboarding/presentation/widgets/theme_toggle_widget.dart';
import 'package:echo_bloom/features/profile/profile_controller.dart';
import 'package:echo_bloom/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? profile;
  bool setupCompleted = false;

  @override
  Future<Result<UserProfile?, StorageFailure>> getProfile() async {
    return Result.ok(profile);
  }

  @override
  Future<Result<void, StorageFailure>> saveProfile(UserProfile userProfile) async {
    profile = userProfile;
    setupCompleted = true;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool, StorageFailure>> isSetupCompleted() async {
    return Result.ok(setupCompleted);
  }

  @override
  Future<Result<void, StorageFailure>> setSetupCompleted(bool completed) async {
    setupCompleted = completed;
    return const Result.ok(null);
  }
}

void main() {
  late FakeUserProfileRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeUserProfileRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  }

  group('Phase 1 — Project Lyrithm Onboarding UI Tests', () {
    testWidgets('Screen 1 (SplashWelcomeScreen) renders all reference components accurately',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(container: container),
      );
      await tester.pumpAndSettle();

      // 1. Verify squircle 3D logo
      expect(find.byType(LyrithmLogoWidget), findsOneWidget);

      // 2. Verify Title and Tagline
      expect(find.text('Lyrithm'), findsOneWidget);
      expect(find.text('Let your music bloom.'), findsOneWidget);

      // 3. Verify Offline & Tracking badges
      expect(find.text('100% Offline'), findsOneWidget);
      expect(find.text('Zero Cloud Tracking'), findsOneWidget);

      // 4. Verify primary CTA button
      expect(find.text('Setup to Continue'), findsOneWidget);
      expect(find.text('→'), findsOneWidget);

      // 5. Verify theme toggle presence
      expect(find.byType(ThemeToggleWidget), findsOneWidget);
    });

    testWidgets('Tapping Setup to Continue navigates to Screen 2 (CreateProfileScreen)',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(container: container),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SplashWelcomeScreen), findsOneWidget);

      // Tap Setup to Continue
      await tester.tap(find.text('Setup to Continue'));
      await tester.pumpAndSettle();

      // Verify navigation to CreateProfileScreen
      expect(find.byType(CreateProfileScreen), findsOneWidget);
      expect(find.text('Create Profile'), findsOneWidget);
      expect(find.text('Stored 100% locally on your device. Never shared or uploaded.'), findsOneWidget);
    });

    testWidgets('Screen 2 (CreateProfileScreen) back button returns to SplashWelcomeScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(container: container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setup to Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateProfileScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Should be back at Splash
      expect(find.byType(SplashWelcomeScreen), findsOneWidget);
    });

    testWidgets('Screen 2 renders avatar, input fields, age indicator, gender pills, and continue button',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar & Photo link
      expect(find.byType(NeumorphicAvatarWidget), findsOneWidget);
      expect(find.text('Choose Profile Photo'), findsOneWidget);

      // Inputs
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Enter your name'), findsOneWidget);

      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('1/1/2006'), findsOneWidget);
      expect(find.textContaining('Age:'), findsOneWidget);

      // Gender selector
      expect(find.byType(GenderSelectorWidget), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Continue button
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Screen 2 gender selector switches selection correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Female'
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Verify widget rebuilds with Female selection
      final femaleFinder = find.widgetWithText(AnimatedContainer, 'Female');
      expect(femaleFinder, findsOneWidget);
    });

    testWidgets('Screen 2 validation prevents empty name submission and shows error',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Continue button is visible before tapping
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Error message should be displayed
      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('Screen 2 valid submission calls ProfileController and displays success feedback',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.widgetWithText(TextField, 'Enter your name'), 'Aria Stark');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Verify profile state updated
      final profileState = container.read(profileControllerProvider);
      expect(profileState.isSetupCompleted, isTrue);
      expect(profileState.profile?.name, 'Aria Stark');

      // Verify confirmation feedback
      expect(find.text('Profile saved locally. Welcome to Lyrithm!'), findsOneWidget);
    });

    testWidgets('Theme toggle switches between Day and Night modes seamlessly',
        (tester) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const SplashWelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day'), findsOneWidget);

      // Tap Theme toggle
      await tester.tap(find.byType(ThemeToggleWidget));
      await tester.pumpAndSettle();

      // Should now display 'Night'
      expect(find.text('Night'), findsOneWidget);
      expect(container.read(settingsControllerProvider).themeMode, ThemeMode.dark);

      // Tap again to switch back to Day
      await tester.tap(find.byType(ThemeToggleWidget));
      await tester.pumpAndSettle();

      expect(find.text('Day'), findsOneWidget);
      expect(container.read(settingsControllerProvider).themeMode, ThemeMode.light);
    });

    testWidgets('Zero overflow verification across Desktop / Microsoft Edge wide viewport (1280x800)',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = createContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        EchoBloomApp(
          container: container,
          home: const CreateProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Must render without any exception or overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(CreateProfileScreen), findsOneWidget);
      expect(find.text('Create Profile'), findsOneWidget);
    });
  });
}
