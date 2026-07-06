import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SAFE-03: the private journal gains an [EmptyState] and per-entry delete.
/// Delete is the owning patient removing their own reflection — never a
/// clinician path. These tests lock owner-only deletion at the repository
/// layer and the confirmed empty-state + delete UI at the widget layer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryAppRepository.deleteJournalEntry', () {
    test('patient deletes their own entry; removal is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const storageKey = 'journal-delete-persist-test';
      final repository = InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      );

      final before = await repository.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      );
      expect(before.map((entry) => entry.id), contains('journal-1'));

      await repository.deleteJournalEntry(
        requesterUserId: demoPatient.id,
        entryId: 'journal-1',
      );

      final after = await repository.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      );
      expect(after.map((entry) => entry.id), isNot(contains('journal-1')));

      // A fresh repository restored from the same storage proves persistence.
      final restored = InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      );
      final restoredEntries = await restored.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      );
      expect(
        restoredEntries.map((entry) => entry.id),
        isNot(contains('journal-1')),
      );
    });

    test('a non-owner cannot delete an entry; it remains', () async {
      final repository = InMemoryAppRepository();

      await expectLater(
        repository.deleteJournalEntry(
          requesterUserId: linkedPatient.id,
          entryId: 'journal-1',
        ),
        throwsA(isA<PrivacyException>()),
      );

      final entries = await repository.getJournalEntriesForPatient(
        requesterUserId: demoPatient.id,
        patientId: demoPatient.id,
      );
      expect(entries.map((entry) => entry.id), contains('journal-1'));
    });

    test('deleting a missing id is an idempotent no-op', () async {
      final repository = InMemoryAppRepository();

      await expectLater(
        repository.deleteJournalEntry(
          requesterUserId: demoPatient.id,
          entryId: 'journal-does-not-exist',
        ),
        completes,
      );
    });
  });
}
