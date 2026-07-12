/// Pure, on-device Trends computation for the Trends tab (screens 20/24).
///
/// Like `sleep_insights.dart` and `readiness.dart`, everything here is
/// deterministic over its inputs — it imports ONLY the app models, takes
/// `List<DailySummary>` / `List<ReadinessSummary>` values, and returns plain
/// data. No Flutter, no IO, no clock reads — so callers and tests fully
/// control what flows in.
///
/// The three signals (Sleep, Readiness, Activity) all derive from persisted,
/// patient-owned data: sleep from the daily summaries, readiness from the
/// readiness series, and activity from each readiness summary's prior-day
/// activity contributor (its kcal value). No new data surface is introduced,
/// and nothing here is ever shown to a clinician (sleep-only contract).
///
/// Voice rules for every string produced here: observational, describes the
/// metric never the person, non-diagnostic, no emoji, no exclamation marks.
library;

import '../models/app_models.dart';

/// The three trend signals matching the design's top segmented control.
enum TrendSignal { sleep, readiness, activity }

extension TrendSignalLabel on TrendSignal {
  /// The segment label as shown in the control.
  String get label => switch (this) {
    TrendSignal.sleep => 'Sleep',
    TrendSignal.readiness => 'Readiness',
    TrendSignal.activity => 'Activity',
  };
}

/// The three range windows matching the design's Week / Month / Quarter toggle.
enum TrendRange { week, month, quarter }

extension TrendRangeMeta on TrendRange {
  /// The nominal number of days the range spans.
  int get days => switch (this) {
    TrendRange.week => 7,
    TrendRange.month => 30,
    TrendRange.quarter => 90,
  };

  String get label => switch (this) {
    TrendRange.week => 'Week',
    TrendRange.month => 'Month',
    TrendRange.quarter => 'Quarter',
  };
}

/// One point on the trend line: a calendar [date] and its scalar [value].
class TrendPoint {
  const TrendPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// One weekly-average bar: a short [label] (W1..W4), the [value] it averages,
/// and a 0..1 [fraction] of the axis max for the bar height.
class WeeklyAverage {
  const WeeklyAverage({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final double value;
  final double fraction;
}

/// One heatmap cell state. [empty] leaves a gap (before the first / after the
/// last day in the calendar grid); [flag] marks a short/attention day; levels
/// 1-4 encode how close the day lands to target (more is better).
enum HeatLevel { empty, flag, l1, l2, l3, l4 }

/// The full Trends payload for one (signal, range) selection. Everything the
/// screen renders is precomputed here so the widget layer stays declarative.
class TrendData {
  const TrendData({
    required this.signal,
    required this.range,
    required this.points,
    required this.unit,
    required this.average,
    required this.best,
    required this.avgSleepHours,
    required this.headnote,
    required this.weekly,
    required this.weeklyAxisMax,
    required this.cells,
    required this.onTarget,
    required this.consideredDays,
    required this.consistencyLabel,
  });

  final TrendSignal signal;
  final TrendRange range;

  /// The trend-line points, oldest first.
  final List<TrendPoint> points;

  /// Unit suffix for the primary value (e.g. 'ms' has none here; scores are
  /// unit-less, sleep is 'h', activity is 'kcal').
  final String unit;

  /// Average of the series primary value over the window.
  final double average;

  /// Best (highest) value in the window.
  final double best;

  /// Average nightly sleep hours over the window — shown as a third stat on
  /// the sleep card; null for signals where it does not apply.
  final double? avgSleepHours;

  /// A short observational headnote (e.g. "trending up").
  final String headnote;

  /// Up to four weekly-average bars (most recent weeks in the window).
  final List<WeeklyAverage> weekly;

  /// The axis max the weekly bar fractions were computed against.
  final double weeklyAxisMax;

  /// The consistency calendar cells, laid out Monday-first in 7-wide rows.
  final List<HeatLevel> cells;

  /// How many considered days landed on target.
  final int onTarget;

  /// How many days were considered (non-empty).
  final int consideredDays;

  /// The "24 / 30 on target" style label.
  final String consistencyLabel;

  bool get isEmpty => points.isEmpty;
}

DateTime _dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

double? _mean(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  return values.fold<double>(0, (sum, v) => sum + v) / values.length;
}

/// Reduces the persisted data into the exact [TrendData] a (signal, range)
/// needs. Pure over its inputs; if the window exceeds the available history it
/// simply returns the available window (never fabricates or errors).
TrendData computeTrendData({
  required TrendSignal signal,
  required TrendRange range,
  required List<DailySummary> summaries,
  required List<ReadinessSummary> readiness,
}) {
  // Build the raw (date, value) series for the chosen signal, oldest first.
  final raw = <TrendPoint>[];
  String unit;
  switch (signal) {
    case TrendSignal.sleep:
      unit = '';
      final ordered = summaries.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final s in ordered) {
        raw.add(
          TrendPoint(
            date: _dayOf(s.date),
            value: s.sleepQualityProxy.toDouble(),
          ),
        );
      }
    case TrendSignal.readiness:
      unit = '';
      final ordered = readiness.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final r in ordered) {
        raw.add(
          TrendPoint(date: _dayOf(r.date), value: r.readinessScore.toDouble()),
        );
      }
    case TrendSignal.activity:
      unit = 'kcal';
      final ordered = readiness.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      for (final r in ordered) {
        final kcal = _activityKcal(r);
        if (kcal != null) {
          raw.add(TrendPoint(date: _dayOf(r.date), value: kcal));
        }
      }
  }

  // Take the trailing window (available history is honored — no padding).
  final points = raw.length <= range.days
      ? raw
      : raw.sublist(raw.length - range.days);

  if (points.isEmpty) {
    return TrendData(
      signal: signal,
      range: range,
      points: const [],
      unit: unit,
      average: 0,
      best: 0,
      avgSleepHours: null,
      headnote: '',
      weekly: const [],
      weeklyAxisMax: 1,
      cells: const [],
      onTarget: 0,
      consideredDays: 0,
      consistencyLabel: '0 / 0 on target',
    );
  }

  final values = points.map((p) => p.value).toList();
  final average = _mean(values)!;
  final best = values.reduce((a, b) => a > b ? a : b);

  // Sleep card also shows average nightly hours over the same window.
  double? avgSleepHours;
  if (signal == TrendSignal.sleep) {
    final byDay = {for (final s in summaries) _dayOf(s.date): s};
    final hours = points
        .map((p) => byDay[p.date]?.sleepDurationHours)
        .whereType<double>()
        .toList();
    avgSleepHours = _mean(hours);
  }

  final headnote = _headnote(points);
  final weekly = _weeklyAverages(signal, points, summaries);
  final weeklyAxisMax = _weeklyAxisMax(signal, weekly);
  final consistency = _consistency(signal, points, summaries);

  return TrendData(
    signal: signal,
    range: range,
    points: points,
    unit: unit,
    average: average,
    best: best,
    avgSleepHours: avgSleepHours,
    headnote: headnote,
    weekly: weekly,
    weeklyAxisMax: weeklyAxisMax,
    cells: consistency.cells,
    onTarget: consistency.onTarget,
    consideredDays: consistency.considered,
    consistencyLabel:
        '${consistency.onTarget} / ${consistency.considered} on target',
  );
}

/// The prior-day activity kcal a readiness summary carries, via its activity
/// contributor. Null when the day had no activity reading.
double? _activityKcal(ReadinessSummary summary) {
  for (final c in summary.contributors) {
    if (c.metric == MetricType.activeEnergy) {
      return c.value;
    }
  }
  return null;
}

/// A calm observational headnote from the first-vs-last third of the window.
String _headnote(List<TrendPoint> points) {
  if (points.length < 4) {
    return 'settling in';
  }
  final third = (points.length / 3).floor().clamp(1, points.length);
  final firstAvg = _mean(
    points.take(third).map((p) => p.value).toList(),
  )!;
  final lastAvg = _mean(
    points.reversed.take(third).map((p) => p.value).toList(),
  )!;
  final delta = lastAvg - firstAvg;
  // A small dead-band so tiny drift reads as steady, not up/down.
  final band = firstAvg.abs() * 0.03 + 0.5;
  if (delta > band) {
    return 'trending up';
  }
  if (delta < -band) {
    return 'easing down';
  }
  return 'holding steady';
}

/// Up to four weekly-average bars over the most recent 4 weeks in the window.
/// Sleep averages nightly hours; readiness/activity average their own value.
List<WeeklyAverage> _weeklyAverages(
  TrendSignal signal,
  List<TrendPoint> points,
  List<DailySummary> summaries,
) {
  // Choose the value the weekly bar averages.
  double valueForDay(TrendPoint p) {
    if (signal == TrendSignal.sleep) {
      final byDay = {for (final s in summaries) _dayOf(s.date): s};
      return byDay[p.date]?.sleepDurationHours ?? 0;
    }
    return p.value;
  }

  // Group into trailing 7-day weeks: the last 7 points are the newest week.
  final weeks = <List<TrendPoint>>[];
  for (var end = points.length; end > 0 && weeks.length < 4; end -= 7) {
    final start = (end - 7).clamp(0, end);
    weeks.add(points.sublist(start, end));
  }
  final ordered = weeks.reversed.toList(); // oldest week first

  final result = <WeeklyAverage>[];
  for (var i = 0; i < ordered.length; i++) {
    final avg = _mean(ordered[i].map(valueForDay).toList()) ?? 0;
    result.add(
      WeeklyAverage(
        label: 'W${i + 1}',
        value: double.parse(avg.toStringAsFixed(1)),
        fraction: 0, // filled below once the axis max is known
      ),
    );
  }
  final axisMax = _weeklyAxisMax(signal, result);
  return [
    for (final w in result)
      WeeklyAverage(
        label: w.label,
        value: w.value,
        fraction: axisMax == 0 ? 0 : (w.value / axisMax).clamp(0.0, 1.0),
      ),
  ];
}

/// The axis maximum the weekly bars fill against. Sleep uses a fixed 9.5h axis
/// (matching SleepTrendBars) so a short week reads short; score/activity use a
/// headroom multiple of the tallest bar.
double _weeklyAxisMax(TrendSignal signal, List<WeeklyAverage> weekly) {
  if (signal == TrendSignal.sleep) {
    return 9.5;
  }
  if (signal == TrendSignal.readiness) {
    return 100;
  }
  // Activity (kcal): give ~15% headroom over the tallest week, min 100.
  final peak = weekly.isEmpty
      ? 0.0
      : weekly.map((w) => w.value).reduce((a, b) => a > b ? a : b);
  return (peak * 1.15).clamp(100, double.infinity);
}

class _Consistency {
  const _Consistency({
    required this.cells,
    required this.onTarget,
    required this.considered,
  });
  final List<HeatLevel> cells;
  final int onTarget;
  final int considered;
}

/// Builds the Monday-first consistency calendar for the window, plus the
/// on-target count. A day is "on target" when it reaches level 3 or 4.
_Consistency _consistency(
  TrendSignal signal,
  List<TrendPoint> points,
  List<DailySummary> summaries,
) {
  final byDay = {for (final s in summaries) _dayOf(s.date): s};

  HeatLevel levelFor(TrendPoint p) {
    switch (signal) {
      case TrendSignal.sleep:
        final hours = byDay[p.date]?.sleepDurationHours ?? 0;
        if (hours < 6) {
          return HeatLevel.flag; // short night
        }
        if (hours < 6.75) {
          return HeatLevel.l1;
        }
        if (hours < 7.25) {
          return HeatLevel.l2;
        }
        if (hours < 7.75) {
          return HeatLevel.l3;
        }
        return HeatLevel.l4;
      case TrendSignal.readiness:
      case TrendSignal.activity:
        // Score-like 0-100 for readiness; for activity, closeness to a healthy
        // ~450 kcal band mapped to a 0-100 proximity so both share one ramp.
        final score = signal == TrendSignal.readiness
            ? p.value
            : _activityProximity(p.value);
        if (score < 50) {
          return HeatLevel.flag;
        }
        if (score < 65) {
          return HeatLevel.l1;
        }
        if (score < 78) {
          return HeatLevel.l2;
        }
        if (score < 88) {
          return HeatLevel.l3;
        }
        return HeatLevel.l4;
    }
  }

  // Leading empties so the first day sits under its weekday column (Mon=0).
  final first = points.first.date;
  final leading = (first.weekday - 1) % 7;
  final cells = <HeatLevel>[
    for (var i = 0; i < leading; i++) HeatLevel.empty,
  ];
  var onTarget = 0;
  for (final p in points) {
    final level = levelFor(p);
    cells.add(level);
    if (level == HeatLevel.l3 || level == HeatLevel.l4) {
      onTarget++;
    }
  }
  // Trailing empties to complete the final row of 7.
  while (cells.length % 7 != 0) {
    cells.add(HeatLevel.empty);
  }

  return _Consistency(
    cells: cells,
    onTarget: onTarget,
    considered: points.length,
  );
}

/// Maps activity kcal to a 0-100 proximity to a healthy ~450 kcal band, so a
/// very light or very heavy day reads as less "on target" than a balanced one.
double _activityProximity(double kcal) {
  const target = 450.0;
  final delta = (kcal - target).abs();
  return (100 - delta * 0.09).clamp(0, 100);
}
