import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/brand_splash.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';

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
    expect(find.text('Get started'), findsOneWidget);
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
    expect(find.text('Get started'), findsNothing);

    // The animation is finite, so a bounded settle completes without timeout.
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );

    // The signed-out onboarding is shown and the splash is gone.
    expect(find.text('Get started'), findsOneWidget);
    expect(find.byKey(BrandSplashGate.splashKey), findsNothing);
    expect(state.splashHasPlayed, isTrue);
  });

  testWidgets('splash wordmark renders NguyenInDoubt with an ember "In" span', (
    tester,
  ) async {
    final state = _freshState();

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    // Advance past the wordmark fade-in interval (0.55-0.95 of 3.5s) without
    // completing the splash, so the wordmark RichText is on screen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));

    // The wordmark is a single RichText: 'Nguyen' + 'In' + 'Doubt'.
    final wordmark = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText() == 'NguyenInDoubt' &&
          _hasEmberInSpan(widget.text),
    );
    expect(wordmark, findsOneWidget);
  });
}

/// True when the wordmark's inline spans include an "In" run painted ember
/// (the meaning-bearing accent, not a decorative divider).
bool _hasEmberInSpan(InlineSpan root) {
  var found = false;
  root.visitChildren((span) {
    if (span is TextSpan &&
        span.text == 'In' &&
        span.style?.color == NidColors.ember) {
      found = true;
    }
    return true;
  });
  return found;
}
