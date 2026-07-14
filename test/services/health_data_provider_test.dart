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

  test(
    'available metrics widen to the full readiness set once ready',
    () async {
      final provider = MockHealthDataProvider();
      final range = HealthRange(
        start: DateTime.now().subtract(const Duration(days: 8)),
        end: DateTime.now().add(const Duration(days: 1)),
      );

      // Before permission: sleep-only, matching the pre-Phase-13 behavior.
      expect(await provider.fetchAvailableMetrics(range), [MetricType.sleep]);

      await provider.requestPermissions();
      final available = await provider.fetchAvailableMetrics(range);
      expect(available.first, MetricType.sleep);
      expect(
        available,
        containsAll(<MetricType>[
          MetricType.hrv,
          MetricType.restingHeartRate,
          MetricType.respiratoryRate,
          MetricType.temperature,
          MetricType.bloodOxygen,
          MetricType.activeEnergy,
          MetricType.steps,
        ]),
      );
    },
  );

  test('fetchSamples emits deterministic multi-signal readings', () async {
    final provider = MockHealthDataProvider();
    final range = HealthRange(
      start: DateTime.now().subtract(const Duration(days: 8)),
      end: DateTime.now().add(const Duration(days: 1)),
    );

    // No permission yet -> empty, no throw.
    expect(
      await provider.fetchSamples(metrics: kReadinessMetricTypes, range: range),
      isEmpty,
    );

    await provider.requestPermissions();
    final samples = await provider.fetchSamples(
      metrics: kReadinessMetricTypes,
      range: range,
    );

    expect(samples, isNotEmpty);
    // Sleep is never emitted through the generic path (it has its own read).
    expect(samples.any((s) => s.metricType == MetricType.sleep), isFalse);
    // Deterministic: the same call twice yields identical values.
    final again = await provider.fetchSamples(
      metrics: kReadinessMetricTypes,
      range: range,
    );
    expect(
      samples.map((s) => s.value).toList(),
      again.map((s) => s.value).toList(),
    );

    // Latest reading is last night's deterministic value (the mock now emits a
    // rolling quarter; last-night HRV lands at 50 ms) in realistic units.
    final hrv = samples.where((s) => s.metricType == MetricType.hrv).toList()
      ..sort((a, b) => a.end.compareTo(b.end));
    expect(hrv.last.value, 50);
    expect(hrv.last.unit, 'ms');

    final rhr =
        samples
            .where((s) => s.metricType == MetricType.restingHeartRate)
            .toList()
          ..sort((a, b) => a.end.compareTo(b.end));
    expect(rhr.last.value, 51);
    expect(rhr.last.unit, 'bpm');
  });

  test('fetchSamples honors the requested metric subset', () async {
    final provider = MockHealthDataProvider();
    await provider.requestPermissions();
    final samples = await provider.fetchSamples(
      metrics: const [MetricType.hrv],
      range: HealthRange(
        start: DateTime.now().subtract(const Duration(days: 8)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    expect(samples, isNotEmpty);
    expect(samples.every((s) => s.metricType == MetricType.hrv), isTrue);
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
    // The mock now emits a rolling quarter; over the full window the
    // deterministic durations include a handful of short nights.
    final samples = await provider.fetchSleepSamples(
      HealthRange(
        start: DateTime.now().subtract(const Duration(days: 91)),
        end: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    final summaries = summarizeSleepSamples(samples);

    expect(summaries.length, samples.length);
    expect(summaries.length, greaterThan(80));
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
