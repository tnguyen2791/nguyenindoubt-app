import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';

void main() {
  test('mock provider returns sleep samples after permission', () async {
    final provider = MockHealthDataProvider();

    expect(
      await provider.checkPermissionStatus(),
      HealthPermissionStatus.notRequested,
    );
    expect(
      await provider.fetchAvailableMetrics(
        HealthRange(
          start: DateTime.now().subtract(const Duration(days: 8)),
          end: DateTime.now(),
        ),
      ),
      [MetricType.sleep],
    );
    expect(
      await provider.fetchSleepSamples(
        HealthRange(
          start: DateTime.now().subtract(const Duration(days: 8)),
          end: DateTime.now(),
        ),
      ),
      isEmpty,
    );

    await provider.requestPermissions();
    expect(
      await provider.checkPermissionStatus(),
      HealthPermissionStatus.ready,
    );
    final samples = await provider.fetchSleepSamples(
      HealthRange(
        start: DateTime.now().subtract(const Duration(days: 8)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    expect(samples, isNotEmpty);
    expect(
      samples.every((sample) => sample.metricType == MetricType.sleep),
      isTrue,
    );
  });

  test('unavailable mock provider refuses permission requests', () async {
    final provider = MockHealthDataProvider(
      initialStatus: HealthPermissionStatus.unavailable,
    );

    expect(await provider.requestPermissions(), isFalse);
    expect(
      await provider.checkPermissionStatus(),
      HealthPermissionStatus.unavailable,
    );
    expect(
      await provider.fetchSleepSamples(
        HealthRange(
          start: DateTime.now().subtract(const Duration(days: 8)),
          end: DateTime.now(),
        ),
      ),
      isEmpty,
    );
  });

  test('sleep samples summarize into daily trend rows', () async {
    final provider = MockHealthDataProvider();
    await provider.requestPermissions();
    final samples = await provider.fetchSleepSamples(
      HealthRange(
        start: DateTime.now().subtract(const Duration(days: 8)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    final summaries = summarizeSleepSamples(samples);

    expect(summaries.length, samples.length);
    expect(
      summaries.any((summary) => summary.trendFlag == 'short night'),
      isTrue,
    );
  });

  test('sleep samples aggregate by patient and day', () {
    final day = DateTime(2026, 1, 2, 6);
    final samples = [
      HealthSample(
        userId: 'patient-demo',
        source: 'Health Connect',
        metricType: MetricType.sleep,
        start: day.subtract(const Duration(hours: 3)),
        end: day,
        value: 3,
        unit: 'hours',
        createdAt: day,
      ),
      HealthSample(
        userId: 'patient-demo',
        source: 'Health Connect',
        metricType: MetricType.sleep,
        start: day,
        end: day.add(const Duration(hours: 4)),
        value: 4,
        unit: 'hours',
        createdAt: day,
      ),
    ];

    final summaries = summarizeSleepSamples(samples);

    expect(summaries, hasLength(1));
    expect(summaries.single.sleepDurationHours, 7);
    expect(summaries.single.trendFlag, 'steady');
  });

  test('sleep sample dedupe uses source and time range', () {
    final now = DateTime(2026, 1, 2, 6);
    final sample = HealthSample(
      userId: 'patient-demo',
      source: 'Apple Health',
      metricType: MetricType.sleep,
      start: now.subtract(const Duration(hours: 7)),
      end: now,
      value: 7,
      unit: 'hours',
      createdAt: now,
    );

    expect(dedupeSleepSamples([sample, sample]), hasLength(1));
  });
}
