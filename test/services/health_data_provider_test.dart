import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';

void main() {
  test('mock provider returns sleep samples after permission', () async {
    final provider = MockHealthDataProvider();

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
}
