import '../models/app_models.dart';

abstract class HealthDataProvider {
  Future<bool> requestPermissions();

  Future<List<HealthSample>> fetchSleepSamples(HealthRange range);

  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range);
}

class MockHealthDataProvider implements HealthDataProvider {
  MockHealthDataProvider({this.userId = 'patient-demo'});

  final String userId;
  bool _permissionsGranted = false;

  @override
  Future<bool> requestPermissions() async {
    _permissionsGranted = true;
    return true;
  }

  @override
  Future<List<MetricType>> fetchAvailableMetrics(HealthRange range) async {
    return const [
      MetricType.sleep,
      MetricType.steps,
      MetricType.heartRate,
      MetricType.hrv,
      MetricType.mindfulMinutes,
    ];
  }

  @override
  Future<List<HealthSample>> fetchSleepSamples(HealthRange range) async {
    if (!_permissionsGranted) {
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

List<DailySummary> summarizeSleepSamples(List<HealthSample> samples) {
  final summaries = samples.map((sample) {
    final quality = (sample.value / 8 * 100).clamp(45, 96).round();
    final trend = switch (sample.value) {
      < 6 => 'short night',
      >= 7.5 => 'protective',
      _ => 'steady',
    };

    return DailySummary(
      userId: sample.userId,
      date: DateTime(sample.end.year, sample.end.month, sample.end.day),
      sleepDurationHours: sample.value,
      sleepQualityProxy: quality,
      trendFlag: trend,
    );
  }).toList()..sort((a, b) => a.date.compareTo(b.date));

  return summaries;
}
