import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'repositories/app_repository.dart';
import 'repositories/firebase_app_repository.dart';
import 'screens/brand_splash.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/health_data_provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect Firebase for account-backed storage. Guarded so a transient init
  // failure (offline, misconfig) degrades to the local demo instead of a black
  // boot screen.
  var firebaseReady = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    firebaseReady = false;
    debugPrint('Firebase initialization failed; continuing on local demo.');
    debugPrintStack(stackTrace: stackTrace, label: '$error');
  }

  if (!firebaseReady) {
    // No Firebase: run the in-memory demo exactly as before real auth. Keeps
    // the app usable offline and for the public web demo.
    final repository = InMemoryAppRepository();
    final state = NguyenInDoubtState(
      repository: repository,
      healthDataProvider: createDefaultHealthDataProvider(
        userId: repository.patientDemo.id,
      ),
    );
    runApp(NguyenInDoubtApp(state: state));
    return;
  }

  // Real auth entry: an AuthGate listens to auth state and swaps between the
  // brand LoginScreen (signed out) and the app backed by the live Firestore
  // repository under the signed-in uid.
  runApp(
    NguyenInDoubtAuthApp(
      authService: FirebaseAuthService(),
      repository: FirebaseAppRepository(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      ),
    ),
  );
}

/// The demo/offline app: wraps a prebuilt in-memory [NguyenInDoubtState] in the
/// brand splash gate. This is the exact widget the test suite drives — its
/// constructor is intentionally unchanged so the 60 existing tests compile and
/// behave identically.
class NguyenInDoubtApp extends StatelessWidget {
  const NguyenInDoubtApp({
    super.key,
    required this.state,
    this.showSplash = true,
  });

  final NguyenInDoubtState state;

  /// Test seam (ONB-01): production boots keep the default `true` and get the
  /// one-shot brand-intro splash. Widget tests pass `false` so the gate
  /// builds [AppShell] directly and `pumpAndSettle` from boot never hangs.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NguyenInDoubt',
      theme: buildNidTheme(),
      home: BrandSplashGate(state: state, enabled: showSplash),
    );
  }
}

/// The live, auth-gated app: signed-out shows the brand [LoginScreen];
/// signed-in bootstraps a real profile and enters the app on the Firebase
/// repository. Kept separate from [NguyenInDoubtApp] so the demo/test path
/// stays untouched.
class NguyenInDoubtAuthApp extends StatelessWidget {
  const NguyenInDoubtAuthApp({
    super.key,
    required this.authService,
    required this.repository,
    this.showSplash = true,
  });

  final AuthService authService;
  final NidRepository repository;
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NguyenInDoubt',
      theme: buildNidTheme(),
      home: AuthGate(
        authService: authService,
        repository: repository,
        showSplash: showSplash,
      ),
    );
  }
}

/// Auth-gated entry: listens to [AuthService.uidChanges] and gently fades
/// between the brand [LoginScreen] (signed out) and the app backed by the
/// signed-in uid. Sign-out flows back here through the stream — never a pop
/// (project rule: screens transition, never snap away).
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.repository,
    this.showSplash = true,
  });

  final AuthService authService;
  final NidRepository repository;
  final bool showSplash;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  NguyenInDoubtState? _signedInState;
  String? _stateUid;

  /// Builds fresh app state for [uid], bootstrapping the real profile via the
  /// injected AuthService + Firebase repository (ensureUser runs in the state
  /// constructor). Reused across rebuilds while the uid is unchanged so we do
  /// not re-bootstrap on every stream tick.
  NguyenInDoubtState _stateForUid(String uid) {
    final existing = _signedInState;
    if (existing != null && _stateUid == uid) {
      return existing;
    }
    existing?.dispose();
    final state = NguyenInDoubtState(
      repository: widget.repository,
      authService: widget.authService,
      healthDataProvider: createDefaultHealthDataProvider(userId: uid),
    );
    _signedInState = state;
    _stateUid = uid;
    return state;
  }

  void _clearSignedInState() {
    _signedInState?.dispose();
    _signedInState = null;
    _stateUid = null;
  }

  @override
  void dispose() {
    _signedInState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: widget.authService.uidChanges,
      initialData: widget.authService.currentUid,
      builder: (context, snapshot) {
        final uid = snapshot.data;
        final Widget child;
        if (uid == null) {
          // Signed out. Drop any prior signed-in state so a later sign-in
          // rebuilds clean, then show the brand login.
          _clearSignedInState();
          child = LoginScreen(
            key: const ValueKey('login'),
            auth: widget.authService,
          );
        } else {
          // Signed in. Bootstrap-backed state drives the existing app shell.
          child = BrandSplashGate(
            key: ValueKey('app-$uid'),
            state: _stateForUid(uid),
            enabled: widget.showSplash,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        );
      },
    );
  }
}
