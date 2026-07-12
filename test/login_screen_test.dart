import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/screens/login_screen.dart';
import 'package:nguyenindoubt_app/services/auth_service.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';

/// Pumps the standalone [LoginScreen] with a no-op [DemoAuthService] — no
/// Firebase, no splash, no app shell. The screen is not yet the app entry, so
/// these tests exercise it in isolation.
Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildNidTheme(),
      home: LoginScreen(auth: DemoAuthService()),
    ),
  );
  await tester.pumpAndSettle();
}

FilledButton _buttonForLabel(WidgetTester tester, String label) {
  return tester.widget<FilledButton>(
    find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
  );
}

void main() {
  testWidgets('renders the three provider buttons with exact labels', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with phone'), findsOneWidget);

    // All three are enabled on the chooser (DemoAuthService never blocks).
    expect(
      _buttonForLabel(tester, 'Continue with Google').onPressed,
      isNotNull,
    );
    expect(_buttonForLabel(tester, 'Continue with Apple').onPressed, isNotNull);
    expect(_buttonForLabel(tester, 'Continue with phone').onPressed, isNotNull);
  });

  testWidgets('phone entry guards empty and invalid numbers', (tester) async {
    await _pumpLogin(tester);

    // Enter the phone flow.
    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();

    FilledButton sendButton() => _buttonForLabel(tester, 'Send code');

    // Empty: Send code is disabled.
    expect(sendButton().onPressed, isNull);

    // Obviously incomplete / missing country code: still disabled.
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(sendButton().onPressed, isNull);

    // A well-formed E.164 number enables Send code.
    await tester.enterText(find.byType(TextField), '+14155550123');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('phone flow advances to code entry and guards short codes', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+14155550123');
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // DemoAuthService returns a verificationId, so we land on code entry.
    expect(find.text('Enter your code'), findsOneWidget);

    FilledButton verifyButton() => _buttonForLabel(tester, 'Verify');

    // Empty and short codes cannot submit.
    expect(verifyButton().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(verifyButton().onPressed, isNull);

    // A full 6-digit code enables Verify.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(verifyButton().onPressed, isNotNull);
  });

  testWidgets('no raw exception or error-code strings surface in the UI', (
    tester,
  ) async {
    await _pumpLogin(tester);

    // Tap each provider button; DemoAuthService no-ops, so nothing should
    // render a raw exception. Assert none of the usual raw-error markers show.
    for (final label in const ['Continue with Google', 'Continue with Apple']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    for (final rawMarker in const [
      'Exception',
      'FirebaseAuthException',
      'PlatformException',
      'firebase_auth/',
      'StackTrace',
      '#0 ',
    ]) {
      expect(
        find.textContaining(rawMarker),
        findsNothing,
        reason: 'raw error marker "$rawMarker" must never reach the UI',
      );
    }
  });
}
