import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HealthSample sleepSampleFor(String userId, DateTime end, double hours) {
    return HealthSample(
      userId: userId,
      source: 'test import',
      metricType: MetricType.sleep,
      start: end.subtract(Duration(hours: hours.round())),
      end: end,
      value: hours,
      unit: 'hours',
      createdAt: end,
    );
  }

  test('patient can export own data across all categories', () async {
    final repository = InMemoryAppRepository();
    final now = DateTime(2026, 2, 1, 7);

    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [sleepSampleFor(demoPatient.id, now, 7)],
    );
    await repository.acceptInvite(
      patientId: demoPatient.id,
      inviteCode: 'NID-1138',
    );

    final export = await repository.exportPatientData(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );

    expect(export.exportVersion, 1);
    expect(export.patientId, demoPatient.id);
    expect(export.profile.id, demoPatient.id);
    expect(export.journalEntries, isNotEmpty);
    expect(export.healthSamples, isNotEmpty);
    expect(export.dailySummaries, isNotEmpty);
    expect(export.consentHistory, isNotEmpty);
    expect(
      export.clinicianLinks.every((link) => link.patientUserId == demoPatient.id),
      isTrue,
    );

    // Export serializes to a JSON-encodable map.
    final json = patientDataExportToJson(export);
    expect(json['patientId'], demoPatient.id);
    expect(json['journalEntries'], isA<List<Object?>>());
  });

  test('export enforces patient ownership', () async {
    final repository = InMemoryAppRepository();

    expect(
      repository.exportPatientData(
        requesterUserId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('deleting account removes personal data but retains consent audit', () async {
    final repository = InMemoryAppRepository();
    final now = DateTime(2026, 2, 2, 7);

    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [sleepSampleFor(demoPatient.id, now, 7)],
    );
    await repository.acceptInvite(
      patientId: demoPatient.id,
      inviteCode: 'NID-1138',
    );

    final result = await repository.deletePatientData(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );

    expect(result.deletedJournalEntries, greaterThan(0));
    expect(result.deletedHealthSamples, greaterThan(0));
    expect(result.deletedDailySummaries, greaterThan(0));
    expect(result.revokedClinicianLinks, 1);
    expect(result.retainedConsentEvents, greaterThan(0));

    final journals = await repository.getJournalEntriesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    final summaries = await repository.getDailySummariesForPatient(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );
    final history = await repository.getConsentHistory(
      patientId: demoPatient.id,
    );
    final linkedPatients = await repository.getLinkedPatients(demoClinician.id);

    expect(journals, isEmpty);
    expect(summaries, isEmpty);
    // Consent history is retained as an audit record.
    expect(history, isNotEmpty);
    // Clinician can no longer see the deleted patient.
    expect(
      linkedPatients.map((patient) => patient.id),
      isNot(contains(demoPatient.id)),
    );
    // Deleted patient's sleep summary is no longer reachable by the clinician.
    expect(
      repository.getPatientSleepSummary(
        clinicianId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('delete enforces patient ownership', () async {
    final repository = InMemoryAppRepository();

    expect(
      repository.deletePatientData(
        requesterUserId: demoClinician.id,
        patientId: demoPatient.id,
      ),
      throwsA(isA<PrivacyException>()),
    );
  });

  test('deleted account can still be exported and shows no personal data', () async {
    final repository = InMemoryAppRepository();

    await repository.deletePatientData(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );

    final export = await repository.exportPatientData(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
    );

    expect(export.journalEntries, isEmpty);
    expect(export.healthSamples, isEmpty);
    expect(export.dailySummaries, isEmpty);
  });

  test('default retention policy purges nothing', () async {
    final repository = InMemoryAppRepository();

    final purged = await repository.applyRetention();

    expect(purged, 0);
  });

  test('retention policy purges records older than the window', () async {
    final repository = InMemoryAppRepository(
      retentionPolicy: const RetentionPolicy(
        healthSamples: Duration(days: 30),
      ),
    );
    final asOf = DateTime(2026, 3, 1, 8);
    final oldNight = asOf.subtract(const Duration(days: 400));

    await repository.saveImportedSleep(
      requesterUserId: demoPatient.id,
      patientId: demoPatient.id,
      samples: [sleepSampleFor(demoPatient.id, oldNight, 7)],
    );

    final purged = await repository.applyRetention(asOf: asOf);

    expect(purged, greaterThan(0));
  });
}
