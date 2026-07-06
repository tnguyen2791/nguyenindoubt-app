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

  test('clinician sleep access follows accepted link status only', () async {
    final repository = InMemoryAppRepository();

    final sleepBundle = await repository.getPatientSleepSummary(
      clinicianId: demoClinician.id,
      patientId: linkedPatient.id,
    );
    expect(sleepBundle.summaries, isNotEmpty);

    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );

    await repository.updateDemoClinicianLinkStatus(
      clinicianId: demoClinician.id,
      patientId: linkedPatient.id,
      status: LinkStatus.revoked,
    );
    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: linkedPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );

    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: 'patient-missing',
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test(
    'clinician journal access is denied regardless of link status',
    () async {
      final repository = InMemoryAppRepository();

      for (final patientId in [
        linkedPatient.id,
        demoPatient.id,
        'patient-missing',
      ]) {
        expect(
          repository.getJournalEntriesForPatient(
            requesterUserId: demoClinician.id,
            patientId: patientId,
          ),
          throwsA(isA<PrivacyException>()),
        );
      }

      await repository.updateDemoClinicianLinkStatus(
        clinicianId: demoClinician.id,
        patientId: linkedPatient.id,
        status: LinkStatus.revoked,
      );
      expect(
        repository.getJournalEntriesForPatient(
          requesterUserId: demoClinician.id,
          patientId: linkedPatient.id,
        ),
        throwsA(isA<PrivacyException>()),
      );
    },
  );

  test('patient can read own journals but not another patient journal', () {
    final repository = InMemoryAppRepository();

    expect(
      repository.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      ),
      completion(isNotEmpty),
    );
    expect(
      repository.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: linkedPatient.id,
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
      requesterUserId: demoPatient.id,
      entry: JournalEntry(
        id: 'journal-persisted',
        userId: demoPatient.id,
        title: 'Still here',
        body: 'This should survive a new repository.',
        moodTag: 'steady',
        createdAt: now,
      ),
    );
    await firstRepository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
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

    final entries = await secondRepository.getJournalEntriesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    final summaries = await secondRepository.getDailySummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
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

  test('reset clears local demo changes and restores seeded state', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    const storageKey = 'repository-reset-test-storage';
    final repository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );
    final now = DateTime(2026, 1, 3, 8);

    await repository.addJournalEntry(
      requesterUserId: demoPatient.id,
      entry: JournalEntry(
        id: 'journal-reset-me',
        userId: demoPatient.id,
        title: 'Temporary entry',
        body: 'This should be cleared by reset.',
        createdAt: now,
      ),
    );
    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [
        HealthSample(
          userId: demoPatient.id,
          source: 'test import',
          metricType: MetricType.sleep,
          start: now.subtract(const Duration(hours: 6)),
          end: now,
          value: 6,
          unit: 'hours',
          createdAt: now,
        ),
      ],
    );
    await repository.grantPatientConsent(demoPatient.id, 'NID-1138');

    await repository.resetDemoData();

    final restoredRepository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );
    final entries = await restoredRepository.getJournalEntriesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    final summaries = await restoredRepository.getDailySummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    final linkedPatients = await restoredRepository.getLinkedPatients(
      demoClinician.id,
    );
    final resources = await restoredRepository.getResourceCards();

    expect(
      entries.map((entry) => entry.id),
      isNot(contains('journal-reset-me')),
    );
    expect(entries.map((entry) => entry.id), contains('journal-1'));
    expect(summaries, isEmpty);
    expect(
      linkedPatients.map((patient) => patient.id),
      isNot(contains(demoPatient.id)),
    );
    expect(
      linkedPatients.map((patient) => patient.id),
      contains(linkedPatient.id),
    );
    expect(resources, isNotEmpty);
  });

  test(
    'local session and patient profile persist across repository instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const storageKey = 'repository-session-test-storage';
      final firstRepository = InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      );

      final updatedPatient = await firstRepository.updateDemoPatientProfile(
        displayName: 'Taylor Nguyen',
      );
      await firstRepository.saveSession(
        AppSession(stage: SessionStage.patient, userId: updatedPatient.id),
      );

      final secondRepository = InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      );

      expect(secondRepository.patientDemo.displayName, 'Taylor Nguyen');
      expect(secondRepository.currentSession.stage, SessionStage.patient);
      expect(secondRepository.currentSession.userId, demoPatient.id);
    },
  );

  test('reset clears persisted session', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    const storageKey = 'repository-reset-session-test-storage';
    final repository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );

    await repository.saveSession(
      AppSession(stage: SessionStage.clinician, userId: demoClinician.id),
    );
    await repository.resetDemoData();

    final restoredRepository = InMemoryAppRepository(
      preferences: preferences,
      storageKey: storageKey,
    );

    expect(restoredRepository.currentSession.stage, SessionStage.signedOut);
  });
}
