import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/services/trends.dart';

/// A deterministic sleep summary series (oldest first) spanning enough days to
/// exercise every range. Includes short nights so the heatmap flags them.
List<DailySummary> _summaries(int days) {
  return List<DailySummary>.generate(days, (i) {
    // Trend up gently with a weekly ripple; some sub-6h nights near the start.
    final hours = (5.4 + i * 0.03 + (i % 7 == 2 ? -1.2 : 0.4)).clamp(4.5, 9.0);
    final quality = (hours / 8 * 100).clamp(45, 96).round();
    return DailySummary(
      userId: 'patient-demo',
      date: DateTime(2026, 4, 1).add(Duration(days: i)),
      sleepDurationHours: double.parse(hours.toStringAsFixed(1)),
      sleepQualityProxy: quality,
      trendFlag: hours < 6 ? 'short night' : 'steady',
    );
  });
}

List<ReadinessSummary> _readiness(int days) {
  return List<ReadinessSummary>.generate(days, (i) {
    final score = (60 + i).clamp(40, 98);
    final kcal = 300 + (i % 7) * 60;
    return ReadinessSummary(
      userId: 'patient-demo',
      date: DateTime(2026, 4, 1).add(Duration(days: i)),
      readinessScore: score,
      state: 'balanced',
      contributors: [
        ReadinessContributor(
          metric: MetricType.activeEnergy,
          name: 'Prior-day activity',
          word: 'good',
          fraction: 0.8,
          value: kcal.toDouble(),
          unit: 'kcal',
        ),
      ],
    );
  });
}

void main() {
  test('range windows take the trailing N days, honoring history', () {
    final summaries = _summaries(90);
    final readiness = _readiness(90);

    final week = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.week,
      summaries: summaries,
      readiness: readiness,
    );
    final month = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.month,
      summaries: summaries,
      readiness: readiness,
    );
    final quarter = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.quarter,
      summaries: summaries,
      readiness: readiness,
    );

    expect(week.points.length, 7);
    expect(month.points.length, 30);
    expect(quarter.points.length, 90);
    // The week is the trailing slice of the month.
    expect(week.points.last.date, month.points.last.date);
    expect(week.points.last.value, month.points.last.value);
  });

  test('a range beyond available history degrades to the available window', () {
    // Only 5 days imported, but the user asks for the Quarter.
    final data = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.quarter,
      summaries: _summaries(5),
      readiness: _readiness(5),
    );
    // No fabrication, no error — just the 5 days we have.
    expect(data.points.length, 5);
    expect(data.isEmpty, isFalse);
  });

  test('no data yields a calm empty payload, never a throw', () {
    final data = computeTrendData(
      signal: TrendSignal.readiness,
      range: TrendRange.month,
      summaries: const [],
      readiness: const [],
    );
    expect(data.isEmpty, isTrue);
    expect(data.points, isEmpty);
    expect(data.cells, isEmpty);
    expect(data.consistencyLabel, '0 / 0 on target');
  });

  test('readiness and activity series derive from the readiness history', () {
    final readiness = _readiness(30);

    final readinessData = computeTrendData(
      signal: TrendSignal.readiness,
      range: TrendRange.month,
      summaries: const [],
      readiness: readiness,
    );
    // Readiness value is the score itself.
    expect(readinessData.points.last.value, readiness.last.readinessScore);

    final activityData = computeTrendData(
      signal: TrendSignal.activity,
      range: TrendRange.month,
      summaries: const [],
      readiness: readiness,
    );
    // Activity value is the prior-day activity contributor's kcal.
    final lastKcal = readiness.last.contributors
        .firstWhere((c) => c.metric == MetricType.activeEnergy)
        .value;
    expect(activityData.points.last.value, lastKcal);
    expect(activityData.unit, 'kcal');
  });

  test('consistency counts on-target days and flags short nights', () {
    final summaries = _summaries(30);
    final data = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.month,
      summaries: summaries,
      readiness: const [],
    );

    // Every considered day is one of the seven day-of-week columns.
    expect(data.cells.length % 7, 0);
    // At least one flagged (short) day exists in this series.
    expect(data.cells.contains(HeatLevel.flag), isTrue);
    // on-target never exceeds the considered day count.
    expect(data.onTarget, lessThanOrEqualTo(data.consideredDays));
    expect(data.consideredDays, 30);
    expect(data.consistencyLabel, '${data.onTarget} / 30 on target');
  });

  test('weekly averages produce up to four bars with honest fractions', () {
    final data = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.month,
      summaries: _summaries(30),
      readiness: const [],
    );
    expect(data.weekly.length, inInclusiveRange(1, 4));
    for (final w in data.weekly) {
      expect(w.fraction, inInclusiveRange(0.0, 1.0));
      expect(w.value, greaterThan(0));
    }
    // Sleep uses the fixed 9.5h axis so a short week reads short.
    expect(data.weeklyAxisMax, 9.5);
  });

  test('the trend is deterministic — same inputs, same output', () {
    final summaries = _summaries(45);
    final a = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.month,
      summaries: summaries,
      readiness: const [],
    );
    final b = computeTrendData(
      signal: TrendSignal.sleep,
      range: TrendRange.month,
      summaries: summaries,
      readiness: const [],
    );
    expect(a.points.map((p) => p.value), b.points.map((p) => p.value));
    expect(a.cells, b.cells);
    expect(a.consistencyLabel, b.consistencyLabel);
  });
}
