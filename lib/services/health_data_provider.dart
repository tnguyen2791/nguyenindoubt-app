import 'health_data_provider_platform_stub.dart'
    if (dart.library.io) 'health_data_provider_platform_io.dart';
import '../models/app_models.dart';

enum HealthPermissionStatus {
  unavailable,
  notRequested,
  partial,
  denied,
  revoked,
  ready,
}

/// The full wearable signal set the app reads once permissions are granted.
///
/// Sleep is intentionally excluded here — it flows through the dedicated
/// [HealthDataProvider.fetchSleepSamples] path (its own dedupe + summary), and
/// the clinician surface stays sleep-summaries-only. These are the signals that
/// feed the patient-facing multi-signal readiness (Phase 13).
const List<MetricType> kReadinessMetricTypes = [
  MetricType.hrv,
  MetricType.restingHeartRate,
  MetricType.respiratoryRate,
  MetricType.temperature,
  MetricType.bloodOxygen,
  MetricType.activeEnergy,
  MetricType.steps,
];

abstract class HealthDataProvider {
  HealthPermissionStatus get permissionStatus;

  Future<HealthPermissionStatus> checkPermissionStatus();

  Future<bool> requestPermissions();

  Future<List<HealthSample>> fetchSleepSamples(HealthRange range);

  /// Generic multi-metric read. Returns samples for the requested [metrics]
  /// within [range]. Unsupported metrics on the current platform are skipped
  /// gracefully (never throw). Implementations may ignore [MetricType.sleep]
  /// here — sleep has its own [fetchSleepSamples] path.
  Future<List<HealthSample>> fetchSamples({
    required List<MetricType> metrics,
    required HealthRange range,
  });

  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range);
}

HealthDataProvider createDefaultHealthDataProvider({required String userId}) {
  return createPlatformHealthDataProvider(userId: userId);
}

class MockHealthDataProvider implements HealthDataProvider {
  MockHealthDataProvider({
    this.userId = 'patient-demo',
    HealthPermissionStatus initialStatus = HealthPermissionStatus.notRequested,
  }) : _permissionStatus = initialStatus;

  final String userId;
  HealthPermissionStatus _permissionStatus;

  @override
  HealthPermissionStatus get permissionStatus => _permissionStatus;

  @override
  Future<HealthPermissionStatus> checkPermissionStatus() async {
    return _permissionStatus;
  }

  @override
  Future<bool> requestPermissions() async {
    if (_permissionStatus == HealthPermissionStatus.unavailable) {
      return false;
    }
    _permissionStatus = HealthPermissionStatus.ready;
    return _permissionStatus == HealthPermissionStatus.ready;
  }

  @override
  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range) async {
    if (_permissionStatus != HealthPermissionStatus.ready) {
      return const [MetricType.sleep];
    }
    // Ready: the mock has deterministic data for sleep plus the full readiness
    // signal set, so the demo/tests exercise the whole pipeline.
    return const [MetricType.sleep, ...kReadinessMetricTypes];
  }

  @override
  Future<List<HealthSample>> fetchSleepSamples(HealthRange range) async {
    if (_permissionStatus != HealthPermissionStatus.ready) {
      return const [];
    }

    final now = DateTime.now();
    return List<HealthSample>.generate(_mockDays, (index) {
      // index 0 is the oldest day, _mockDays-1 is last night.
      final ageDays = _mockDays - index - 1;
      final hours = _mockSleepHours(index);
      final sleepEnd = DateTime(
        now.year,
        now.month,
        now.day,
        6 + index % 2,
        45,
      ).subtract(Duration(days: ageDays));
      final sleepStart = sleepEnd.subtract(
        Duration(minutes: (hours * 60).round()),
      );

      return HealthSample(
        userId: userId,
        source: 'Apple Health mock',
        metricType: MetricType.sleep,
        start: sleepStart,
        end: sleepEnd,
        value: hours,
        unit: 'hours',
        createdAt: now,
      );
    }).where((sample) {
      return !sample.end.isBefore(range.start) &&
          !sample.start.isAfter(range.end);
    }).toList();
  }

  @override
  Future<List<HealthSample>> fetchSamples({
    required List<MetricType> metrics,
    required HealthRange range,
  }) async {
    if (_permissionStatus != HealthPermissionStatus.ready) {
      return const [];
    }

    final now = DateTime.now();
    final samples = <HealthSample>[];
    final wanted = metrics.toSet();
    for (var index = 0; index < _mockDays; index++) {
      // Each day's window ends at ~07:00 on that morning; readiness signals are
      // overnight/morning readings. Deterministic per day-offset — no clock,
      // no randomness, so tests fully control the values.
      final dayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        7,
      ).subtract(Duration(days: _mockDays - index - 1));
      final dayStart = dayEnd.subtract(const Duration(hours: 8));

      for (final metric in _mockReadinessMetrics) {
        if (!wanted.contains(metric)) {
          continue;
        }
        final reading = _mockReading(metric, index);
        samples.add(
          HealthSample(
            userId: userId,
            source: 'Apple Health mock',
            metricType: metric,
            start: dayStart,
            end: dayEnd,
            value: reading.value,
            unit: reading.unit,
            createdAt: now,
          ),
        );
      }
    }

    return samples.where((sample) {
      return !sample.end.isBefore(range.start) &&
          !sample.start.isAfter(range.end);
    }).toList();
  }

  /// The mock emits a rolling quarter of deterministic history so the Trends
  /// tab's Week / Month / Quarter ranges all have a real series. Everything is
  /// a closed-form function of the day offset — no clock, no randomness — so
  /// tests fully control the values and the whole window is reproducible.
  static const int _mockDays = 90;

  static const _mockReadinessMetrics = <MetricType>[
    MetricType.hrv,
    MetricType.restingHeartRate,
    MetricType.respiratoryRate,
    MetricType.temperature,
    MetricType.bloodOxygen,
    MetricType.activeEnergy,
    MetricType.steps,
  ];

  /// A small deterministic triangle wave in [0, 1] over the day [index]. Two
  /// gently out-of-phase periods give the series believable, non-flat drift
  /// without any randomness (so it round-trips identically in every test run).
  static double _wave(int index, int period, int phase) {
    final t = (index + phase) % period;
    final half = period / 2;
    final up = t <= half ? t / half : (period - t) / half;
    return up.clamp(0.0, 1.0);
  }

  /// Deterministic sleep hours for day [index]. Trends up gently across the
  /// quarter (older nights shorter) with a weekly ripple, so weekly averages
  /// climb and a handful of short nights land honestly on the heatmap.
  static double _mockSleepHours(int index) {
    final trend = 6.2 + (index / (_mockDays - 1)) * 1.3; // 6.2 -> 7.5
    final ripple = (_wave(index, 7, 2) - 0.5) * 1.6; // ±0.8h weekly ripple
    final hours = trend + ripple;
    return double.parse(hours.clamp(4.4, 9.1).toStringAsFixed(1));
  }

  /// Deterministic per-day readings across the quarter window. Values sit in
  /// realistic ranges and drift gently (via [_wave]) so the readiness score and
  /// each contributor land in believable, non-flat states across all ranges.
  ({double value, String unit}) _mockReading(MetricType metric, int index) {
    final progress = index / (_mockDays - 1); // 0 (oldest) -> 1 (last night)
    switch (metric) {
      case MetricType.hrv:
        // ms, SDNN-style. Gentle rise across the quarter with a weekly ripple.
        final value = 38 + progress * 14 + (_wave(index, 7, 1) - 0.5) * 8;
        return (value: value.clamp(28, 68).roundToDouble(), unit: 'ms');
      case MetricType.restingHeartRate:
        // bpm, low-50s, easing down as recovery improves.
        final value = 57 - progress * 5 + (_wave(index, 6, 0) - 0.5) * 4;
        return (value: value.clamp(46, 64).roundToDouble(), unit: 'bpm');
      case MetricType.respiratoryRate:
        // breaths/min overnight, tight personal band.
        final value = 14.5 + (_wave(index, 5, 2) - 0.5) * 1.4;
        return (
          value: double.parse(value.clamp(13.2, 15.8).toStringAsFixed(1)),
          unit: 'brpm',
        );
      case MetricType.temperature:
        // Overnight temperature deviation from baseline, °C — mostly small.
        final value = (_wave(index, 9, 3) - 0.5) * 1.0;
        return (
          value: double.parse(value.clamp(-0.4, 0.7).toStringAsFixed(1)),
          unit: '°C',
        );
      case MetricType.bloodOxygen:
        // SpO2 percent.
        final value = 96 + (_wave(index, 4, 0) * 2);
        return (value: value.clamp(95, 99).roundToDouble(), unit: '%');
      case MetricType.activeEnergy:
        // kcal active energy for the prior day — a broad weekly swing.
        final value = 400 + (_wave(index, 7, 4) - 0.5) * 460;
        return (value: value.clamp(180, 720).roundToDouble(), unit: 'kcal');
      case MetricType.steps:
        final value = 7500 + (_wave(index, 7, 4) - 0.5) * 7000;
        return (value: value.clamp(3200, 12500).roundToDouble(), unit: 'count');
      case MetricType.sleep:
      case MetricType.heartRate:
      case MetricType.mindfulMinutes:
      case MetricType.medication:
        return (value: 0, unit: '');
    }
  }
}

String sleepSampleDedupeKey(HealthSample sample) {
  return [
    sample.userId,
    sample.source,
    sample.metricType.name,
    sample.start.toIso8601String(),
    sample.end.toIso8601String(),
  ].join('|');
}

List<HealthSample> dedupeSleepSamples(Iterable<HealthSample> samples) {
  final byKey = <String, HealthSample>{};
  for (final sample in samples) {
    if (sample.metricType != MetricType.sleep) {
      continue;
    }
    byKey[sleepSampleDedupeKey(sample)] = sample;
  }
  return byKey.values.toList()..sort((a, b) => a.start.compareTo(b.start));
}

List<DailySummary> summarizeSleepSamples(List<HealthSample> samples) {
  final totalsByPatientDay = <String, _DailySleepTotal>{};
  for (final sample in samples.where((s) => s.metricType == MetricType.sleep)) {
    final day = DateTime(sample.end.year, sample.end.month, sample.end.day);
    final key = '${sample.userId}|${day.toIso8601String()}';
    totalsByPatientDay.update(
      key,
      (total) => total.add(sample.value),
      ifAbsent: () => _DailySleepTotal(sample.userId, day, sample.value),
    );
  }

  final summaries = totalsByPatientDay.values.map((total) {
    final sleepHours = double.parse(total.hours.toStringAsFixed(2));
    final quality = (sleepHours / 8 * 100).clamp(45, 96).round();
    final trend = switch (sleepHours) {
      < 6 => 'short night',
      >= 7.5 => 'protective',
      _ => 'steady',
    };

    return DailySummary(
      userId: total.userId,
      date: total.day,
      sleepDurationHours: sleepHours,
      sleepQualityProxy: quality,
      trendFlag: trend,
    );
  }).toList()..sort((a, b) => a.date.compareTo(b.date));

  return summaries;
}

class _DailySleepTotal {
  const _DailySleepTotal(this.userId, this.day, this.hours);

  final String userId;
  final DateTime day;
  final double hours;

  _DailySleepTotal add(double additionalHours) {
    return _DailySleepTotal(userId, day, hours + additionalHours);
  }
}
