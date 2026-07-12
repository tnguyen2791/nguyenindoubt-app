import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/explore_screen.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

NguyenInDoubtState _state() => NguyenInDoubtState(
  repository: InMemoryAppRepository(),
  healthDataProvider: MockHealthDataProvider(),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Explore tab (70)', () {
    testWidgets('renders the featured practice, markers strip, article rows, '
        'and the disclaimer + 988 line', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      // Title + intro.
      expect(find.text('Explore'), findsOneWidget);
      expect(
        find.textContaining('learn what your body is telling you'),
        findsOneWidget,
      );

      // Featured practice (box breathing) with a Begin CTA.
      expect(find.text('Box breathing'), findsOneWidget);
      expect(find.text('Practice · 4 min'), findsOneWidget);
      expect(find.text('Begin'), findsOneWidget);

      // Markers-explained strip: all four wearable signals + their abbrs.
      expect(find.text('Your markers, explained'.toUpperCase()), findsWidgets);
      expect(find.text('Heart rate variability'), findsOneWidget);
      expect(find.text('Resting heart rate'), findsOneWidget);
      expect(find.text('Temperature deviation'), findsOneWidget);
      expect(find.text('Readiness'), findsOneWidget);
      expect(find.text('HRV'), findsOneWidget);
      expect(find.text('RHR'), findsOneWidget);

      // Mind & mood article rows.
      expect(find.text('Mind & mood'.toUpperCase()), findsWidgets);
      expect(find.text('Stress leaves a signature'), findsOneWidget);

      // Disclaimer + crisis 988 line (below the fold — scroll it in).
      final disclaimer = find.textContaining('Educational, not medical advice');
      await tester.scrollUntilVisible(disclaimer, 200);
      await tester.pumpAndSettle();
      expect(disclaimer, findsOneWidget);
      expect(find.text('Low days are data, not verdicts'), findsOneWidget);
      expect(find.textContaining('988'), findsWidgets);
    });

    testWidgets('a marker InfoTip opens a reassuring, non-warning explainer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      // Tap the first "i" affordance (HRV row).
      await tester.tap(find.text('i').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('timing differences between heartbeats'),
        findsOneWidget,
      );
      // Educational voice — never a warning / exclamation.
      expect(find.textContaining('!'), findsNothing);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('the 988 disclaimer line routes to the reachable Safety '
        'surface', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      final line = find.textContaining('If things feel heavy');
      await tester.scrollUntilVisible(line, 200);
      await tester.pumpAndSettle();
      await tester.tap(line);
      await tester.pumpAndSettle();

      // Lands on the existing Safety surface with its crisis controls intact.
      expect(find.text('Call 988'), findsOneWidget);
      expect(find.text('Call 911'), findsOneWidget);
    });
  });

  group('Article reader (72)', () {
    testWidgets('opens from an Explore row with kicker, lede, callout, and '
        'the try-it-now practice', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stress leaves a signature'));
      await tester.pumpAndSettle();

      // Kicker (section · kind · time) + lede.
      expect(find.text('Mind & mood · Read · 3 min'), findsOneWidget);
      expect(
        find.textContaining('your body has already filed a report'),
        findsOneWidget,
      );

      // "Worth knowing" callout + "Try it now" practice card (scroll them in).
      final callout = find.text('Worth knowing'.toUpperCase());
      await tester.scrollUntilVisible(callout, 200);
      await tester.pumpAndSettle();
      expect(callout, findsOneWidget);
      expect(find.text('Try it now'), findsOneWidget);
      expect(find.text('Begin practice'), findsOneWidget);

      // Read-next rows chain onward.
      final readNext = find.text('Read next'.toUpperCase());
      await tester.scrollUntilVisible(readNext, 200);
      await tester.pumpAndSettle();
      expect(readNext, findsOneWidget);
      expect(find.text('Anxiety and sleep: breaking the loop'), findsOneWidget);

      // Closing disclaimer + 988.
      final disclaimer = find.textContaining('Educational, not medical advice');
      await tester.scrollUntilVisible(disclaimer, 200);
      await tester.pumpAndSettle();
      expect(disclaimer, findsOneWidget);
    });

    testWidgets('the featured Begin button opens the box-breathing reader', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // Box-breathing reader: a Practice kicker and an inline HRV InfoTip in
      // the body.
      expect(find.text('Practice · Practice · 4 min'), findsOneWidget);
      expect(find.text('How it works'), findsOneWidget);
      expect(find.text('i'), findsWidgets);
    });

    testWidgets('read-next chains to the next article', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExploreScreen(state: _state())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stress leaves a signature'));
      await tester.pumpAndSettle();

      final next = find.text('Anxiety and sleep: breaking the loop');
      await tester.scrollUntilVisible(next, 200);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Anxiety and short sleep feed each other'),
        findsOneWidget,
      );
    });
  });
}
