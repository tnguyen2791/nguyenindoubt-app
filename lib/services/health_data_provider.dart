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
    return List<HealthSample>.generate(_mockDurations.length, (index) {
      final sleepEnd = DateTime(
        now.year,
        now.month,
        now.day,
        6 + index % 2,
        45,
      ).subtract(Duration(days: _mockDurations.length - index - 1));
      final sleepStart = sleepEnd.subtract(
        Duration(minutes: (_mockDurations[index] * 60).round()),
      );

      return HealthSample(
        userId: userId,
        source: 'Apple Health mock',
        metricType: MetricType.sleep,
        start: sleepStart,
        end: sleepEnd,
        value: _mockDurations[index],
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

  static const _mockDurations = <double>[7.4, 6.1, 6.8, 7.9, 5.7, 7.1, 7.6];
  static const _mockDays = 7;

  static const _mockReadinessMetrics = <MetricType>[
    MetricType.hrv,
    MetricType.restingHeartRate,
    MetricType.respiratoryRate,
    MetricType.temperature,
    MetricType.bloodOxygen,
    MetricType.activeEnergy,
    MetricType.steps,
  ];

  /// Deterministic per-day readings across the 7-day window. Values sit in
  /// realistic ranges and drift gently so the readiness score and each
  /// contributor land in believable, non-flat states.
  ({double value, String unit}) _mockReading(MetricType metric, int index) {
    switch (metric) {
      case MetricType.hrv:
        // ms, SDNN-style. Gentle rise across the week.
        const values = <double>[42, 39, 45, 48, 44, 50, 52];
        return (value: values[index], unit: 'ms');
      case MetricType.restingHeartRate:
        // bpm, low-50s, within a personal baseline band.
        const values = <double>[54, 56, 53, 51, 55, 52, 51];
        return (value: values[index], unit: 'bpm');
      case MetricType.respiratoryRate:
        // breaths/min overnight.
        const values = <double>[14.6, 15.1, 14.4, 14.2, 15.3, 14.5, 14.3];
        return (value: values[index], unit: 'brpm');
      case MetricType.temperature:
        // Overnight skin/body temperature deviation from baseline, °C.
        const values = <double>[0.1, 0.4, -0.1, -0.2, 0.6, 0.0, -0.1];
        return (value: values[index], unit: '°C');
      case MetricType.bloodOxygen:
        // SpO2 percent.
        const values = <double>[97, 96, 97, 98, 96, 97, 98];
        return (value: values[index], unit: '%');
      case MetricType.activeEnergy:
        // kcal active energy for the prior day.
        const values = <double>[420, 260, 510, 640, 300, 480, 560];
        return (value: values[index], unit: 'kcal');
      case MetricType.steps:
        const values = <double>[7200, 4300, 9100, 11200, 5200, 8600, 9800];
        return (value: values[index], unit: 'count');
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
