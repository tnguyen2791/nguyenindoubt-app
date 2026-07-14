import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result of kicking off a phone sign-in: the [verificationId] Firebase issues
/// after sending the SMS, to be paired with the user-entered code in
/// [AuthService.confirmPhoneCode]. [autoResolved] is true only when the
/// platform auto-retrieved and completed sign-in without a code entry step
/// (Android instant verification) — in that case no code prompt is needed.
class PhoneStartResult {
  const PhoneStartResult({
    required this.verificationId,
    this.autoResolved = false,
  });

  /// Marks an auto-resolved verification (Android instant verify) where sign-in
  /// already completed and no code entry is required.
  const PhoneStartResult.autoResolved()
    : verificationId = '',
      autoResolved = true;

  final String verificationId;
  final bool autoResolved;
}

/// Raised when a provider sign-in cannot complete. Carries a calm,
/// user-facing [message] only — the underlying provider error is logged at the
/// call site, never surfaced. UI shows [message] verbatim (project rule: no raw
/// exceptions or error codes in the UI).
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The auth seam the app talks to. Provider SDK calls live only inside
/// [FirebaseAuthService]; tests and the local demo use [DemoAuthService], so
/// nothing here needs a live Firebase project to run.
abstract class AuthService {
  /// Emits the current Firebase uid, or null when signed out. Fires on every
  /// auth state change.
  Stream<String?> get uidChanges;

  /// The current Firebase uid, or null when signed out.
  String? get currentUid;

  /// Interactive Google sign-in. Throws [AuthFailure] on any failure.
  Future<void> signInWithGoogle();

  /// Interactive Apple sign-in. Throws [AuthFailure] on any failure.
  Future<void> signInWithApple();

  /// Starts phone sign-in for an E.164 number (e.g. `+14155550123`). Returns a
  /// [PhoneStartResult] whose verificationId is passed back to
  /// [confirmPhoneCode]. Throws [AuthFailure] on any failure.
  Future<PhoneStartResult> startPhoneSignIn(String e164);

  /// Confirms a phone sign-in with the SMS code the user entered. Throws
  /// [AuthFailure] on any failure (including a wrong code).
  Future<void> confirmPhoneCode(String verificationId, String smsCode);

  /// Signs the user out of all providers.
  Future<void> signOut();
}

/// Real multi-provider auth backed by FirebaseAuth + google_sign_in +
/// sign_in_with_apple. Not yet wired as the app entry — staged for the pass
/// that flips the app to real auth once providers are enabled server-side.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  @override
  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      // Firebase needs an access token alongside the id token; google_sign_in
      // 7.x sources it through the authorization client, prompting if needed.
      final authorization = await account.authorizationClient.authorizeScopes(
        const ['email'],
      );
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      await _auth.signInWithCredential(credential);
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      _logAuthError('Google sign-in failed', error, stackTrace);
      throw const AuthFailure(
        "We couldn't finish signing in with Google. Please try again.",
      );
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _auth.signInWithCredential(oauthCredential);
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      _logAuthError('Apple sign-in failed', error, stackTrace);
      throw const AuthFailure(
        "We couldn't finish signing in with Apple. Please try again.",
      );
    }
  }

  @override
  Future<PhoneStartResult> startPhoneSignIn(String e164) async {
    final completer = Completer<PhoneStartResult>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        verificationCompleted: (credential) async {
          // Android instant verification: sign in directly, no code prompt.
          try {
            await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(const PhoneStartResult.autoResolved());
            }
          } catch (error, stackTrace) {
            _logAuthError('Phone auto-verify failed', error, stackTrace);
            if (!completer.isCompleted) {
              completer.completeError(
                const AuthFailure(
                  "We couldn't verify that number. Please try again.",
                ),
              );
            }
          }
        },
        verificationFailed: (error) {
          _logAuthError('Phone verification failed', error, StackTrace.current);
          if (!completer.isCompleted) {
            completer.completeError(
              const AuthFailure(
                "We couldn't send a code to that number. Check it and try "
                'again.',
              ),
            );
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneStartResult(verificationId: verificationId),
            );
          }
        },
        codeAutoRetrievalTimeout: (_) {
          // No-op: the manual code-entry path in confirmPhoneCode remains
          // available after auto-retrieval times out.
        },
      );
      return await completer.future;
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      _logAuthError('Phone sign-in start failed', error, stackTrace);
      throw const AuthFailure(
        "We couldn't start phone sign-in. Please try again.",
      );
    }
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } on AuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      _logAuthError('Phone code confirmation failed', error, stackTrace);
      throw const AuthFailure(
        'That code did not match. Please check it and try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_googleInitialized) {
        await _googleSignIn.signOut();
      }
    } catch (error, stackTrace) {
      // A Google sign-out hiccup must not block the Firebase sign-out below.
      _logAuthError('Google sign-out failed', error, stackTrace);
    }
    await _auth.signOut();
  }

  void _logAuthError(String label, Object error, StackTrace stackTrace) {
    // Logs the real error for debugging; the UI only ever sees AuthFailure copy
    // (project rule: never surface raw exceptions or provider error codes).
    debugPrint('[auth] $label: $error');
    debugPrintStack(stackTrace: stackTrace, label: label);
  }
}

/// No-op auth for tests and the local demo: always signed out, every provider
/// call is a safe no-op that never touches Firebase or a provider SDK.
class DemoAuthService implements AuthService {
  /// Const so it can be the default [AuthService] on [NguyenInDoubtState],
  /// keeping every existing demo/test constructor call unchanged.
  const DemoAuthService();

  @override
  Stream<String?> get uidChanges => Stream<String?>.value(null);

  @override
  String? get currentUid => null;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<PhoneStartResult> startPhoneSignIn(String e164) async {
    return const PhoneStartResult(verificationId: 'demo-verification-id');
  }

  @override
  Future<void> confirmPhoneCode(String verificationId, String smsCode) async {}

  @override
  Future<void> signOut() async {}
}
