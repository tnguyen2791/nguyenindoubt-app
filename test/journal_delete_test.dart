import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
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

  group('JournalScreen empty state + per-entry delete', () {
    testWidgets('empty journal shows the private EmptyState', (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = NguyenInDoubtState(
        repository: InMemoryAppRepository(),
        healthDataProvider: MockHealthDataProvider(),
      );

      await tester.pumpWidget(
        NguyenInDoubtApp(state: state, showSplash: false),
      );
      await tester.pumpAndSettle();
      await _completePatientOnboarding(tester);

      // Remove the single seeded entry so the journal is empty.
      await state.deleteJournalEntry('journal-1');
      await _openJournal(tester);

      expect(state.journalEntries, isEmpty);
      expect(find.text('Your journal stays private'), findsOneWidget);
      expect(
        find.text('Start your first entry — only you can read it.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('confirming delete removes the entry; cancel keeps it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = NguyenInDoubtState(
        repository: InMemoryAppRepository(),
        healthDataProvider: MockHealthDataProvider(),
      );

      await tester.pumpWidget(
        NguyenInDoubtApp(state: state, showSplash: false),
      );
      await tester.pumpAndSettle();
      await _completePatientOnboarding(tester);
      await _openJournal(tester);

      expect(find.text('The part I keep avoiding'), findsOneWidget);
      final deleteControl = find.byIcon(Icons.delete_outline);
      expect(deleteControl, findsOneWidget);

      // Cancel keeps the entry.
      await tester.tap(deleteControl);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('permanently removed from this device'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(state.journalEntries, isNotEmpty);
      expect(find.text('The part I keep avoiding'), findsOneWidget);

      // Confirming removes it.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete entry'));
      await tester.pumpAndSettle();

      expect(state.journalEntries, isEmpty);
      expect(find.text('The part I keep avoiding'), findsNothing);
      expect(find.text('Your journal stays private'), findsOneWidget);
    });
  });
}

Future<void> _openJournal(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.edit_note_outlined).last);
  await tester.pumpAndSettle();
}

/// Local replica of the onboarding flow — `test/widget_test.dart`'s helper is
/// file-private and cannot be imported (harness note in 09-03-PLAN).
Future<void> _completePatientOnboarding(
  WidgetTester tester, {
  String displayName = 'Alex Nguyen',
}) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  expect(find.text('Patient onboarding'), findsOneWidget);
  await tester.enterText(find.byType(TextField), displayName);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}
