import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/data/seed_data.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/data_displays.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('patient can sign up and import mock sleep data', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text("I'm a clinician"), findsOneWidget);

    await _completePatientOnboarding(tester, displayName: 'Taylor Nguyen');

    // The BrandHeader "Morning check-in" banner is gone; the guided
    // first-run layer leads the dashboard until sleep data is imported.
    expect(find.text('Morning check-in'), findsNothing);
    expect(find.text("Start with last night's sleep"), findsOneWidget);
    expect(find.textContaining('never your journal'), findsOneWidget);
    expect(state.currentUser.displayName, 'Taylor Nguyen');

    final importButton = find.widgetWithText(FilledButton, 'Import sleep');
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(state.summaries, isNotEmpty);
    expect(find.text('sleep access ready'), findsOneWidget);
    expect(find.text("Start with last night's sleep"), findsNothing);

    // Phase 14 hierarchy: the Today hero is now the REAL multi-signal
    // readiness ring (the retired sleep proxy is gone from the hero), still
    // non-diagnostic, and the greeting block leads the with-data dashboard.
    expect(find.text('not a diagnosis'), findsOneWidget);
    expect(find.text('READINESS'), findsOneWidget);
    // The retired 'SLEEP SCORE' hero label no longer heads the Today screen.
    expect(find.text('SLEEP SCORE'), findsNothing);
    expect(find.byType(ScoreRing), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('QUALITY PROXY'), findsNothing);
    expect(find.text('CLINICIAN LINK'), findsNothing);
    // Readiness computed from the deterministic mock — a real score is shown.
    expect(state.readiness, isNotNull);
    expect(find.text('${state.readiness!.readinessScore}'), findsOneWidget);
  });

  testWidgets(
    'dashboard hierarchy shows score hero, honest trend, and one insight '
    'line at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
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

      await state.importMockSleep();
      await tester.pumpAndSettle();

      // No overflow at phone width, and the readiness hero leads (P14).
      expect(tester.takeException(), isNull);
      expect(find.byType(ScoreRing), findsOneWidget);
      expect(find.text('not a diagnosis'), findsOneWidget);
      expect(find.text('READINESS'), findsOneWidget);

      // Exactly one gentle observational insight line (the greeting
      // sub-line): the fixed mock durations put last night over baseline.
      expect(find.textContaining('vs your recent average'), findsOneWidget);

      // The dashboard ListView is the first Scrollable; the consent card's
      // invite TextField contributes another once it is built.
      final dashboardScrollable = find.byType(Scrollable).first;

      // The honest trend scale: ramp legend ends plus the 8h hairline label.
      await tester.scrollUntilVisible(
        find.text('5h short'),
        200,
        scrollable: dashboardScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('5h short'), findsOneWidget);
      expect(find.text('8h+ optimal'), findsOneWidget);
      expect(find.text('8h'), findsOneWidget);

      // The consent card is demoted to last but still reachable.
      await tester.scrollUntilVisible(
        find.text('Sleep sharing consent'),
        200,
        scrollable: dashboardScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sleep sharing consent'), findsOneWidget);
    },
  );

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

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await _completePatientOnboarding(tester);

    expect(
      find.text(
        'Demo mode: data stays on this device. It does not sync across browsers, phones, or the GitHub Pages demo, and it is not production storage.',
      ),
      findsOneWidget,
    );

    await state.importMockSleep();
    await state.validateInviteCode('NID-1138');
    await state.acceptValidatedInvite();
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
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text("Start with last night's sleep"), findsNothing);
    expect(find.text('Reset title'), findsNothing);
  });

  testWidgets('public demo discloses local-only data mode', (tester) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Account-backed production storage is not enabled'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Alex Nguyen');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Demo mode: data stays on this device. It does not sync across browsers, phones, or the GitHub Pages demo, and it is not production storage.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('onboarding guards the name field and offers a skip fallback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // The three expectation bullets are on the single onboarding screen.
    expect(find.text('Sleep, privately imported'), findsOneWidget);
    expect(find.text('A journal only you can read'), findsOneWidget);
    expect(find.text('Guides, with room for doubt'), findsOneWidget);

    FilledButton continueButton() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Continue'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );

    // Empty and whitespace-only names cannot submit.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(continueButton().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(continueButton().onPressed, isNull);

    // A real name enables Continue.
    await tester.enterText(find.byType(TextField), 'Taylor Nguyen');
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    // Explicit skip proceeds with the demo fallback name.
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    final skip = find.text('Skip for now');
    await tester.ensureVisible(skip);
    await tester.pumpAndSettle();
    await tester.tap(skip);
    await tester.pumpAndSettle();

    // Banner removed — the guided first-run layer confirms the patient
    // dashboard was reached via the skip fallback.
    expect(find.text('Morning check-in'), findsNothing);
    expect(find.text("Start with last night's sleep"), findsOneWidget);
    expect(state.currentUser.displayName, demoPatient.displayName);
  });

  testWidgets('safety actions provide explicit urgent support fallback', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await _completePatientOnboarding(tester);
    // Safety no longer has its own tab — it stays reachable from the Profile
    // tab's Support group (standing project rule: Safety must remain reachable).
    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    final safetyRow = find.text('Safety and limits');
    await tester.scrollUntilVisible(safetyRow, 200);
    await tester.pumpAndSettle();
    await tester.tap(safetyRow);
    await tester.pumpAndSettle();

    // Crisis controls are honestly labeled for direct action (SAFE-01). We do
    // NOT tap them here — the default UrlCrisisLauncher would hit an unmocked
    // platform channel; URI-launch behavior is covered by safety_screen_test.
    expect(find.text('Call 988'), findsOneWidget);
    expect(find.text('Text 988'), findsOneWidget);
    expect(find.text('Call 911'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    final disclosure = find.text(
      'NguyenInDoubt does not provide diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging in this MVP.',
    );
    await tester.scrollUntilVisible(disclosure, 200);
    await tester.pumpAndSettle();
    expect(disclosure, findsOneWidget);
  });

  testWidgets('bottom nav exposes the Today/Trends/[+]/Explore/Profile IA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await _completePatientOnboarding(tester);

    // All five design slots are present: four labelled tabs plus the center
    // canopy [+] Add action.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // The old IA labels are gone from the tab bar.
    expect(find.text('Sleep'), findsNothing);
    expect(find.text('Journal'), findsNothing);
    expect(find.text('Guides'), findsNothing);

    // Trends is a calm shell — a coming-soon empty state, no fake data.
    await tester.tap(find.byIcon(Icons.bar_chart_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Your sleep trend is coming soon'), findsOneWidget);

    // Explore re-homes the resources content under the Explore title.
    await tester.tap(find.byIcon(Icons.explore_outlined).first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('learn what your body is telling you'),
      findsOneWidget,
    );

    // Profile shows the identity header and the settings groups (the section
    // kickers render uppercase, matching the design's `.k` idiom).
    await tester.tap(find.byIcon(Icons.person_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Personal info'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('SHARING'), findsOneWidget);

    final profileScrollable = find.byType(Scrollable).first;
    // PREFERENCES + SUPPORT groups sit below the fold at phone width.
    await tester.scrollUntilVisible(
      find.text('SUPPORT'),
      200,
      scrollable: profileScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('SUPPORT'), findsOneWidget);

    // Journal stays reachable from Profile (no tab of its own now).
    final journalRow = find.text('Journal');
    await tester.ensureVisible(journalRow);
    await tester.pumpAndSettle();
    await tester.tap(journalRow);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Journal'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Sign out sits at the foot of the Profile list.
    final signOut = find.text('Sign out');
    await tester.scrollUntilVisible(signOut, 200);
    await tester.pumpAndSettle();
    expect(signOut, findsOneWidget);

    // The center [+] opens the Add-sheet stub with the wired Import action.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Add to today'), findsOneWidget);
    expect(find.text('Import sleep'), findsOneWidget);
  });

  testWidgets('patient can validate accept and revoke invite sharing', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await _completePatientOnboarding(tester);

    // The dashboard ListView is the first Scrollable; the consent card's
    // invite TextField adds a second, so target the dashboard explicitly.
    final dashboardScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Sleep sharing consent'),
      200,
      scrollable: dashboardScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sleep sharing consent'), findsOneWidget);
    expect(find.text('No consent events yet.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'bad-code');
    await tester.tap(find.text('Validate invite'));
    await tester.pumpAndSettle();
    expect(find.text('Invite not available'), findsOneWidget);
    expect(state.currentUser.consentStatus, ConsentStatus.notAsked);

    await tester.enterText(find.byType(TextField).last, 'NID-1138');
    await tester.tap(find.text('Validate invite'));
    await tester.pumpAndSettle();
    expect(find.text('Invite preview'), findsOneWidget);
    expect(find.text('Clinician: Dr. Nguyen'), findsOneWidget);
    expect(
      find.textContaining('Hidden: journal entries, drafts'),
      findsOneWidget,
    );
    expect(state.currentUser.consentStatus, ConsentStatus.notAsked);

    await tester.tap(find.text('Accept sharing'));
    await tester.pumpAndSettle();
    expect(state.currentUser.consentStatus, ConsentStatus.granted);
    expect(find.text('sharing active'), findsOneWidget);
    expect(find.textContaining('Accepted NID-1138'), findsOneWidget);

    await tester.tap(find.text('Revoke sharing'));
    await tester.pumpAndSettle();
    expect(state.currentUser.consentStatus, ConsentStatus.revoked);
    expect(find.text('sharing revoked'), findsOneWidget);
    expect(find.textContaining('Revoked NID-1138'), findsOneWidget);
  });

  testWidgets('clinician dashboard keeps sleep-only privacy copy', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I'm a clinician"));
    await tester.pumpAndSettle();

    expect(state.journalEntries, isEmpty);
    expect(
      find.text('Accepted invites only. Sleep summaries, never journals.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining(
        'Visible: sleep samples, daily summaries, trend flags.',
      ),
      200,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Visible: sleep samples, daily summaries, trend flags.',
      ),
      findsOneWidget,
    );
    expect(find.text('A steadier morning'), findsNothing);
  });

  testWidgets('clinician dashboard shows invite lifecycle statuses', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm a clinician"));
    await tester.pumpAndSettle();

    // "Invite status" now renders through the `.k` section-label idiom
    // (uppercase canopy kicker), so it is a RichText span, not plain Text.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('INVITE STATUS'),
      ),
      findsOneWidget,
    );
    expect(find.text('NID-8274 - accepted'), findsOneWidget);
    expect(find.text('NID-1138 - pending'), findsOneWidget);
    expect(find.text('NID-4455 - expired'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('expired'), findsOneWidget);
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

    await tester.pumpWidget(
      NguyenInDoubtApp(state: firstState, showSplash: false),
    );
    await tester.pumpAndSettle();
    await _completePatientOnboarding(tester, displayName: 'Taylor Nguyen');

    final restoredState = NguyenInDoubtState(
      repository: InMemoryAppRepository(
        preferences: preferences,
        storageKey: storageKey,
      ),
      healthDataProvider: MockHealthDataProvider(),
    );
    await tester.pumpWidget(
      NguyenInDoubtApp(state: restoredState, showSplash: false),
    );
    await tester.pumpAndSettle();

    expect(restoredState.sessionStage, SessionStage.patient);
    expect(restoredState.currentUser.displayName, 'Taylor Nguyen');
    // Banner removed — restored patient session lands on the first-run layer.
    expect(find.text('Morning check-in'), findsNothing);
    expect(find.text("Start with last night's sleep"), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
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

      await tester.pumpWidget(
        NguyenInDoubtApp(state: firstState, showSplash: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text("I'm a clinician"));
      await tester.pumpAndSettle();

      final restoredState = NguyenInDoubtState(
        repository: InMemoryAppRepository(
          preferences: preferences,
          storageKey: storageKey,
        ),
        healthDataProvider: MockHealthDataProvider(),
      );
      await tester.pumpWidget(
        NguyenInDoubtApp(state: restoredState, showSplash: false),
      );
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

  await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
  await tester.pumpAndSettle();
  await _completePatientOnboarding(tester);
  expect(tester.takeException(), isNull);

  // Walk the new IA: Trends, Explore, Profile all render without overflow at
  // both widths. Today (index 0) is already on screen from onboarding.
  await tester.tap(find.byIcon(Icons.bar_chart_outlined).first);
  await tester.pumpAndSettle();
  expect(find.text('Trends'), findsWidgets);
  expect(tester.takeException(), isNull);

  await tester.tap(find.byIcon(Icons.explore_outlined).first);
  await tester.pumpAndSettle();
  expect(find.text('Explore'), findsWidgets);
  expect(tester.takeException(), isNull);

  await tester.tap(find.byIcon(Icons.person_outline).first);
  await tester.pumpAndSettle();
  expect(find.text('Profile'), findsWidgets);
  final signOut = find.text('Sign out');
  await tester.scrollUntilVisible(signOut, 200);
  await tester.pumpAndSettle();
  expect(signOut, findsOneWidget);
  expect(tester.takeException(), isNull);

  await state.signOut();
  await tester.pumpAndSettle();
  final clinicianLink = find.text("I'm a clinician");
  await tester.ensureVisible(clinicianLink);
  await tester.pumpAndSettle();
  await tester.tap(clinicianLink);
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
  final getStarted = find.text('Get started');
  await tester.ensureVisible(getStarted);
  await tester.pumpAndSettle();
  await tester.tap(getStarted);
  await tester.pumpAndSettle();
  expect(find.text('Patient onboarding'), findsOneWidget);
  await tester.enterText(find.byType(TextField), displayName);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}
