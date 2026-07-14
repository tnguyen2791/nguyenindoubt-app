import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/services/readiness.dart';

void main() {
  final date = DateTime(2026, 7, 7);

  test('a rested day scores protective with six contributors in order', () {
    // The mock provider's best (last) day, paired with its 7-night sleep window.
    final summary = computeReadiness(
      inputs: ReadinessInputs(
        userId: 'patient-demo',
        date: date,
        hrvMs: 52,
        restingHeartRateBpm: 51,
        respiratoryRateBrpm: 14.3,
        temperatureDeviationC: -0.1,
        activeEnergyKcal: 560,
      ),
      recentSleepHours: const [7.4, 6.1, 6.8, 7.9, 5.7, 7.1, 7.6],
    );

    expect(summary.readinessScore, 90);
    expect(summary.state, 'protective');
    expect(summary.contributors, hasLength(6));
    expect(summary.contributors.map((c) => c.name).toList(), [
      'Resting HR',
      'HRV balance',
      'Body temp',
      'Respiratory rate',
      'Sleep balance',
      'Prior-day activity',
    ]);
    expect(summary.contributors.map((c) => c.metric).toList(), [
      MetricType.restingHeartRate,
      MetricType.hrv,
      MetricType.temperature,
      MetricType.respiratoryRate,
      MetricType.sleep,
      MetricType.activeEnergy,
    ]);
  });

  test('each contributor state word follows from its own value', () {
    final summary = computeReadiness(
      inputs: ReadinessInputs(
        userId: 'patient-demo',
        date: date,
        hrvMs: 52,
        restingHeartRateBpm: 51,
        respiratoryRateBrpm: 14.3,
        temperatureDeviationC: -0.1,
        activeEnergyKcal: 560,
      ),
      recentSleepHours: const [7.4, 6.1, 6.8, 7.9, 5.7, 7.1, 7.6],
    );

    ReadinessContributor byName(String name) =>
        summary.contributors.firstWhere((c) => c.name == name);

    expect(byName('Resting HR').word, 'optimal');
    expect(byName('HRV balance').word, 'optimal');
    expect(byName('Body temp').word, 'optimal');
    expect(byName('Respiratory rate').word, 'optimal');
    // Recent sleep averages ~6.9h vs an 8h need — good, not optimal.
    expect(byName('Sleep balance').word, 'good');
    expect(byName('Prior-day activity').word, 'optimal');

    // The raw values ride along for the detail surface.
    expect(byName('Resting HR').value, 51);
    expect(byName('Resting HR').unit, 'bpm');
    expect(byName('HRV balance').unit, 'ms');
  });

  test('a strained day reads pay attention across recovery signals', () {
    final summary = computeReadiness(
      inputs: ReadinessInputs(
        userId: 'patient-demo',
        date: date,
        hrvMs: 30,
        restingHeartRateBpm: 66,
        respiratoryRateBrpm: 17.5,
        temperatureDeviationC: 0.9,
        activeEnergyKcal: 900,
      ),
      recentSleepHours: const [4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5],
    );

    expect(summary.readinessScore, 32);
    expect(summary.state, 'pay attention');

    final watchWords = summary.contributors
        .where((c) => c.word == 'fair' || c.word == 'pay attention')
        .map((c) => c.name)
        .toList();
    expect(watchWords, contains('HRV balance'));
    expect(watchWords, contains('Resting HR'));
    expect(watchWords, contains('Body temp'));
    expect(watchWords, contains('Sleep balance'));
  });

  test(
    'missing signals fall back to neutral rather than tanking the score',
    () {
      final summary = computeReadiness(
        inputs: ReadinessInputs(userId: 'patient-demo', date: date),
      );

      // Every contributor neutral (75) -> overall 75 -> balanced.
      expect(summary.readinessScore, 75);
      expect(summary.state, 'balanced');
      expect(summary.contributors.every((c) => c.word == 'good'), isTrue);
      // No readings means no raw values on the contributors.
      expect(summary.contributors.every((c) => c.value == null), isTrue);
    },
  );

  test('contributor fractions stay within 0..1', () {
    final summary = computeReadiness(
      inputs: ReadinessInputs(
        userId: 'patient-demo',
        date: date,
        hrvMs: 120, // extreme high — subscore clamps at 100
        restingHeartRateBpm: 40,
        respiratoryRateBrpm: 30, // extreme — clamps at 0
        temperatureDeviationC: 2.0,
        activeEnergyKcal: 50,
      ),
      recentSleepHours: const [9, 9, 9],
    );

    for (final c in summary.contributors) {
      expect(c.fraction, inInclusiveRange(0.0, 1.0));
    }
    expect(summary.readinessScore, inInclusiveRange(0, 100));
  });

  test('readinessStateWord maps the score bands', () {
    expect(readinessStateWord(90), 'protective');
    expect(readinessStateWord(85), 'protective');
    expect(readinessStateWord(75), 'balanced');
    expect(readinessStateWord(60), 'fair');
    expect(readinessStateWord(20), 'pay attention');
  });

  test(
    'readinessInputsFromSamples averages same-day multi-metric readings',
    () {
      final samples = [
        _sample('patient-demo', MetricType.hrv, 40, 'ms'),
        _sample('patient-demo', MetricType.hrv, 50, 'ms'),
        _sample('patient-demo', MetricType.restingHeartRate, 52, 'bpm'),
        _sample('patient-demo', MetricType.activeEnergy, 500, 'kcal'),
      ];

      final inputs = readinessInputsFromSamples(
        userId: 'patient-demo',
        date: date,
        samples: samples,
        sleepHours: 7.5,
      );

      expect(inputs.hrvMs, 45); // (40 + 50) / 2
      expect(inputs.restingHeartRateBpm, 52);
      expect(inputs.activeEnergyKcal, 500);
      expect(inputs.respiratoryRateBrpm, isNull);
      expect(inputs.temperatureDeviationC, isNull);
      expect(inputs.sleepHours, 7.5);
    },
  );
}

HealthSample _sample(
  String userId,
  MetricType metric,
  double value,
  String unit,
) {
  final now = DateTime(2026, 7, 7, 7);
  return HealthSample(
    userId: userId,
    source: 'Apple Health mock',
    metricType: metric,
    start: now.subtract(const Duration(hours: 8)),
    end: now,
    value: value,
    unit: unit,
    createdAt: now,
  );
}
