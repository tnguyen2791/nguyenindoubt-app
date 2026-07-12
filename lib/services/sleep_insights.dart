/// Pure, on-device sleep-insight computation.
///
/// This module is the privacy seam for Phase 11's derived insights: it
/// imports ONLY the app models, takes `List<DailySummary>` values, and
/// returns plain data/strings. No Flutter, no IO, no clock reads — every
/// function is deterministic over its inputs, so callers (and tests) fully
/// control what flows in. Only sleep summaries can ever reach a score,
/// insight line, or clinician summary by construction.
///
/// Voice rules for every string produced here: observational, describes the
/// metric never the person, no emoji, no exclamation marks.
library;

import '../models/app_models.dart';

/// The four metric states, ordered best to most-worth-watching.
enum StateTone { optimal, good, fair, attention }

/// One explainable factor behind the overall sleep score.
class ScoreContributor {
  const ScoreContributor({
    required this.name,
    required this.word,
    required this.tone,
    required this.fraction,
  });

  final String name;

  /// The contributor's own state word — derived from its own subscore, so
  /// the evidence always matches the label.
  final String word;

  final StateTone tone;

  /// Subscore expressed 0.0-1.0 for track fills.
  final double fraction;
}

/// The multi-factor, non-diagnostic sleep score.
class SleepScore {
  const SleepScore({
    required this.value,
    required this.word,
    required this.tone,
    required this.caption,
    required this.contributors,
  });

  final int value;
  final String word;
  final StateTone tone;
  final String caption;
  final List<ScoreContributor> contributors;
}

/// Directional week summary for the clinician surface — sleep summaries
/// only, deltas and descriptors instead of raw counts.
class ClinicianWeekSummary {
  const ClinicianWeekSummary({
    required this.avgLabel,
    required this.deltaLabel,
    required this.deltaFlagged,
    required this.variabilityValue,
    required this.variabilityWord,
    required this.variabilityFlagged,
    required this.nightsLabel,
  });

  final String avgLabel;
  final String deltaLabel;
  final bool deltaFlagged;
  final String variabilityValue;
  final String variabilityWord;
  final bool variabilityFlagged;
  final String nightsLabel;
}

/// Defensive copy sorted by date ascending — the last element is the most
/// recent night everywhere in this module.
List<DailySummary> _sortedByDate(List<DailySummary> summaries) {
  final sorted = List<DailySummary>.of(summaries)
    ..sort((a, b) => a.date.compareTo(b.date));
  return sorted;
}

double _mean(List<double> values) =>
    values.fold<double>(0, (sum, value) => sum + value) / values.length;

/// Population standard deviation of [values].
double _populationSd(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final mean = _mean(values);
  final variance =
      values.fold<double>(
        0,
        (sum, value) => sum + (value - mean) * (value - mean),
      ) /
      values.length;
  double sd = 0;
  double guess = variance;
  if (variance > 0) {
    // Newton's method square root — keeps the module free of dart:math.
    guess = variance > 1 ? variance : 1;
    for (var i = 0; i < 24; i++) {
      guess = (guess + variance / guess) / 2;
    }
    sd = guess;
  }
  return sd;
}

/// The most recent up-to-[count] durations, date ascending.
List<double> _recentDurations(List<DailySummary> sorted, int count) {
  final window = sorted.length <= count
      ? sorted
      : sorted.sublist(sorted.length - count);
  return window.map((summary) => summary.sleepDurationHours).toList();
}

String _capitalize(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);

({String word, StateTone tone}) _bandFor(
  double subscore, {
  String optimalWord = 'optimal',
}) {
  if (subscore >= 85) {
    return (word: optimalWord, tone: StateTone.optimal);
  }
  if (subscore >= 70) {
    return (word: 'good', tone: StateTone.good);
  }
  if (subscore >= 50) {
    return (word: 'fair', tone: StateTone.fair);
  }
  return (word: 'pay attention', tone: StateTone.attention);
}

/// Multi-factor sleep score over the most recent up-to-7 nights.
///
/// Three contributors — duration vs the 7-9h target band, consistency of
/// the window, and the week trend — each carrying its own state word so the
/// evidence is explainable. Non-diagnostic by design.
SleepScore computeSleepScore(List<DailySummary> summaries) {
  if (summaries.isEmpty) {
    return const SleepScore(
      value: 0,
      word: 'no data yet',
      tone: StateTone.fair,
      caption: 'No nights imported yet',
      contributors: [],
    );
  }

  final sorted = _sortedByDate(summaries);
  final window = _recentDurations(sorted, 7);

  // Duration — last night vs the 7-9h target band.
  final lastNight = window.last;
  double durationScore;
  if (lastNight >= 7 && lastNight <= 9) {
    durationScore = 100;
  } else {
    final distance = lastNight < 7 ? 7 - lastNight : lastNight - 9;
    durationScore = (100 - distance * 40).clamp(0.0, 100.0);
  }
  final durationBand = _bandFor(durationScore);

  // Consistency — population sd of the window's durations.
  final sd = _populationSd(window);
  final consistencyScore = (((2.0 - sd) / 1.5) * 100).clamp(0.0, 100.0);
  final consistencyBand = _bandFor(consistencyScore, optimalWord: 'on rhythm');

  // Week trend — later half of the window vs the earlier half.
  double trendScore;
  String trendWord;
  StateTone trendTone;
  if (window.length < 4) {
    // Honest neutral: too few nights to call a trend.
    trendScore = 75;
    trendWord = 'steady';
    trendTone = StateTone.good;
  } else {
    final split = window.length ~/ 2;
    final earlier = window.sublist(0, split);
    final later = window.sublist(split);
    final deltaMinutes = ((_mean(later) - _mean(earlier)) * 60).round();
    trendScore = deltaMinutes >= 0
        ? 100
        : (100 + deltaMinutes).clamp(0, 100).toDouble();
    if (deltaMinutes >= 15) {
      trendWord = 'trending up';
      trendTone = StateTone.optimal;
    } else if (deltaMinutes >= -15) {
      trendWord = 'steady';
      trendTone = StateTone.good;
    } else if (deltaMinutes >= -45) {
      trendWord = 'fair';
      trendTone = StateTone.fair;
    } else {
      trendWord = 'pay attention';
      trendTone = StateTone.attention;
    }
  }

  final contributors = [
    ScoreContributor(
      name: 'Duration',
      word: durationBand.word,
      tone: durationBand.tone,
      fraction: durationScore / 100,
    ),
    ScoreContributor(
      name: 'Consistency',
      word: consistencyBand.word,
      tone: consistencyBand.tone,
      fraction: consistencyScore / 100,
    ),
    ScoreContributor(
      name: 'Week trend',
      word: trendWord,
      tone: trendTone,
      fraction: trendScore / 100,
    ),
  ];

  final value =
      (0.5 * durationScore + 0.3 * consistencyScore + 0.2 * trendScore)
          .round()
          .clamp(0, 100);

  String overallWord;
  StateTone overallTone;
  if (value >= 85) {
    overallWord = 'protective';
    overallTone = StateTone.optimal;
  } else if (value >= 70) {
    overallWord = 'balanced';
    overallTone = StateTone.good;
  } else if (value >= 50) {
    overallWord = 'fair';
    overallTone = StateTone.fair;
  } else {
    overallWord = 'pay attention';
    overallTone = StateTone.attention;
  }

  final watchCount = contributors
      .where(
        (contributor) =>
            contributor.tone == StateTone.fair ||
            contributor.tone == StateTone.attention,
      )
      .length;
  final watchPhrase = switch (watchCount) {
    0 => 'contributors steady',
    1 => 'one contributor to watch',
    _ => '$watchCount contributors to watch',
  };

  return SleepScore(
    value: value,
    word: overallWord,
    tone: overallTone,
    caption: '${_capitalize(overallWord)} · $watchPhrase',
    contributors: contributors,
  );
}

/// One gentle observational line: last night vs the recent average.
String insightLine(List<DailySummary> summaries) {
  if (summaries.length < 2) {
    return 'One night imported — comparisons appear after a few nights.';
  }

  final sorted = _sortedByDate(summaries);
  final lastNight = sorted.last.sleepDurationHours;
  final before = sorted.sublist(0, sorted.length - 1);
  final baselineWindow = _recentDurations(before, 7);
  final baseline = _mean(baselineWindow);
  final deltaMinutes = ((lastNight - baseline) * 60).round();

  if (deltaMinutes.abs() < 15) {
    return 'Last night was close to your recent average — on rhythm.';
  }
  if (deltaMinutes > 0) {
    return 'Last night ran +${deltaMinutes}m vs your recent average.';
  }
  return 'Last night ran -${deltaMinutes.abs()}m vs your recent average.';
}

/// Consistency micro-insight caption for the patient trend card.
String consistencyCaption(List<DailySummary> summaries) {
  if (summaries.length < 3) {
    return 'rhythm appears after a few nights';
  }
  final sorted = _sortedByDate(summaries);
  final sd = _populationSd(_recentDurations(sorted, 7));
  if (sd <= 0.75) {
    return 'on rhythm — nights are landing close together';
  }
  if (sd <= 1.5) {
    return 'rhythm varies a little this week';
  }
  return 'rhythm is wide this week';
}

/// Directional label: the recent up-to-7 nights vs the up-to-7 before them.
String weekDeltaLabel(List<DailySummary> summaries) {
  final delta = _weekDeltaMinutes(summaries);
  if (delta == null) {
    return 'no prior week yet';
  }
  if (delta.abs() < 10) {
    return 'about even with prior week';
  }
  if (delta > 0) {
    return '+${delta}m vs prior week';
  }
  return '-${delta.abs()}m vs prior week';
}

/// Recent-vs-prior-week delta in minutes; null when no prior nights exist.
int? _weekDeltaMinutes(List<DailySummary> summaries) {
  final sorted = _sortedByDate(summaries);
  if (sorted.length <= 7) {
    return null;
  }
  final recent = sorted.sublist(sorted.length - 7);
  final priorAll = sorted.sublist(0, sorted.length - 7);
  final prior = priorAll.length <= 7
      ? priorAll
      : priorAll.sublist(priorAll.length - 7);
  final recentMean = _mean(
    recent.map((summary) => summary.sleepDurationHours).toList(),
  );
  final priorMean = _mean(
    prior.map((summary) => summary.sleepDurationHours).toList(),
  );
  return ((recentMean - priorMean) * 60).round();
}

/// Directional, non-diagnostic week summary for the clinician surface.
ClinicianWeekSummary clinicianWeekSummary(List<DailySummary> summaries) {
  if (summaries.isEmpty) {
    return const ClinicianWeekSummary(
      avgLabel: '0.0h',
      deltaLabel: 'no prior week yet',
      deltaFlagged: false,
      variabilityValue: '±0.0h',
      variabilityWord: 'steady nights',
      variabilityFlagged: false,
      nightsLabel: '0 of 7 nights',
    );
  }

  final sorted = _sortedByDate(summaries);
  final recent = sorted.length <= 7
      ? sorted
      : sorted.sublist(sorted.length - 7);
  final recentDurations = recent
      .map((summary) => summary.sleepDurationHours)
      .toList();

  final deltaMinutes = _weekDeltaMinutes(summaries);
  final sd = _populationSd(recentDurations);

  String variabilityWord;
  var variabilityFlagged = false;
  if (sd <= 0.75) {
    variabilityWord = 'steady nights';
  } else if (sd <= 1.5) {
    variabilityWord = 'some variability';
  } else {
    variabilityWord = 'wide variability';
    variabilityFlagged = true;
  }

  return ClinicianWeekSummary(
    avgLabel: '${_mean(recentDurations).toStringAsFixed(1)}h',
    deltaLabel: weekDeltaLabel(summaries),
    deltaFlagged: deltaMinutes != null && deltaMinutes <= -30,
    variabilityValue: '±${sd.toStringAsFixed(1)}h',
    variabilityWord: variabilityWord,
    variabilityFlagged: variabilityFlagged,
    nightsLabel: '${recent.length} of 7 nights',
  );
}
