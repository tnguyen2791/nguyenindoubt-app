import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadinessSummary _readiness(String userId, DateTime date, int score) {
  return ReadinessSummary(
    userId: userId,
    date: date,
    readinessScore: score,
    state: 'balanced',
    contributors: [
      ReadinessContributor(
        metric: MetricType.restingHeartRate,
        name: 'Resting HR',
        word: 'optimal',
        fraction: 0.95,
        value: 51,
        unit: 'bpm',
      ),
      const ReadinessContributor(
        metric: MetricType.hrv,
        name: 'HRV balance',
        word: 'good',
        fraction: 0.8,
        value: 46,
        unit: 'ms',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'readiness summaries save and read back for the owning patient',
    () async {
      final repository = InMemoryAppRepository();
      final date = DateTime(2026, 7, 7);

      await repository.saveReadinessSummaries(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
        summaries: [_readiness(demoPatient.id, date, 82)],
      );

      final read = await repository.getReadinessSummariesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      );
      expect(read, hasLength(1));
      expect(read.single.readinessScore, 82);
      expect(read.single.contributors, hasLength(2));
      expect(read.single.contributors.first.name, 'Resting HR');
      expect(read.single.contributors.first.value, 51);
    },
  );

  test('saving the same day upserts rather than duplicating', () async {
    final repository = InMemoryAppRepository();
    final date = DateTime(2026, 7, 7);

    await repository.saveReadinessSummaries(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      summaries: [_readiness(demoPatient.id, date, 60)],
    );
    await repository.saveReadinessSummaries(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      summaries: [_readiness(demoPatient.id, date, 88)],
    );

    final read = await repository.getReadinessSummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    expect(read, hasLength(1));
    expect(read.single.readinessScore, 88);
  });

  test('a patient cannot read or write another patient readiness', () async {
    final repository = InMemoryAppRepository();
    final date = DateTime(2026, 7, 7);

    expect(
      repository.saveReadinessSummaries(
        requesterUserId: demoPatient.id,
        patientId: linkedPatient.id,
        summaries: [_readiness(linkedPatient.id, date, 70)],
      ),
      throwsA(isA<PrivacyException>()),
    );
    expect(
      repository.getReadinessSummariesForPatient(
        requesterUserId: demoPatient.id,
        patientId: linkedPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('readiness samples must belong to the patient', () async {
    final repository = InMemoryAppRepository();
    final date = DateTime(2026, 7, 7);

    expect(
      repository.saveReadinessSummaries(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
        summaries: [_readiness('someone-else', date, 70)],
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('readiness survives a persisted round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final date = DateTime(2026, 7, 7);

    final first = InMemoryAppRepository(preferences: prefs);
    await first.saveReadinessSummaries(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      summaries: [_readiness(demoPatient.id, date, 77)],
    );

    // A fresh repository over the same prefs restores the readiness rows.
    final restored = InMemoryAppRepository(preferences: prefs);
    final read = await restored.getReadinessSummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    expect(read, hasLength(1));
    expect(read.single.readinessScore, 77);
    expect(read.single.contributors.last.name, 'HRV balance');
    expect(read.single.contributors.last.metric, MetricType.hrv);
  });

  test('clinician sleep bundle never carries readiness', () async {
    // The clinician surface reads only sleep summaries + samples. Readiness is
    // patient-owned and has no clinician path — proven here by the bundle type
    // exposing only sleep data even after readiness is written.
    final repository = InMemoryAppRepository();
    await repository.saveReadinessSummaries(
      requesterUserId: linkedPatient.id,
      patientId: linkedPatient.id,
      summaries: [_readiness(linkedPatient.id, DateTime(2026, 7, 7), 82)],
    );

    final bundle = await repository.getPatientSleepSummary(
      clinicianId: demoClinician.id,
      patientId: linkedPatient.id,
    );
    // Bundle carries sleep summaries + samples only; no readiness field exists.
    expect(bundle.summaries, isNotEmpty);
    expect(
      bundle.samples.every((s) => s.metricType == MetricType.sleep),
      isTrue,
    );
  });
}
