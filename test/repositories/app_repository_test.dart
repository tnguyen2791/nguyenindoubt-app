import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clinician sees only accepted linked patients', () async {
    final repository = InMemoryAppRepository();

    final patients = await repository.getLinkedPatients(demoClinician.id);

    expect(patients.map((patient) => patient.id), contains(linkedPatient.id));
    expect(
      patients.map((patient) => patient.id),
      isNot(contains(demoPatient.id)),
    );
  });

  test('clinician can read linked sleep but cannot read journals', () async {
    final repository = InMemoryAppRepository();

    final sleepBundle = await repository.getPatientSleepSummary(
      clinicianId: demoClinician.id,
      patientId: linkedPatient.id,
    );

    expect(sleepBundle.summaries, isNotEmpty);
    expect(
      repository.getPatientJournalEntries(
        clinicianId: demoClinician.id,
        patientId: linkedPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('unlinked clinician access to patient sleep is rejected', () {
    final repository = InMemoryAppRepository();

    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('local demo data persists across repository instances', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    const storageKey = 'repository-test-storage';
    final firstRepository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );
    final now = DateTime(2026, 1, 2, 8);

    await firstRepository.addJournalEntry(
      JournalEntry(
        id: 'journal-persisted',
        userId: demoPatient.id,
        title: 'Still here',
        body: 'This should survive a new repository.',
        moodTag: 'steady',
        createdAt: now,
      ),
    );
    await firstRepository.saveImportedSleep(
      userId: demoPatient.id,
      samples: [
        HealthSample(
          userId: demoPatient.id,
          source: 'test import',
          metricType: MetricType.sleep,
          start: now.subtract(const Duration(hours: 7)),
          end: now,
          value: 7,
          unit: 'hours',
          createdAt: now,
        ),
      ],
    );
    await firstRepository.grantPatientConsent(demoPatient.id, 'NID-1138');

    final secondRepository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );

    final entries = await secondRepository.getJournalEntries(demoPatient.id);
    final summaries = await secondRepository.getDailySummaries(demoPatient.id);
    final linkedPatients = await secondRepository.getLinkedPatients(
      demoClinician.id,
    );

    expect(entries.map((entry) => entry.id), contains('journal-persisted'));
    expect(summaries, hasLength(1));
    expect(summaries.single.sleepDurationHours, 7);
    expect(
      linkedPatients.map((patient) => patient.id),
      contains(demoPatient.id),
    );
  });
}
