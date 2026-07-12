import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/brand_splash.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

NguyenInDoubtState _freshState() {
  return NguyenInDoubtState(
    repository: InMemoryAppRepository(),
    healthDataProvider: MockHealthDataProvider(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showSplash: false skips the splash and lands on onboarding', (
    tester,
  ) async {
    final state = _freshState();

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    // Onboarding surface is reachable immediately.
    expect(find.text('Patient sign up'), findsOneWidget);
    // No splash-only widget remains.
    expect(find.byKey(BrandSplashGate.splashKey), findsNothing);
  });

  testWidgets('showSplash: true plays the splash once then cross-fades to '
      'onboarding', (tester) async {
    final state = _freshState();
    expect(state.splashHasPlayed, isFalse);

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pump();

    // The splash renders first.
    expect(find.byKey(BrandSplashGate.splashKey), findsOneWidget);
    expect(find.text('Patient sign up'), findsNothing);

    // The animation is finite, so a bounded settle completes without timeout.
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );

    // The signed-out onboarding is shown and the splash is gone.
    expect(find.text('Patient sign up'), findsOneWidget);
    expect(find.byKey(BrandSplashGate.splashKey), findsNothing);
    expect(state.splashHasPlayed, isTrue);
  });
}
