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

  test('invite validation previews without granting access', () async {
    final repository = InMemoryAppRepository();

    final validation = await repository.validateInviteCode(
      patientId: demoPatient.id,
      inviteCode: ' nid-1138 ',
    );

    expect(validation.canAccept, isTrue);
    expect(validation.normalizedCode, 'NID-1138');
    expect(validation.clinicianDisplayName, demoClinician.displayName);
    expect(repository.patientDemo.consentStatus, ConsentStatus.notAsked);
    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('invite validation failures never grant access', () async {
    final repository = InMemoryAppRepository();

    final empty = await repository.validateInviteCode(
      patientId: demoPatient.id,
      inviteCode: ' ',
    );
    final malformed = await repository.validateInviteCode(
      patientId: demoPatient.id,
      inviteCode: 'bad-code',
    );
    final missing = await repository.validateInviteCode(
      patientId: demoPatient.id,
      inviteCode: 'NID-0000',
    );
    final wrongPatient = await repository.validateInviteCode(
      patientId: demoPatient.id,
      inviteCode: 'NID-8274',
    );
    final expired = await repository.validateInviteCode(
      patientId: expiredInvitePatient.id,
      inviteCode: 'NID-4455',
    );

    expect(empty.status, InviteValidationStatus.empty);
    expect(malformed.status, InviteValidationStatus.malformed);
    expect(missing.status, InviteValidationStatus.missing);
    expect(wrongPatient.status, InviteValidationStatus.wrongPatient);
    expect(expired.status, InviteValidationStatus.expired);
    expect(repository.patientDemo.consentStatus, ConsentStatus.notAsked);
  });

  test('accepting and revoking invite updates access and history', () async {
    final repository = InMemoryAppRepository();

    final accepted = await repository.acceptInvite(
      patientId: demoPatient.id,
      inviteCode: 'NID-1138',
    );
    expect(accepted.consentStatus, ConsentStatus.granted);
    expect(accepted.clinicCode, 'NID-1138');

    final linkedPatients = await repository.getLinkedPatients(demoClinician.id);
    expect(
      linkedPatients.map((patient) => patient.id),
      contains(demoPatient.id),
    );

    final acceptedHistory = await repository.getConsentHistory(
      patientId: demoPatient.id,
    );
    expect(acceptedHistory, hasLength(1));
    expect(acceptedHistory.single.action, ConsentEventAction.accepted);
    expect(acceptedHistory.single.inviteCode, 'NID-1138');

    final revoked = await repository.revokeConsent(patientId: demoPatient.id);
    expect(revoked.consentStatus, ConsentStatus.revoked);
    expect(revoked.clinicCode, isNull);
    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );

    final fullHistory = await repository.getConsentHistory(
      patientId: demoPatient.id,
    );
    expect(fullHistory, hasLength(2));
    expect(fullHistory.first.action, ConsentEventAction.revoked);
    expect(fullHistory.last.action, ConsentEventAction.accepted);
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
    await firstRepository.acceptInvite(
      patientId: demoPatient.id,
      inviteCode: 'NID-1138',
    );

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
    final history = await secondRepository.getConsentHistory(
      patientId: demoPatient.id,
    );

    expect(entries.map((entry) => entry.id), contains('journal-persisted'));
    expect(summaries, hasLength(1));
    expect(summaries.single.sleepDurationHours, 7);
    expect(
      linkedPatients.map((patient) => patient.id),
      contains(demoPatient.id),
    );
    expect(history.single.action, ConsentEventAction.accepted);
  });

  test('imported sleep deduplicates and syncs incrementally', () async {
    final repository = InMemoryAppRepository();
    final firstNight = DateTime(2026, 1, 2, 6);
    final secondNight = DateTime(2026, 1, 3, 6);
    final firstSample = HealthSample(
      userId: demoPatient.id,
      source: 'Health Connect',
      metricType: MetricType.sleep,
      start: firstNight.subtract(const Duration(hours: 7)),
      end: firstNight,
      value: 7,
      unit: 'hours',
      createdAt: firstNight,
    );
    final secondSample = HealthSample(
      userId: demoPatient.id,
      source: 'Health Connect',
      metricType: MetricType.sleep,
      start: secondNight.subtract(const Duration(hours: 6)),
      end: secondNight,
      value: 6,
      unit: 'hours',
      createdAt: secondNight,
    );

    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [firstSample],
    );
    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [firstSample, secondSample],
    );

    final summaries = await repository.getDailySummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );

    expect(summaries, hasLength(2));
    expect(
      summaries.map((summary) => summary.sleepDurationHours),
      containsAll([7, 6]),
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
    await repository.acceptInvite(
      patientId: demoPatient.id,
      inviteCode: 'NID-1138',
    );

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
