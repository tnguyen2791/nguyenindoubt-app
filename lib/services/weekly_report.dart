/// Pure, on-device Weekly-report computation (design `94`).
///
/// Like `sleep_insights.dart`, `readiness.dart`, and `trends.dart`, everything
/// here is deterministic over its inputs — it imports ONLY the app models,
/// takes plain `List<DailySummary>` / `List<ReadinessSummary>` /
/// `List<JournalEntry>` values, and returns plain data. No Flutter, no IO, no
/// clock reads, no dart:math — so callers and tests fully control what flows in.
///
/// Every signal here derives from persisted, patient-owned data: readiness and
/// sleep from the summaries, the "what lined up" correlations from the
/// patient's own journal mood tags vs their sleep the same night. Nothing here
/// is ever shown to a clinician (the sleep-summaries-only privacy contract is
/// unaffected — this is a patient-only surface).
///
/// Voice rules for every string produced here (brand-readme): observational,
/// describes the pattern never the person, non-diagnostic, no shame, no emoji,
/// no exclamation marks. "Patterns, not grades — a week is data, not a verdict."
library;

import '../models/app_models.dart';

/// One night's bar in the 7-night sleep strip.
class WeeklyReportNight {
  const WeeklyReportNight({
    required this.date,
    required this.sleepHours,
    required this.fraction,
  });

  final DateTime date;

  /// Hours asleep that night.
  final double sleepHours;

  /// 0.0-1.0 height of the bar against the fixed hour axis.
  final double fraction;
}

/// One "what lined up" correlation row — an observational note tying a journal
/// mood tag (or a flagged night) to that night's sleep, warm-flagged when the
/// pattern went the harder way.
class WeeklyReportCorrelation {
  const WeeklyReportCorrelation({required this.text, this.warm = false});

  /// The full observational sentence, plain (no leading bullet).
  final String text;

  /// Whether the row uses the warm ember dot (a harder-way pattern).
  final bool warm;
}

/// A stat readout: a big value (with optional small unit fragments) and a
/// lowercase label, matching the design's three-up stat grid.
class WeeklyReportStat {
  const WeeklyReportStat({
    required this.value,
    required this.label,
    this.unitTail,
  });

  /// The primary value string (e.g. "78", "7", "5").
  final String value;

  /// An optional trailing unit fragment rendered smaller (e.g. "h 06m", "/7").
  final String? unitTail;

  /// The lowercase caption beneath (e.g. "avg readiness").
  final String label;
}

/// The full Weekly-report payload the screen renders. Everything is precomputed
/// here so the widget layer stays declarative and testable.
class WeeklyReport {
  const WeeklyReport({
    required this.rangeLabel,
    required this.takeaway,
    required this.takeawaySub,
    required this.stats,
    required this.nights,
    required this.nightsAxisMax,
    required this.correlations,
    required this.oneThingToTry,
    required this.isEmpty,
  });

  /// The "Jul 6 - 12" style date span for the considered week.
  final String rangeLabel;

  /// The short takeaway headline (e.g. "A steadier week").
  final String takeaway;

  /// One calm observational sub-line under the takeaway.
  final String takeawaySub;

  /// The three summary stats (avg readiness, avg sleep, days on target).
  final List<WeeklyReportStat> stats;

  /// Up to seven nights of sleep for the bar strip, oldest first.
  final List<WeeklyReportNight> nights;

  /// The fixed hour axis the night fractions were computed against.
  final double nightsAxisMax;

  /// The "what lined up" observational correlations from the patient's tags.
  final List<WeeklyReportCorrelation> correlations;

  /// The single gentle "one thing to try" suggestion.
  final String oneThingToTry;

  /// True when there is not enough data to render a meaningful week.
  final bool isEmpty;
}

/// The fixed hour axis every night bar renders against — mirrors
/// [SleepTrendBars.axisMaxHours] so the two surfaces read consistently.
const double _nightsAxisMaxHours = 9.5;

DateTime _dayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

double? _mean(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  return values.fold<double>(0, (sum, v) => sum + v) / values.length;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _monthDay(DateTime date) => '${_months[date.month - 1]} ${date.day}';

/// Formats an average sleep duration in hours into value + small tail, e.g.
/// 7.1h -> ("7", "h 06m").
({String value, String tail}) _formatSleep(double hours) {
  final whole = hours.floor();
  final minutes = ((hours - whole) * 60).round();
  final mm = minutes.toString().padLeft(2, '0');
  return (value: '$whole', tail: 'h ${mm}m');
}

/// Computes the Weekly report for the trailing week of the patient's own data.
///
/// [summaries] and [readiness] are the full persisted series (any order);
/// [journal] is the patient's own entries (used only for the observational
/// tag correlations). [sleepGoalHours] is the patient's nightly sleep goal,
/// used for the "days on target" count and the night-bar reference — a night
/// at or above goal counts as on target. Pure over its inputs; when there is
/// too little data it returns an [WeeklyReport.isEmpty] payload the screen
/// renders as a calm empty state.
WeeklyReport computeWeeklyReport({
  required List<DailySummary> summaries,
  required List<ReadinessSummary> readiness,
  List<JournalEntry> journal = const [],
  double sleepGoalHours = 8,
}) {
  // The considered window is the trailing 7 nights of sleep we have.
  final orderedSleep = summaries.toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final week = orderedSleep.length <= 7
      ? orderedSleep
      : orderedSleep.sublist(orderedSleep.length - 7);

  if (week.isEmpty) {
    return const WeeklyReport(
      rangeLabel: '',
      takeaway: 'Your week is still filling in',
      takeawaySub:
          'A few nights of data and this becomes a calm read on your week — '
          'patterns, not grades.',
      stats: [],
      nights: [],
      nightsAxisMax: _nightsAxisMaxHours,
      correlations: [],
      oneThingToTry:
          'Import a few nights of sleep to see your first weekly read.',
      isEmpty: true,
    );
  }

  final firstDay = _dayOf(week.first.date);
  final lastDay = _dayOf(week.last.date);
  final rangeLabel = '${_monthDay(firstDay)} - ${_monthDay(lastDay)}';

  // The readiness values that fall inside the same day window.
  final weekDays = week.map((s) => _dayOf(s.date)).toSet();
  final weekReadiness =
      (readiness.where((r) => weekDays.contains(_dayOf(r.date))).toList()
        ..sort((a, b) => a.date.compareTo(b.date)));

  // --- Stats ---------------------------------------------------------------
  final avgReadiness = _mean(
    weekReadiness.map((r) => r.readinessScore.toDouble()).toList(),
  );
  final avgSleep = _mean(week.map((s) => s.sleepDurationHours).toList())!;
  final onTarget = week
      .where((s) => s.sleepDurationHours >= sleepGoalHours)
      .length;

  final sleepFmt = _formatSleep(avgSleep);
  final stats = <WeeklyReportStat>[
    WeeklyReportStat(
      value: avgReadiness == null ? '--' : avgReadiness.round().toString(),
      label: 'avg readiness',
    ),
    WeeklyReportStat(
      value: sleepFmt.value,
      unitTail: sleepFmt.tail,
      label: 'avg sleep',
    ),
    WeeklyReportStat(
      value: '$onTarget',
      unitTail: '/${week.length}',
      label: 'days on target',
    ),
  ];

  // --- Takeaway ------------------------------------------------------------
  final takeaway = _takeaway(week, weekReadiness);

  // --- Night bars ----------------------------------------------------------
  final nights = <WeeklyReportNight>[
    for (final s in week)
      WeeklyReportNight(
        date: _dayOf(s.date),
        sleepHours: s.sleepDurationHours,
        fraction: (s.sleepDurationHours / _nightsAxisMaxHours).clamp(0.0, 1.0),
      ),
  ];

  // --- Correlations (patient's own journal tags vs that night's sleep) -----
  final correlations = _correlations(week, journal);

  // --- One thing to try ----------------------------------------------------
  final oneThing = _oneThingToTry(week, sleepGoalHours);

  return WeeklyReport(
    rangeLabel: rangeLabel,
    takeaway: takeaway.headline,
    takeawaySub: takeaway.sub,
    stats: stats,
    nights: nights,
    nightsAxisMax: _nightsAxisMaxHours,
    correlations: correlations,
    oneThingToTry: oneThing,
    isEmpty: false,
  );
}

/// The observational takeaway from the shape of the week. Compares the first
/// vs second half of readiness (falling back to sleep) so the headline
/// describes the week's arc without ever grading the person.
({String headline, String sub}) _takeaway(
  List<DailySummary> week,
  List<ReadinessSummary> weekReadiness,
) {
  // Prefer readiness for the arc; fall back to sleep hours when readiness is
  // absent for the window (an honest read on whatever data exists).
  final series = weekReadiness.isNotEmpty
      ? weekReadiness.map((r) => r.readinessScore.toDouble()).toList()
      : week.map((s) => s.sleepDurationHours).toList();
  final usingReadiness = weekReadiness.isNotEmpty;

  if (series.length < 4) {
    return (
      headline: 'A short read this week',
      sub:
          'Only a few nights landed in this window — the picture steadies as '
          'more come in.',
    );
  }

  final half = series.length ~/ 2;
  final firstAvg = _mean(series.take(half).toList())!;
  final lastAvg = _mean(series.skip(series.length - half).toList())!;
  final delta = lastAvg - firstAvg;
  // A small dead-band so tiny drift reads as steady, not up/down.
  final band = firstAvg.abs() * 0.03 + (usingReadiness ? 1.5 : 0.2);

  if (delta > band) {
    return (
      headline: 'A steadier week',
      sub: usingReadiness
          ? 'Readiness climbed through the back half of the week — the later '
                'nights read calmer than the earlier ones.'
          : 'Sleep lengthened through the back half of the week — the later '
                'nights read longer than the earlier ones.',
    );
  }
  if (delta < -band) {
    return (
      headline: 'A lighter week',
      sub: usingReadiness
          ? 'Readiness eased through the week — worth watching, not worrying. '
                'A gentle wind-down can help it settle.'
          : 'Sleep ran a little shorter through the week — worth watching, '
                'not worrying. A gentle wind-down can help it settle.',
    );
  }
  return (
    headline: 'A level week',
    sub: usingReadiness
        ? 'Readiness held fairly steady across the week — a calm, even stretch '
              'with no sharp swings.'
        : 'Sleep held fairly steady across the week — a calm, even stretch '
              'with no sharp swings.',
  );
}

/// Builds the "what lined up" rows from the patient's own journal tags vs the
/// sleep the same night. For each distinct mood tag with at least one night of
/// sleep, compares that tag's nights to the week's average sleep and writes one
/// calm observational sentence. Warm-flags a tag whose nights ran shorter than
/// average. Caps at three rows (the design shows three); returns an empty list
/// when there is nothing honest to say.
List<WeeklyReportCorrelation> _correlations(
  List<DailySummary> week,
  List<JournalEntry> journal,
) {
  final sleepByDay = <DateTime, double>{
    for (final s in week) _dayOf(s.date): s.sleepDurationHours,
  };
  final weekAvg = _mean(sleepByDay.values.toList());
  if (weekAvg == null) {
    return const [];
  }

  // Group the in-window journal entries by their mood tag, keeping the sleep of
  // the night each entry was written. Only tags that map onto a night we have.
  final byTag = <String, List<double>>{};
  for (final entry in journal) {
    final tag = entry.moodTag?.trim();
    if (tag == null || tag.isEmpty) {
      continue;
    }
    final hours = sleepByDay[_dayOf(entry.createdAt)];
    if (hours == null) {
      continue;
    }
    byTag.putIfAbsent(tag, () => []).add(hours);
  }

  final rows = <WeeklyReportCorrelation>[];
  // Deterministic order: by tag name so the output is stable for tests.
  final tags = byTag.keys.toList()..sort();
  for (final tag in tags) {
    if (rows.length >= 3) {
      break;
    }
    final nights = byTag[tag]!;
    final tagAvg = _mean(nights)!;
    final n = nights.length;
    final nightWord = n == 1 ? 'night' : 'nights';
    if (tagAvg >= weekAvg) {
      rows.add(
        WeeklyReportCorrelation(
          text:
              'On "$tag" $nightWord ($n), your sleep ran at or above the '
              "week's average.",
        ),
      );
    } else {
      rows.add(
        WeeklyReportCorrelation(
          text:
              'On "$tag" $nightWord ($n), your sleep ran a little below the '
              "week's average — worth noticing, not worrying.",
          warm: true,
        ),
      );
    }
  }
  return rows;
}

/// The single gentle "one thing to try", chosen from the week's own shape. If a
/// night fell short of goal, it points at an earlier wind-down; otherwise it
/// affirms the steady pattern. Never a command, never shame.
String _oneThingToTry(List<DailySummary> week, double sleepGoalHours) {
  DailySummary? shortest;
  for (final s in week) {
    if (shortest == null ||
        s.sleepDurationHours < shortest.sleepDurationHours) {
      shortest = s;
    }
  }
  if (shortest != null && shortest.sleepDurationHours < sleepGoalHours) {
    return 'Your shortest night this week ran under your goal. A wind-down '
        'that starts 30 minutes earlier would set up the next one gently.';
  }
  return 'Every night this week reached your goal. Keeping the same wind-down '
      'time is the quiet thing that holds it together.';
}
