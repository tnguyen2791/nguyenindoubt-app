import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/weekly_report_screen.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/services/weekly_report.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

/// A deterministic run of nights for the pure-computation tests.
List<DailySummary> _nights(List<double> hours) {
  final base = DateTime(2026, 7, 6);
  return [
    for (var i = 0; i < hours.length; i++)
      DailySummary(
        userId: 'p1',
        date: base.add(Duration(days: i)),
        sleepDurationHours: hours[i],
        sleepQualityProxy: 70,
        trendFlag: 'steady',
      ),
  ];
}

List<ReadinessSummary> _readiness(List<int> scores) {
  final base = DateTime(2026, 7, 6);
  return [
    for (var i = 0; i < scores.length; i++)
      ReadinessSummary(
        userId: 'p1',
        date: base.add(Duration(days: i)),
        readinessScore: scores[i],
        state: 'balanced',
        contributors: const [],
      ),
  ];
}

void main() {
  group('computeWeeklyReport (pure)', () {
    test('empty history yields a calm empty payload', () {
      final report = computeWeeklyReport(
        summaries: const [],
        readiness: const [],
      );
      expect(report.isEmpty, isTrue);
      expect(report.stats, isEmpty);
      expect(report.nights, isEmpty);
      // Even empty, the voice stays calm and non-diagnostic.
      expect(report.oneThingToTry, isNotEmpty);
    });

    test('computes the three stats from the patient own data', () {
      final report = computeWeeklyReport(
        summaries: _nights([6.8, 6.4, 7.1, 7.3, 7.0, 7.6, 7.4]),
        readiness: _readiness([70, 72, 74, 78, 76, 84, 80]),
        sleepGoalHours: 7,
      );
      expect(report.isEmpty, isFalse);
      // avg readiness = (70+72+74+78+76+84+80)/7 = 76.28 -> 76.
      expect(report.stats[0].value, '76');
      expect(report.stats[0].label, 'avg readiness');
      // avg sleep ~7.08h -> "7" + "h 05m"; 5 of 7 nights >= 7h goal
      // (7.1, 7.3, 7.0, 7.6, 7.4 reach it; 6.8 and 6.4 fall short).
      expect(report.stats[1].value, '7');
      expect(report.stats[1].unitTail, 'h 05m');
      expect(report.stats[2].value, '5');
      expect(report.stats[2].unitTail, '/7');
    });

    test('reads a rising week as steadier from the readiness arc', () {
      final report = computeWeeklyReport(
        summaries: _nights([6.5, 6.6, 6.8, 7.0, 7.2, 7.5, 7.7]),
        readiness: _readiness([64, 66, 68, 74, 78, 84, 88]),
      );
      expect(report.takeaway, 'A steadier week');
      expect(report.takeawaySub, contains('climbed'));
    });

    test('night bars carry honest fractions of the fixed axis', () {
      final report = computeWeeklyReport(
        summaries: _nights([9.5, 4.75, 7.0]),
        readiness: const [],
      );
      expect(report.nights.length, 3);
      expect(report.nights.first.fraction, closeTo(1.0, 1e-9));
      expect(report.nights[1].fraction, closeTo(0.5, 1e-9));
    });

    test('correlates journal mood tags with that night sleep', () {
      final week = _nights([7.5, 7.6, 5.5, 7.4, 7.2, 7.8, 7.6]);
      // A calm tag on a good night, an "uneasy" tag on the short night.
      final journal = [
        JournalEntry(
          id: 'j1',
          userId: 'p1',
          title: 'calm',
          body: 'good',
          moodTag: 'calm',
          createdAt: week[0].date,
        ),
        JournalEntry(
          id: 'j2',
          userId: 'p1',
          title: 'uneasy',
          body: 'short',
          moodTag: 'uneasy',
          createdAt: week[2].date,
        ),
      ];
      final report = computeWeeklyReport(
        summaries: week,
        readiness: const [],
        journal: journal,
      );
      expect(report.correlations.length, 2);
      // Deterministic order by tag: "calm" first, "uneasy" second.
      expect(report.correlations[0].text, contains('"calm"'));
      expect(report.correlations[0].warm, isFalse);
      // The short "uneasy" night ran below average -> warm-flagged.
      expect(report.correlations[1].text, contains('"uneasy"'));
      expect(report.correlations[1].warm, isTrue);
      // Voice stays observational, never diagnostic.
      for (final c in report.correlations) {
        expect(c.text.contains('!'), isFalse);
      }
    });

    test('one thing to try points earlier when a night fell short of goal', () {
      final short = computeWeeklyReport(
        summaries: _nights([7.5, 7.6, 5.9, 7.4, 7.2, 7.8, 7.6]),
        readiness: const [],
        sleepGoalHours: 7,
      );
      expect(short.oneThingToTry, contains('30 minutes earlier'));

      final onTrack = computeWeeklyReport(
        summaries: _nights([7.5, 7.6, 7.2, 7.4, 7.2, 7.8, 7.6]),
        readiness: const [],
        sleepGoalHours: 7,
      );
      expect(onTrack.oneThingToTry, contains('same wind-down'));
    });
  });

  group('WeeklyReportScreen (widget)', () {
    testWidgets('renders takeaway, stats, bars, and the patterns footer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = NguyenInDoubtState(
        repository: InMemoryAppRepository(),
        healthDataProvider: MockHealthDataProvider(),
      );
      await state.continueAsPatient();
      await state.importMockSleep();

      await tester.pumpWidget(
        MaterialApp(home: WeeklyReportScreen(state: state)),
      );
      await tester.pumpAndSettle();

      // The design-94 chrome is present.
      expect(find.text('Your week'), findsOneWidget);
      expect(find.text('avg readiness'.toUpperCase()), findsOneWidget);
      expect(find.text('avg sleep'.toUpperCase()), findsOneWidget);
      expect(find.text('days on target'.toUpperCase()), findsOneWidget);
      expect(find.text('ONE THING TO TRY'), findsOneWidget);
      // The verbatim non-diagnostic close.
      expect(
        find.text('Patterns, not grades — a week is data, not a verdict.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a calm empty state before any import', (tester) async {
      final state = NguyenInDoubtState(
        repository: InMemoryAppRepository(),
        healthDataProvider: MockHealthDataProvider(),
      );
      await state.continueAsPatient();

      await tester.pumpWidget(
        MaterialApp(home: WeeklyReportScreen(state: state)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your week'), findsOneWidget);
      expect(find.text('Your week is still filling in'), findsOneWidget);
    });
  });
}
