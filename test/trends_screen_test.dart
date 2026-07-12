import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/data_displays.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

/// Drives onboarding then lands on the Today dashboard, ready to switch tabs.
Future<NguyenInDoubtState> _bootPatient(WidgetTester tester) async {
  final state = NguyenInDoubtState(
    repository: InMemoryAppRepository(),
    healthDataProvider: MockHealthDataProvider(),
  );
  await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Alex Nguyen');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _openTrends(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.bar_chart_outlined).first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Trends renders each segment and range with the deterministic mock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _bootPatient(tester);
      await state.importMockSleep();
      await tester.pumpAndSettle();

      // A quarter of readiness was scored + persisted from the mock, so the
      // Trends signals all have a real series.
      expect(state.readinessHistory, isNotEmpty);
      expect(state.summaries.length, greaterThan(80));

      await _openTrends(tester);

      // The segmented control and range toggle are present.
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Readiness'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Quarter'), findsOneWidget);

      // Sleep segment (default): trend line renders at the top of the tab.
      expect(find.byType(TrendLine), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Switch the range across Week / Quarter — the controls stay pinned at
      // the top of the ListView, so no scrolling is needed; nothing overflows.
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.byType(TrendLine), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Quarter'));
      await tester.pumpAndSettle();
      expect(find.byType(TrendLine), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Readiness segment renders its own series.
      await tester.tap(find.text('Readiness'));
      await tester.pumpAndSettle();
      expect(find.byType(TrendLine), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Activity segment renders its own series (kcal).
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(find.byType(TrendLine), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Weekly bars + the consistency heatmap sit below the fold — scroll the
      // Trends ListView to reveal each in turn, honestly built from the series.
      final trendsScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byType(WeeklyAverageBars),
        250,
        scrollable: trendsScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyAverageBars), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byType(ConsistencyHeatmap),
        250,
        scrollable: trendsScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConsistencyHeatmap), findsOneWidget);
      expect(find.textContaining('on target'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Trends degrades calmly before any import (no fake data)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootPatient(tester);
    // No import yet.
    await _openTrends(tester);

    // The controls still render, but the body is a calm empty state — no
    // fabricated chart.
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.byType(TrendLine), findsNothing);
    expect(
      find.text('Your sleep trend appears after a few nights'),
      findsOneWidget,
    );

    // Readiness and Activity segments show their own calm empty copy.
    await tester.tap(find.text('Readiness'));
    await tester.pumpAndSettle();
    expect(find.text('Readiness trends after a wearable read'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Sleep trend card opens the Sleep detail (21)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _bootPatient(tester);
    await state.importMockSleep();
    await tester.pumpAndSettle();
    await _openTrends(tester);

    // Tapping the sleep trend line card opens the Sleep detail drill-down.
    await tester.tap(find.byType(TrendLine));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sleep'), findsOneWidget);
  });
}
