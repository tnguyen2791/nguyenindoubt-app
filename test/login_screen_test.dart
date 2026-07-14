import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/screens/login_screen.dart';
import 'package:nguyenindoubt_app/services/auth_service.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';

/// Pumps the standalone [LoginScreen] with a no-op [DemoAuthService] — no
/// Firebase, no splash, no app shell. The screen is not yet the app entry, so
/// these tests exercise it in isolation.
Future<void> _pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1000);
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

/// The design uses a canopy-fill primary block (FilledButton) for the live
/// Google provider and canopy-outline ghost blocks (OutlinedButton) for Apple
/// (disabled) and Phone — so `onPressed` is read from whichever button type
/// owns the label.
VoidCallback? _onPressedForLabel(WidgetTester tester, String label) {
  final buttonFinder = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is FilledButton || widget is OutlinedButton,
    ),
  );
  final button = tester.widget<ButtonStyleButton>(buttonFinder);
  return button.onPressed;
}

FilledButton _filledForLabel(WidgetTester tester, String label) {
  return tester.widget<FilledButton>(
    find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
  );
}

void main() {
  testWidgets('renders the welcome grammar and three provider blocks', (
    tester,
  ) async {
    await _pumpLogin(tester);

    // The 42 welcome lockup + headline. The compact mark renders as N/i/D
    // spans that read "NiD" — the below-80px brand form.
    expect(find.text('Quiet signals,\nclear mornings'), findsOneWidget);
    expect(find.text('NiD'), findsOneWidget);

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue with phone'), findsOneWidget);

    // Google and phone are live; Apple is gently disabled with calm
    // "coming soon" copy (provider not enabled server-side yet).
    expect(_onPressedForLabel(tester, 'Continue with Google'), isNotNull);
    expect(_onPressedForLabel(tester, 'Continue with phone'), isNotNull);
    expect(_onPressedForLabel(tester, 'Continue with Apple'), isNull);
    expect(find.text('Apple sign-in is coming soon.'), findsOneWidget);

    // The calm disclosure fine-print (42 `.fine`).
    expect(
      find.text('Private by design — your data stays yours.'),
      findsOneWidget,
    );
  });

  testWidgets('phone entry guards empty and invalid numbers', (tester) async {
    await _pumpLogin(tester);

    // Enter the phone flow.
    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();

    FilledButton sendButton() => _filledForLabel(tester, 'Send code');

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

  testWidgets('phone flow advances to the 6-box code entry and guards codes', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Continue with phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '+14155550123');
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // DemoAuthService returns a verificationId, so we land on the OTP step.
    expect(find.text('Enter your code'), findsOneWidget);
    // The 62 grammar: a resend + change-number affordance.
    expect(find.text('Resend code'), findsOneWidget);
    expect(find.text('Change number'), findsOneWidget);

    FilledButton verifyButton() => _filledForLabel(tester, 'Verify');

    // Empty and short codes cannot submit.
    expect(verifyButton().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(verifyButton().onPressed, isNull);

    // A full 6-digit code enables Verify and shows the digits in the boxes.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(verifyButton().onPressed, isNotNull);
    for (final digit in const ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsWidgets);
    }
  });

  testWidgets('no raw exception or error-code strings surface in the UI', (
    tester,
  ) async {
    await _pumpLogin(tester);

    // Tap the live Google provider; DemoAuthService no-ops, so nothing should
    // render a raw exception. Apple is disabled (coming soon) so it is not
    // tapped here. Assert none of the usual raw-error markers show.
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

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
