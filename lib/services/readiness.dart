/// Pure, on-device multi-signal readiness computation.
///
/// This module is the Phase-13 successor to the fake `sleepQualityProxy`. It
/// takes plain [HealthSample] values (HRV, resting HR, respiratory rate,
/// temperature deviation, prior-day activity) plus the sleep [DailySummary]
/// history and returns a genuine, explainable multi-factor [ReadinessSummary].
///
/// Like `sleep_insights.dart`, everything here is deterministic over its inputs
/// — no Flutter, no IO, no clock reads, no dart:math — so callers and tests
/// fully control what flows in. Each contributor's state word is derived from
/// its own value vs a personal baseline/typical range, so the evidence always
/// matches the label.
///
/// Voice rules for every string produced here: observational, describes the
/// metric never the person, non-diagnostic, no emoji, no exclamation marks.
library;

import '../models/app_models.dart';

/// Explicit contributor weights. They sum to 1.0; the overall readiness is the
/// weighted average of each contributor's 0-100 subscore. Sleep carries the
/// most weight (it is the deepest recovery signal), HRV and resting HR next,
/// then the lighter overnight/activity signals.
const double _wSleep = 0.30;
const double _wHrv = 0.20;
const double _wRestingHr = 0.18;
const double _wRespiratory = 0.12;
const double _wTemperature = 0.12;
const double _wActivity = 0.08;

/// A single day's readiness inputs, already reduced to scalar readings.
/// Nulls mean "no reading for this signal today" — the contributor is then
/// treated as neutral so a missing wearable signal never tanks the score.
class ReadinessInputs {
  const ReadinessInputs({
    required this.userId,
    required this.date,
    this.hrvMs,
    this.restingHeartRateBpm,
    this.respiratoryRateBrpm,
    this.temperatureDeviationC,
    this.activeEnergyKcal,
    this.sleepHours,
  });

  final String userId;
  final DateTime date;
  final double? hrvMs;
  final double? restingHeartRateBpm;
  final double? respiratoryRateBrpm;
  final double? temperatureDeviationC;
  final double? activeEnergyKcal;
  final double? sleepHours;
}

/// A personal baseline for the signals. Defaults describe a typical healthy
/// adult range; callers can pass a computed baseline once enough history
/// exists. Kept explicit and injectable so scoring stays deterministic.
class ReadinessBaseline {
  const ReadinessBaseline({
    this.hrvMs = 46,
    this.restingHeartRateBpm = 56,
    this.respiratoryRateBrpm = 14.5,
    this.activeEnergyKcal = 450,
    this.sleepHours = 8,
  });

  final double hrvMs;
  final double restingHeartRateBpm;
  final double respiratoryRateBrpm;
  final double activeEnergyKcal;
  final double sleepHours;
}

/// The observational band for a 0-100 subscore. Shared with sleep insights'
/// vocabulary so the two surfaces read consistently.
({String word, double fraction}) _band(double subscore) {
  final fraction = (subscore / 100).clamp(0.0, 1.0);
  if (subscore >= 85) {
    return (word: 'optimal', fraction: fraction);
  }
  if (subscore >= 70) {
    return (word: 'good', fraction: fraction);
  }
  if (subscore >= 50) {
    return (word: 'fair', fraction: fraction);
  }
  return (word: 'pay attention', fraction: fraction);
}

double _clamp100(double value) => value.clamp(0.0, 100.0);

/// HRV subscore: higher HRV vs baseline is more rested. Scaled so at baseline
/// it lands "good", clearly above lands "optimal", well below flags.
double _hrvSubscore(double hrv, double baseline) {
  final ratio = hrv / baseline;
  // ratio 1.0 -> 78, 1.15+ -> ~100, 0.7 -> ~40.
  return _clamp100(30 + (ratio - 0.6) * 120);
}

/// Resting-HR subscore: lower vs baseline is better. A resting HR at or below
/// baseline scores high; elevations pull it down.
double _restingHrSubscore(double rhr, double baseline) {
  final delta = rhr - baseline; // negative is better
  return _clamp100(90 - delta * 6);
}

/// Respiratory-rate subscore: closeness to the personal baseline. Small drifts
/// are fine; larger deviations (either direction) lower it gently.
double _respiratorySubscore(double brpm, double baseline) {
  final deviation = (brpm - baseline).abs();
  return _clamp100(100 - deviation * 22);
}

/// Temperature-deviation subscore: closeness to baseline (deviation ~0).
/// Sustained rises matter more than dips, matching the design copy.
double _temperatureSubscore(double deviationC) {
  final magnitude = deviationC >= 0 ? deviationC : deviationC.abs() * 0.6;
  return _clamp100(100 - magnitude * 90);
}

/// Prior-day activity subscore: gentle bell around the baseline. Both a very
/// low and a very high load can lower next-day readiness, so distance from
/// baseline (in either direction) reduces the score, low-side more.
double _activitySubscore(double kcal, double baseline) {
  final delta = kcal - baseline;
  final penalty = delta >= 0 ? delta * 0.03 : delta.abs() * 0.06;
  return _clamp100(95 - penalty);
}

/// Sleep-balance subscore: recent sleep vs typical need, using a short window
/// so one short night does not sink it. Mirrors the "two-week view" design copy
/// at a smaller scale for the data we have.
double _sleepSubscore(double recentAvgHours, double needHours) {
  if (recentAvgHours >= needHours) {
    return 100;
  }
  final shortfall = needHours - recentAvgHours;
  return _clamp100(100 - shortfall * 22);
}

double? _mean(List<double> values) {
  if (values.isEmpty) {
    return null;
  }
  return values.fold<double>(0, (sum, v) => sum + v) / values.length;
}

/// Computes the multi-signal readiness for one day.
///
/// [inputs] carries that day's scalar readings; [sleepHistory] supplies the
/// recent nights used for the sleep-balance contributor (so it reflects a
/// window, not just last night). Missing signals fall back to neutral so a
/// gap in wearable data reads honestly rather than as a failing score.
ReadinessSummary computeReadiness({
  required ReadinessInputs inputs,
  List<double> recentSleepHours = const [],
  ReadinessBaseline baseline = const ReadinessBaseline(),
}) {
  // Sleep balance — recent window average vs need. Prefer the passed window;
  // fall back to the day's own sleepHours; neutral when neither exists.
  final windowAvg = _mean(recentSleepHours) ?? inputs.sleepHours;
  final sleepSub = windowAvg == null
      ? 75.0
      : _sleepSubscore(windowAvg, baseline.sleepHours);

  final hrvSub = inputs.hrvMs == null
      ? 75.0
      : _hrvSubscore(inputs.hrvMs!, baseline.hrvMs);
  final restingSub = inputs.restingHeartRateBpm == null
      ? 75.0
      : _restingHrSubscore(
          inputs.restingHeartRateBpm!,
          baseline.restingHeartRateBpm,
        );
  final respiratorySub = inputs.respiratoryRateBrpm == null
      ? 75.0
      : _respiratorySubscore(
          inputs.respiratoryRateBrpm!,
          baseline.respiratoryRateBrpm,
        );
  final temperatureSub = inputs.temperatureDeviationC == null
      ? 75.0
      : _temperatureSubscore(inputs.temperatureDeviationC!);
  final activitySub = inputs.activeEnergyKcal == null
      ? 75.0
      : _activitySubscore(inputs.activeEnergyKcal!, baseline.activeEnergyKcal);

  final restingBand = _band(restingSub);
  final hrvBand = _band(hrvSub);
  final temperatureBand = _band(temperatureSub);
  final respiratoryBand = _band(respiratorySub);
  final sleepBand = _band(sleepSub);
  final activityBand = _band(activitySub);

  // Contributor order matches the readiness-detail design (28/05).
  final contributors = <ReadinessContributor>[
    ReadinessContributor(
      metric: MetricType.restingHeartRate,
      name: 'Resting HR',
      word: restingBand.word,
      fraction: restingBand.fraction,
      value: inputs.restingHeartRateBpm,
      unit: inputs.restingHeartRateBpm == null ? null : 'bpm',
    ),
    ReadinessContributor(
      metric: MetricType.hrv,
      name: 'HRV balance',
      word: hrvBand.word,
      fraction: hrvBand.fraction,
      value: inputs.hrvMs,
      unit: inputs.hrvMs == null ? null : 'ms',
    ),
    ReadinessContributor(
      metric: MetricType.temperature,
      name: 'Body temp',
      word: temperatureBand.word,
      fraction: temperatureBand.fraction,
      value: inputs.temperatureDeviationC,
      unit: inputs.temperatureDeviationC == null ? null : '°C',
    ),
    ReadinessContributor(
      metric: MetricType.respiratoryRate,
      name: 'Respiratory rate',
      word: respiratoryBand.word,
      fraction: respiratoryBand.fraction,
      value: inputs.respiratoryRateBrpm,
      unit: inputs.respiratoryRateBrpm == null ? null : 'brpm',
    ),
    ReadinessContributor(
      metric: MetricType.sleep,
      name: 'Sleep balance',
      word: sleepBand.word,
      fraction: sleepBand.fraction,
      value: windowAvg,
      unit: windowAvg == null ? null : 'h',
    ),
    ReadinessContributor(
      metric: MetricType.activeEnergy,
      name: 'Prior-day activity',
      word: activityBand.word,
      fraction: activityBand.fraction,
      value: inputs.activeEnergyKcal,
      unit: inputs.activeEnergyKcal == null ? null : 'kcal',
    ),
  ];

  final value =
      (_wSleep * sleepSub +
              _wHrv * hrvSub +
              _wRestingHr * restingSub +
              _wRespiratory * respiratorySub +
              _wTemperature * temperatureSub +
              _wActivity * activitySub)
          .round()
          .clamp(0, 100);

  final state = readinessStateWord(value);

  return ReadinessSummary(
    userId: inputs.userId,
    date: inputs.date,
    readinessScore: value,
    state: state,
    contributors: contributors,
  );
}

/// The overall observational state word for a 0-100 readiness value. Mirrors
/// the sleep-score vocabulary (protective / balanced / fair / pay attention).
String readinessStateWord(int value) {
  if (value >= 85) {
    return 'protective';
  }
  if (value >= 70) {
    return 'balanced';
  }
  if (value >= 50) {
    return 'fair';
  }
  return 'pay attention';
}

/// Reduces a day's readiness samples (from `fetchSamples`) plus that day's
/// sleep summary into [ReadinessInputs]. Averages same-metric readings for the
/// day so multiple points collapse to one scalar. Pure over its inputs.
ReadinessInputs readinessInputsFromSamples({
  required String userId,
  required DateTime date,
  required List<HealthSample> samples,
  double? sleepHours,
}) {
  double? avgFor(MetricType metric) => _mean(
    samples.where((s) => s.metricType == metric).map((s) => s.value).toList(),
  );

  return ReadinessInputs(
    userId: userId,
    date: date,
    hrvMs: avgFor(MetricType.hrv),
    restingHeartRateBpm: avgFor(MetricType.restingHeartRate),
    respiratoryRateBrpm: avgFor(MetricType.respiratoryRate),
    temperatureDeviationC: avgFor(MetricType.temperature),
    activeEnergyKcal: avgFor(MetricType.activeEnergy),
    sleepHours: sleepHours,
  );
}
