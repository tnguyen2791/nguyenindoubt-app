import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/models/app_models.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/common_widgets.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the app to the patient dashboard with an injected repository so tests
/// can share persistence across a rebuild.
Future<NguyenInDoubtState> _bootPatient(
  WidgetTester tester, {
  NidRepository? repository,
}) async {
  final state = NguyenInDoubtState(
    repository: repository ?? InMemoryAppRepository(),
    healthDataProvider: MockHealthDataProvider(),
  );
  await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Alex Nguyen');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _openProfile(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline).first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Goals steppers adjust and persist the sleep goal + step target',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _bootPatient(tester);
      // Default goal is 8h 00m before any change.
      expect(state.preferences.sleepGoalMinutes, 480);

      await _openProfile(tester);
      final goalsRow = find.text('Goals & targets');
      await tester.tap(goalsRow);
      await tester.pumpAndSettle();

      // The Goals screen renders both steppers and the guidance-only note.
      expect(find.widgetWithText(AppBar, 'Goals & targets'), findsOneWidget);
      expect(find.text('nightly sleep goal'), findsOneWidget);
      expect(find.text('daily step target'), findsOneWidget);
      expect(
        find.text('Goals shape guidance only — they never change your scores.'),
        findsOneWidget,
      );
      expect(find.text('8h 00m'), findsOneWidget);

      // Increase sleep by one 15-minute step -> 8h 15m, persisted.
      await tester.tap(find.bySemanticsLabel('Increase nightly sleep goal'));
      await tester.pumpAndSettle();
      expect(state.preferences.sleepGoalMinutes, 495);
      expect(find.text('8h 15m'), findsOneWidget);

      // Decrease steps by one 500-step step -> 8,500, persisted.
      expect(state.preferences.stepTarget, 9000);
      await tester.tap(find.bySemanticsLabel('Decrease daily step target'));
      await tester.pumpAndSettle();
      expect(state.preferences.stepTarget, 8500);
      expect(find.text('8,500'), findsOneWidget);
    },
  );

  testWidgets('Goals hint leads with the patient\'s own recent sleep average', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _bootPatient(tester);

    await _openProfile(tester);
    await tester.tap(find.text('Goals & targets'));
    await tester.pumpAndSettle();

    // Before any import: honest empty hint, no fabricated average.
    expect(find.textContaining('Once you import a few nights'), findsOneWidget);

    // After a real import, the hint leads with the patient's OWN average and
    // stays non-shaming ("steady increases stick better than big jumps").
    await tester.pageBack();
    await tester.pumpAndSettle();
    await state.importMockSleep();
    await tester.pumpAndSettle();
    expect(state.recentSleepAverageHours, isNotNull);

    await tester.tap(find.text('Goals & targets'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your recent nights average'), findsOneWidget);
    expect(find.textContaining('stick better than big jumps'), findsOneWidget);
    // No streak/guilt language.
    expect(find.textContaining('streak'), findsNothing);
  });

  testWidgets('Notification toggles flip and persist stored preferences', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await _bootPatient(tester);
    // Defaults: morning reading on, goal milestones off.
    expect(state.preferences.morningReading, isTrue);
    expect(state.preferences.goalMilestones, isFalse);

    await _openProfile(tester);
    // The Notifications row sits in the Preferences group, below the fold.
    final notifRow = find.text('Notifications');
    await tester.scrollUntilVisible(
      notifRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(notifRow);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
    expect(find.text('Morning reading'), findsOneWidget);

    // Quiet hours + the never-guilt note sit below the fold — scroll to them.
    final settingsScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Do not disturb'),
      250,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Do not disturb'), findsOneWidget);
    // Quiet-hours default times render.
    expect(find.text('10:00p'), findsOneWidget);
    expect(find.text('7:00a'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('never streaks, never guilt'),
      250,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('never streaks, never guilt'), findsOneWidget);

    // Scroll back to the top and toggle morning reading off — the stored
    // preference flips + persists.
    await tester.scrollUntilVisible(
      find.text('Morning reading'),
      -250,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();
    final toggles = find.byType(NidToggle);
    await tester.tap(toggles.first);
    await tester.pumpAndSettle();
    expect(state.preferences.morningReading, isFalse);
  });

  testWidgets(
    'Notifications feed renders all three sections + opens a detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = await _bootPatient(tester);
      // A real import so the readiness-detail target has data.
      await state.importMockSleep();
      await tester.pumpAndSettle();

      await _openProfile(tester);
      // The header bell opens the display-only feed.
      await tester.tap(find.byIcon(Icons.notifications_none_outlined).first);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Your morning reading is ready'), findsOneWidget);

      // THIS WEEK + the calm closing copy sit below the fold — scroll to them.
      final feedScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('THIS WEEK'),
        250,
        scrollable: feedScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('THIS WEEK'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('only write when there'),
        250,
        scrollable: feedScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('only write when there'), findsOneWidget);

      // Scroll back to the top and open the morning-reading item — it opens
      // the Readiness detail (28).
      await tester.scrollUntilVisible(
        find.text('Your morning reading is ready'),
        -250,
        scrollable: feedScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your morning reading is ready'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Readiness'), findsOneWidget);
    },
  );

  testWidgets('preferences round-trip across an app recreation (persisted)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    // First run: change the sleep goal, then let it persist to shared prefs.
    final firstRepo = InMemoryAppRepository(preferences: prefs);
    final firstState = await _bootPatient(tester, repository: firstRepo);
    await firstState.updatePreferences(
      firstState.preferences.copyWith(sleepGoalMinutes: 450, stepTarget: 10000),
    );
    await tester.pumpAndSettle();
    final patientId = firstState.currentUser.id;

    // Second run: a fresh repository over the SAME shared prefs restores it.
    final secondRepo = InMemoryAppRepository(preferences: prefs);
    final restored = await secondRepo.getUserPreferences(
      requesterUserId: patientId,
      patientId: patientId,
    );
    expect(restored.sleepGoalMinutes, 450);
    expect(restored.stepTarget, 10000);
  });

  test(
    'repository rejects cross-patient preference access (privacy)',
    () async {
      final repo = InMemoryAppRepository();
      const other = 'someone-else';
      expect(
        () => repo.getUserPreferences(requesterUserId: 'me', patientId: other),
        throwsA(isA<PrivacyException>()),
      );
      expect(
        () => repo.saveUserPreferences(
          requesterUserId: 'me',
          patientId: other,
          preferences: const UserPreferences(),
        ),
        throwsA(isA<PrivacyException>()),
      );
    },
  );
}
