import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/screens/common_widgets.dart';
import 'package:nguyenindoubt_app/screens/data_displays.dart';
import 'package:nguyenindoubt_app/services/sleep_insights.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';

Widget harness(Widget child) {
  return MaterialApp(
    theme: buildNidTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('ScoreRing shows the score and state word after easing in', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const ScoreRing(
          score: 82,
          word: 'balanced',
          color: NidStateColors.good,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('82'), findsOneWidget);
    expect(find.text('balanced'), findsOneWidget);
  });

  testWidgets('ContributorBar shows its own state word', (tester) async {
    await tester.pumpWidget(
      harness(
        const ContributorBar(
          name: 'Consistency',
          word: 'fair',
          tone: StateTone.fair,
          fraction: 0.6,
        ),
      ),
    );

    expect(find.text('Consistency'), findsOneWidget);
    expect(find.text('fair'), findsOneWidget);
  });

  testWidgets('InfoTip opens an educational card and Got it dismisses it', (
    tester,
  ) async {
    const body =
        'How close your nights land to each other. Small swings are normal '
        'and settle on their own.';
    await tester.pumpWidget(
      harness(const InfoTip(term: 'Consistency', body: body)),
    );

    await tester.tap(find.byType(InfoTip));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Consistency'), findsOneWidget);
    expect(find.text(body), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('StatDeltaRow renders name, value, and delta', (tester) async {
    await tester.pumpWidget(
      harness(
        const StatDeltaRow(
          name: 'Avg duration',
          sub: 'recent nights',
          value: '6.7h',
          delta: '+12m vs prior week',
        ),
      ),
    );

    expect(find.text('Avg duration'), findsOneWidget);
    expect(find.text('6.7h'), findsOneWidget);
    expect(find.text('+12m vs prior week'), findsOneWidget);
  });

  testWidgets('SleepTrendBars renders honest heights on the fixed axis', (
    tester,
  ) async {
    final summaries = [
      DailySummary(
        userId: 'patient-demo',
        date: DateTime(2026, 6, 1),
        sleepDurationHours: 2.0,
        sleepQualityProxy: 0,
        trendFlag: 'short night',
      ),
      DailySummary(
        userId: 'patient-demo',
        date: DateTime(2026, 6, 2),
        sleepDurationHours: 8.0,
        sleepQualityProxy: 0,
        trendFlag: 'protective',
      ),
    ];

    await tester.pumpWidget(harness(SleepTrendBars(summaries: summaries)));

    final heightFactors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.heightFactor)
        .whereType<double>()
        .toList();
    expect(
      heightFactors,
      contains(closeTo(2.0 / SleepTrendBars.axisMaxHours, 0.001)),
      reason: 'the 2h bar must render its honest tiny fraction — no floor',
    );
    expect(
      heightFactors,
      contains(closeTo(8.0 / SleepTrendBars.axisMaxHours, 0.001)),
    );

    expect(find.text('5h short'), findsOneWidget);
    expect(find.text('8h+ optimal'), findsOneWidget);
  });
}
