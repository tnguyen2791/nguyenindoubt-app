import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/common_widgets.dart';
import 'package:nguyenindoubt_app/screens/data_displays.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

/// Phase 14 drill-down coverage: the real readiness Today hero opens the
/// Readiness detail (28), the Sleep card opens the Sleep detail (21), the
/// education InfoTips are present, and the clinician never sees readiness.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> completeOnboarding(WidgetTester tester) async {
    final getStarted = find.text('Get started');
    await tester.ensureVisible(getStarted);
    await tester.pumpAndSettle();
    await tester.tap(getStarted);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex Nguyen');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Today readiness hero opens the Readiness detail with contributors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = NguyenInDoubtState(
        repository: InMemoryAppRepository(),
        healthDataProvider: MockHealthDataProvider(),
      );

      await tester.pumpWidget(
        NguyenInDoubtApp(state: state, showSplash: false),
      );
      await tester.pumpAndSettle();
      await completeOnboarding(tester);

      await state.importMockSleep();
      await tester.pumpAndSettle();

      // The hero shows the real readiness and is tappable.
      expect(state.readiness, isNotNull);
      final readiness = state.readiness!;
      expect(find.text('READINESS'), findsOneWidget);

      await tester.tap(find.text('READINESS'));
      await tester.pumpAndSettle();

      // The detail screen (28): its own app bar title, the full contributor
      // list, the observational headnote, and a ring.
      expect(find.widgetWithText(AppBar, 'Readiness'), findsOneWidget);
      expect(find.text('CONTRIBUTORS'), findsWidgets);
      expect(find.text('not a diagnosis'), findsOneWidget);
      expect(find.byType(ScoreRing), findsOneWidget);

      // Every model contributor is named on the detail screen.
      for (final contributor in readiness.contributors) {
        expect(
          find.text(contributor.name),
          findsOneWidget,
          reason: '${contributor.name} contributor row must render',
        );
      }
    },
  );

  testWidgets('a readiness contributor InfoTip opens a reassuring card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await state.importMockSleep();
    await tester.pumpAndSettle();

    await tester.tap(find.text('READINESS'));
    await tester.pumpAndSettle();

    // HRV balance carries an educational InfoTip (unfamiliar signal).
    expect(find.text('HRV balance'), findsOneWidget);
    final tip = find.byType(InfoTip).first;
    await tester.ensureVisible(tip);
    await tester.pumpAndSettle();
    await tester.tap(tip);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    // Voice check: no exclamation marks in the educational body.
    final dialogText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data ?? '')
        .join(' ');
    expect(dialogText.contains('!'), isFalse);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the Sleep card opens the Sleep detail with the honest trend', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);
    await state.importMockSleep();
    await tester.pumpAndSettle();

    // The 'last night' mini-card opens the Sleep detail (21).
    final dashboardScrollable = find.byType(Scrollable).first;
    final lastNight = find.text('LAST NIGHT');
    await tester.scrollUntilVisible(
      lastNight,
      200,
      scrollable: dashboardScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(lastNight);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Sleep'), findsOneWidget);
    // Sleep detail is sleep-only + honest: the reused 7-night trend legend.
    expect(find.text('SLEEP TREND · 7 NIGHTS'), findsOneWidget);
    expect(find.text('5h short'), findsOneWidget);
    expect(find.text('8h+ optimal'), findsOneWidget);
    expect(find.text('Total sleep'), findsOneWidget);
    expect(find.text('not a diagnosis'), findsOneWidget);
    expect(find.byType(SleepTrendBars), findsOneWidget);
  });

  testWidgets('clinician surface never exposes readiness (sleep-only)', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a clinician"));
    await tester.pumpAndSettle();

    // Readiness is patient-only — the clinician state carries none, and the
    // readiness hero label never appears on the clinician surface.
    expect(state.readiness, isNull);
    expect(find.text('READINESS'), findsNothing);
  });
}
