import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/login_screen.dart';
import 'package:nguyenindoubt_app/services/auth_service.dart';

/// A controllable [AuthService] for driving the [AuthGate] in widget tests:
/// [emit] a uid to simulate sign-in, `null` to simulate sign-out. No Firebase
/// or provider SDKs are touched — every provider method is a no-op.
class FakeAuthService implements AuthService {
  FakeAuthService({String? initialUid}) : _uid = initialUid {
    _controller.add(_uid);
  }

  final _controller = StreamController<String?>.broadcast();
  String? _uid;

  void emit(String? uid) {
    _uid = uid;
    _controller.add(uid);
  }

  @override
  Stream<String?> get uidChanges => _controller.stream;

  @override
  String? get currentUid => _uid;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<PhoneStartResult> startPhoneSignIn(String e164) async {
    return const PhoneStartResult(verificationId: 'fake');
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {}

  @override
  Future<void> signOut() async => emit(null);

  Future<void> dispose() => _controller.close();
}

void main() {
  testWidgets('signed-out renders the brand LoginScreen', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthService(initialUid: null);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      NguyenInDoubtAuthApp(
        authService: auth,
        repository: InMemoryAppRepository(),
        showSplash: false,
      ),
    );
    await tester.pumpAndSettle();

    // The signed-out gate shows the brand login, not the app shell.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    // The demo onboarding "Get started" surface belongs to the app shell and
    // must NOT be present while signed out.
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('signed-in bootstraps into the app, not the login screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A signed-in uid that matches the seeded demo patient so the in-memory
    // repository's ownership checks pass offline (no Firebase needed).
    final auth = FakeAuthService(initialUid: 'patient-demo');
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      NguyenInDoubtAuthApp(
        authService: auth,
        repository: InMemoryAppRepository(),
        showSplash: false,
      ),
    );
    await tester.pumpAndSettle();

    // Signed in: no login screen, and the patient app shell is reached
    // (the first-run "start with sleep" prompt confirms the patient surface).
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text("Start with last night's sleep"), findsOneWidget);
  });

  testWidgets('sign-out fades back to the LoginScreen', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = FakeAuthService(initialUid: 'patient-demo');
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      NguyenInDoubtAuthApp(
        authService: auth,
        repository: InMemoryAppRepository(),
        showSplash: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsNothing);

    // Emitting a null uid (sign-out) fades back to the brand login.
    auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
