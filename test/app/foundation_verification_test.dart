import 'package:echo_bloom/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EchoBloomApp mounts FoundationVerificationView and displays subsystem status', (tester) async {
    final container = ProviderContainer();

    await tester.pumpWidget(
      EchoBloomApp(
        container: container,
        home: const FoundationVerificationView(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FoundationVerificationView), findsOneWidget);
    expect(find.text('Echo Bloom — Foundation Architecture'), findsOneWidget);
    expect(find.text('Core Foundation Reconstructed & Ready'), findsOneWidget);
    expect(find.text('Local SQLite Database'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);

    container.dispose();
  });
}
