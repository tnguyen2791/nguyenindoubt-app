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

abstract class HealthDataProvider {
  HealthPermissionStatus get permissionStatus;

  Future<HealthPermissionStatus> checkPermissionStatus();

  Future<bool> requestPermissions();

  Future<List<HealthSample>> fetchSleepSamples(HealthRange range);

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
    return const [MetricType.sleep];
  }

  @override
  Future<List<HealthSample>> fetchSleepSamples(HealthRange range) async {
    if (_permissionStatus != HealthPermissionStatus.ready) {
      return const [];
    }

    final now = DateTime.now();
    final durations = <double>[7.4, 6.1, 6.8, 7.9, 5.7, 7.1, 7.6];
    return List<HealthSample>.generate(durations.length, (index) {
      final sleepEnd = DateTime(
        now.year,
        now.month,
        now.day,
        6 + index % 2,
        45,
      ).subtract(Duration(days: durations.length - index - 1));
      final sleepStart = sleepEnd.subtract(
        Duration(minutes: (durations[index] * 60).round()),
      );

      return HealthSample(
        userId: userId,
        source: 'Apple Health mock',
        metricType: MetricType.sleep,
        start: sleepStart,
        end: sleepEnd,
        value: durations[index],
        unit: 'hours',
        createdAt: now,
      );
    }).where((sample) {
      return !sample.end.isBefore(range.start) &&
          !sample.start.isAfter(range.end);
    }).toList();
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
