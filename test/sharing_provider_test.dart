import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

/// Phase 18 — Sharing flow + Provider portal.
///
/// THE PRIVACY CONTRACT IS PARAMOUNT. These tests prove:
///   * the provider bundle carries NO journal and NO readiness content — the
///     shared surface is sleep-summaries-only, enforced in logic not just copy;
///   * the user-side sharing flow (request → choose scopes → send → status →
///     pause) works on the demo repo and never offers journal as a scope;
///   * the provider portal renders Requests / Worth a look / roster / shared
///     readings / settings, keeps the verbatim visibility disclosure, and never
///     leaks a journal scope into a shares label or a "worth a look" citation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('privacy contract — shared bundle', () {
    test(
      'the provider sleep bundle carries no journal and no readiness',
      () async {
        final state = NguyenInDoubtState(
          repository: InMemoryAppRepository(),
          healthDataProvider: MockHealthDataProvider(),
        );

        // Enter the provider surface — clinician mode auto-selects the first
        // accepted patient, so a real shared bundle is loaded.
        await state.continueAsClinician();

        final bundle = state.selectedPatientBundle;
        expect(bundle, isNotNull, reason: 'A shared bundle should load.');

        // The bundle is structurally sleep-only: every sample is a sleep sample,
        // so no readiness signal (HRV, temperature, resting HR, etc.) rides
        // through the provider surface.
        for (final sample in bundle!.samples) {
          expect(
            sample.metricType,
            MetricType.sleep,
            reason:
                'The provider bundle must carry sleep samples only — no '
                'readiness signals (HRV, temperature, resting HR, etc.).',
          );
        }

        // PatientSleepBundle exposes patient + summaries + samples only. There is
        // no journal or readiness accessor — the type itself withholds them.
        // Assert the summaries are sleep summaries (sleep duration present).
        expect(bundle.summaries, isNotEmpty);
        for (final summary in bundle.summaries) {
          expect(summary.sleepDurationHours, greaterThan(0));
        }

        // The clinician state never loads journal entries or readiness.
        expect(state.journalEntries, isEmpty);
        expect(state.readiness, isNull);
        expect(state.readinessHistory, isEmpty);
      },
    );

    test('a clinician cannot read the patient journal directly', () async {
      final repository = InMemoryAppRepository();

      // A clinician requesting the patient's journal is denied by the
      // repository's ownership guard — the contract is enforced in logic.
      expect(
        () => repository.getJournalEntriesForPatient(
          requesterUserId: 'clinician-demo',
          patientId: 'patient-linked',
        ),
        throwsA(isA<PrivacyException>()),
      );
    });
  });

  group('user-side sharing flow', () {
    testWidgets('request → choose scopes → send → status → pause', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1600);
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

      // Open the sharing flow from the Profile "Sharing" row.
      await tester.tap(find.byIcon(Icons.person_outline).first);
      await tester.pumpAndSettle();
      final shareRow = find.text('Share with your provider');
      await tester.scrollUntilVisible(shareRow, 200);
      await tester.pumpAndSettle();
      await tester.tap(shareRow);
      await tester.pumpAndSettle();

      // Request step (design 82): the flow leads with the choose-provider copy.
      expect(find.text('Choose who to share with'), findsOneWidget);

      // Choose scopes (design 84): sleep-only offered scopes are present, and
      // journal is explicitly NOT offered — it is never a flippable toggle.
      // The kicker renders uppercase via SectionKicker.
      expect(find.text("THEY'LL SEE"), findsOneWidget);
      expect(find.text('Scores & trends'), findsOneWidget);
      expect(find.text('Sleep detail'), findsOneWidget);
      expect(find.text('Journal tags'), findsOneWidget);
      expect(find.text('Journal notes'), findsOneWidget);
      expect(find.text('Not offered', skipOffstage: false), findsWidgets);
      // No Switch/toggle exists for the journal scopes — the flow offers no
      // control that could turn journal sharing on.
      expect(find.byType(Switch), findsNothing);

      // The verbatim visibility disclosure is present on the choose step.
      expect(
        find.textContaining('Hidden: journal entries, drafts'),
        findsOneWidget,
      );

      // Find the provider by the seeded pending invite code.
      await tester.enterText(find.byType(TextField).first, 'NID-1138');
      await tester.tap(find.text('Find provider'));
      await tester.pumpAndSettle();
      expect(find.text('Dr. Nguyen'), findsWidgets);

      // Send the request (demo activates sharing immediately).
      final send = find.widgetWithText(FilledButton, 'Send request');
      await tester.scrollUntilVisible(
        send,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(send);
      await tester.pumpAndSettle();

      // Confirmation step (design 86) → sharing is on.
      expect(state.currentUser.consentStatus, ConsentStatus.granted);
      expect(find.text('Sharing is on'), findsOneWidget);

      // Review sharing settings → manage/pause (design 78 / 102).
      await tester.tap(find.text('Review sharing settings'));
      await tester.pumpAndSettle();
      expect(find.text('WHAT YOUR PROVIDER CAN SEE'), findsOneWidget);
      expect(find.text('Pause sharing'), findsOneWidget);

      // Pause hides everything — revokes consent, quietly.
      await tester.tap(find.text('Pause sharing'));
      await tester.pumpAndSettle();
      expect(state.currentUser.consentStatus, ConsentStatus.revoked);
    });

    testWidgets('the sharing flow never offers journal as a scope', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1600);
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

      await tester.tap(find.byIcon(Icons.person_outline).first);
      await tester.pumpAndSettle();
      final requestRow = find.text('Request to share');
      await tester.scrollUntilVisible(requestRow, 200);
      await tester.pumpAndSettle();
      await tester.tap(requestRow);
      await tester.pumpAndSettle();

      // Both journal rows read "Not offered" — the contract made visible.
      expect(find.text('Not offered', skipOffstage: false), findsWidgets);
      expect(
        find.textContaining('your tags stay private', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('your notes stay private', skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('provider portal', () {
    testWidgets('renders requests, worth-a-look, roster, and shared readings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
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
      await tester.tap(find.text("I'm a clinician"));
      await tester.pumpAndSettle();

      // The three provider sections render as `.k` kickers.
      Finder kicker(String text) => find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      );
      expect(kicker('REQUESTS · PEOPLE WHO OPTED IN'), findsOneWidget);
      expect(kicker('WORTH A LOOK · NOT ALERTS, JUST PATTERNS'), findsWidgets);
      expect(kicker('EVERYONE'), findsOneWidget);

      // A pending invite surfaces as a Request with Accept/Decline.
      expect(find.text('Accept'), findsWidgets);
      expect(find.text('Decline'), findsWidgets);

      // The shared-readings detail is person-first and sleep-only.
      expect(find.textContaining("'s readings"), findsWidgets);

      // The roster carries a sleep-only shares descriptor — never journal.
      expect(find.text('shares: scores · sleep'), findsOneWidget);
      // No visible text on the provider surface names a "journal" scope
      // (contract). Journal appears only inside the withheld-disclosure copy
      // ("Hidden: journal entries…"), never as a shareable scope label.
      expect(find.text('scores · sleep · journal'), findsNothing);

      // The verbatim visibility disclosure stays on the provider surface.
      final disclosure = find.textContaining(
        'Visible: sleep samples, daily summaries, trend flags.',
      );
      await tester.scrollUntilVisible(disclosure, 200);
      await tester.pumpAndSettle();
      expect(disclosure, findsOneWidget);
    });

    testWidgets('provider settings render sleep-only, no journal scope', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
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
      await tester.tap(find.text("I'm a clinician"));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      Finder kicker(String text) => find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      );
      expect(find.text('Provider settings'), findsOneWidget);
      expect(kicker('SHARING REQUESTS'), findsOneWidget);
      expect(kicker('NOTIFICATIONS'), findsOneWidget);

      // The "good to know" note keeps the sleep-only promise and names the
      // journal as withheld.
      expect(find.textContaining('Sleep summaries only'), findsOneWidget);
      // A settings request descriptor is sleep-only — never "scores, sleep &
      // journal" (the design's copy, stripped per contract).
      expect(find.textContaining('scores & sleep'), findsWidgets);
    });
  });
}

/// Drives the patient onboarding first-run to the dashboard.
Future<void> _completePatientOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  final continueButton = find.widgetWithText(FilledButton, 'Continue');
  await tester.ensureVisible(continueButton);
  await tester.pumpAndSettle();
  await tester.tap(continueButton);
  await tester.pumpAndSettle();
}
