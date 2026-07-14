import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/services/sleep_insights.dart';

/// Deterministic fixture: consecutive nights with fixed dates, ascending.
List<DailySummary> nights(List<double> hours) {
  final firstDate = DateTime(2026, 6, 1);
  return List.generate(hours.length, (index) {
    return DailySummary(
      userId: 'patient-demo',
      date: firstDate.add(Duration(days: index)),
      sleepDurationHours: hours[index],
      sleepQualityProxy: 0,
      trendFlag: 'steady',
    );
  });
}

void main() {
  test('seven steady in-band nights score protective with 3 contributors', () {
    final score = computeSleepScore(
      nights([7.5, 7.8, 7.6, 8.0, 7.7, 7.9, 7.8]),
    );

    expect(score.value, greaterThanOrEqualTo(85));
    expect(score.word, 'protective');
    expect(score.tone, StateTone.optimal);
    expect(score.contributors, hasLength(3));
    expect(score.contributors.map((c) => c.name).toList(), [
      'Duration',
      'Consistency',
      'Week trend',
    ]);
  });

  test('mock-import durations: optimal duration and a positive insight', () {
    final summaries = nights([7.4, 6.1, 6.8, 7.9, 5.7, 7.1, 7.6]);
    final score = computeSleepScore(summaries);

    final duration = score.contributors.firstWhere(
      (contributor) => contributor.name == 'Duration',
    );
    expect(duration.word, 'optimal');
    expect(duration.tone, StateTone.optimal);

    final line = insightLine(summaries);
    expect(line, contains('+'));
    expect(line, contains('vs your recent average'));
  });

  test('short varied nights surface contributors to watch', () {
    final score = computeSleepScore(
      nights([4.0, 7.0, 5.0, 8.0, 4.5, 6.0, 5.0]),
    );

    final watchTones = score.contributors.where(
      (contributor) =>
          contributor.tone == StateTone.fair ||
          contributor.tone == StateTone.attention,
    );
    expect(watchTones, isNotEmpty);
    expect(score.caption, endsWith('to watch'));
  });

  test('a single night returns the exact comparison fallback', () {
    expect(
      insightLine(nights([6.5])),
      'One night imported — comparisons appear after a few nights.',
    );
  });

  test('a lower recent week reads negative and flags at -30m or more', () {
    final lowerRecent = nights([
      7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5, // prior week
      6.5, 6.5, 6.5, 6.5, 6.5, 6.5, 6.5, // recent week, -60m
    ]);
    expect(weekDeltaLabel(lowerRecent), startsWith('-'));
    expect(clinicianWeekSummary(lowerRecent).deltaFlagged, isTrue);

    final slightlyLower = nights([
      7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5, // prior week
      7.2, 7.2, 7.2, 7.2, 7.2, 7.2, 7.2, // recent week, -18m
    ]);
    expect(weekDeltaLabel(slightlyLower), '-18m vs prior week');
    expect(clinicianWeekSummary(slightlyLower).deltaFlagged, isFalse);
  });

  test('exactly 7 nights has no prior week and a full nights label', () {
    final summary = clinicianWeekSummary(
      nights([6.2, 6.5, 7.0, 7.2, 5.9, 6.8, 7.6]),
    );
    expect(summary.deltaLabel, 'no prior week yet');
    expect(summary.nightsLabel, '7 of 7 nights');
  });

  test('seeded clinician durations read as steady nights', () {
    final summary = clinicianWeekSummary(
      nights([6.2, 6.5, 7.0, 7.2, 5.9, 6.8, 7.6]),
    );
    expect(summary.variabilityWord, 'steady nights');
    expect(summary.variabilityFlagged, isFalse);
  });

  test('empty summaries return the calm no-data score', () {
    final score = computeSleepScore(const []);
    expect(score.value, 0);
    expect(score.word, 'no data yet');
    expect(score.caption, 'No nights imported yet');
    expect(score.contributors, isEmpty);
  });

  test('consistency caption tracks the spread of the week', () {
    expect(
      consistencyCaption(nights([7.0, 7.2])),
      'rhythm appears after a few nights',
    );
    expect(
      consistencyCaption(nights([7.4, 7.5, 7.6, 7.5, 7.4, 7.6, 7.5])),
      'on rhythm — nights are landing close together',
    );
    expect(
      consistencyCaption(nights([5.5, 7.5, 6.0, 8.0, 5.0, 7.0, 8.5])),
      'rhythm varies a little this week',
    );
    expect(
      consistencyCaption(nights([3.0, 8.5, 4.0, 9.0, 3.5, 8.0, 4.5])),
      'rhythm is wide this week',
    );
  });
}
