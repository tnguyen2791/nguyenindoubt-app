import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('patient can sign up and import mock sleep data', (tester) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Patient sign up'), findsOneWidget);
    expect(find.text('Clinician demo override'), findsOneWidget);

    await _completePatientOnboarding(tester, displayName: 'Taylor Nguyen');

    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('No sleep samples yet'), findsOneWidget);
    expect(state.currentUser.displayName, 'Taylor Nguyen');

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(state.summaries, isNotEmpty);
    expect(find.text('No sleep samples yet'), findsNothing);
  });

  testWidgets('patient can reset local demo data', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(
        preferences: preferences,
        storageKey: 'widget-reset-test',
      ),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pumpAndSettle();

    await _completePatientOnboarding(tester);

    expect(
      find.text(
        'Demo data is stored on this device. It does not sync across desktop, phone, or the GitHub Pages demo.',
      ),
      findsOneWidget,
    );

    await state.importMockSleep();
    await state.acceptClinicInvite();
    await state.addJournalEntry(
      title: 'Reset title',
      body: 'Reset body',
      moodTag: 'steady',
    );
    await tester.pumpAndSettle();
    expect(state.summaries, isNotEmpty);
    expect(state.currentUser.consentStatus, ConsentStatus.granted);
    expect(
      state.journalEntries.map((entry) => entry.title),
      contains('Reset title'),
    );

    await tester.tap(find.text('Reset demo data'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'clear journal entries, imported sleep samples, and consent state stored on this device',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reset demo data'));
    await tester.pumpAndSettle();

    expect(state.sessionStage, SessionStage.signedOut);
    expect(state.currentUser.id, demoPatient.id);
    expect(state.healthPermissionGranted, isFalse);
    expect(state.summaries, isEmpty);
    expect(state.currentUser.consentStatus, ConsentStatus.notAsked);
    expect(find.text('Patient sign up'), findsOneWidget);
    expect(find.text('No sleep samples yet'), findsNothing);
    expect(find.text('Reset title'), findsNothing);
  });

  testWidgets('safety actions provide explicit urgent support fallback', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pumpAndSettle();

    await _completePatientOnboarding(tester);
    await tester.tap(find.text('Safety'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call or text 988'));
    await tester.pumpAndSettle();
    expect(find.text('Call or text 988'), findsWidgets);
    expect(find.textContaining('Call or text 988 now.'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergency care'));
    await tester.pumpAndSettle();
    expect(find.textContaining('call 911'), findsOneWidget);
  });

  testWidgets('clinician dashboard keeps sleep-only privacy copy', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clinician demo override'));
    await tester.pumpAndSettle();

    expect(state.journalEntries, isEmpty);
    expect(
      find.text('Accepted invites only. Sleep summaries, never journals.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Visible: sleep samples, daily summaries, trend flags. Hidden: journal entries, drafts, private reflections.',
      ),
      findsOneWidget,
    );
    expect(find.text('A steadier morning'), findsNothing);
  });

  testWidgets('phase one surfaces render at phone and desktop widths', (
    tester,
  ) async {
    await _expectSurfacesRenderAtSize(tester, const Size(390, 844));
    await _expectSurfacesRenderAtSize(tester, const Size(1180, 900));
  });

  testWidgets('local patient session restores after app recreation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    const storageKey = 'widget-session-restore-test';
    final firstState = NguyenInDoubtState(
      repository: InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      ),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: firstState));
    await tester.pumpAndSettle();
    await _completePatientOnboarding(tester, displayName: 'Taylor Nguyen');

    final restoredState = NguyenInDoubtState(
      repository: InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      ),
      healthDataProvider: MockHealthDataProvider(),
    );
    await tester.pumpWidget(NguyenInDoubtApp(state: restoredState));
    await tester.pumpAndSettle();

    expect(restoredState.sessionStage, SessionStage.patient);
    expect(restoredState.currentUser.displayName, 'Taylor Nguyen');
    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('Patient sign up'), findsNothing);
  });

  testWidgets(
    'local clinician demo override session restores sleep-only view',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const storageKey = 'widget-clinician-session-restore-test';
      final firstState = NguyenInDoubtState(
        repository: InMemoryAppRepository(
          preferences: preferences,
          storageKey: storageKey,
        ),
        healthDataProvider: MockHealthDataProvider(),
      );

      await tester.pumpWidget(NguyenInDoubtApp(state: firstState));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clinician demo override'));
      await tester.pumpAndSettle();

      final restoredState = NguyenInDoubtState(
        repository: InMemoryAppRepository(
          preferences: preferences,
          storageKey: storageKey,
        ),
        healthDataProvider: MockHealthDataProvider(),
      );
      await tester.pumpWidget(NguyenInDoubtApp(state: restoredState));
      await tester.pumpAndSettle();

      expect(restoredState.sessionStage, SessionStage.clinician);
      expect(restoredState.journalEntries, isEmpty);
      expect(
        find.text('Accepted invites only. Sleep summaries, never journals.'),
        findsOneWidget,
      );
      expect(find.text('A steadier morning'), findsNothing);
    },
  );
}

Future<void> _expectSurfacesRenderAtSize(WidgetTester tester, Size size) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final state = NguyenInDoubtState(
    repository: InMemoryAppRepository(),
    healthDataProvider: MockHealthDataProvider(),
  );

  await tester.pumpWidget(NguyenInDoubtApp(state: state));
  await tester.pumpAndSettle();
  await _completePatientOnboarding(tester);
  expect(tester.takeException(), isNull);

  for (final icon in [
    Icons.edit_note_outlined,
    Icons.menu_book_outlined,
    Icons.health_and_safety_outlined,
  ]) {
    await tester.tap(find.byIcon(icon).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  await state.signOut();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Clinician demo override'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(
    find.text('Accepted invites only. Sleep summaries, never journals.'),
    findsOneWidget,
  );
}

Future<void> _completePatientOnboarding(
  WidgetTester tester, {
  String displayName = 'Alex Nguyen',
}) async {
  await tester.tap(find.text('Patient sign up'));
  await tester.pumpAndSettle();
  expect(find.text('Patient onboarding'), findsOneWidget);
  await tester.enterText(find.byType(TextField), displayName);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}
